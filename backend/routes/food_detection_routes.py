from flask import Flask, Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from models.daily_nutrition_log import DailyNutritionLog  
from models.user import User
from services.nutrition_service import calculate_nutrition_goals
from models import db
import os
import datetime
from datetime import date
import requests
from dotenv import load_dotenv
load_dotenv()

# LogMeal API
API_USER_TOKEN = '974fc78c1d070486d453c379a5d78437970d7db5'
HEADERS = {'Authorization': f'Bearer {API_USER_TOKEN}'}
API_URL = 'https://api.logmeal.es/v2/image/segmentation/complete'

# Nutritionix API (Text-Based)
NUTRITIONIX_APP_ID  = os.getenv('NUTRITIONIX_APP_ID')
NUTRITIONIX_APP_KEY = os.getenv('NUTRITIONIX_APP_KEY')
NUTRITIONIX_URL     = 'https://trackapi.nutritionix.com/v2/natural/nutrients'

food_detection_bp = Blueprint('food_detection', __name__)

UPLOAD_FOLDER = 'uploads'
os.makedirs(UPLOAD_FOLDER, exist_ok=True)


# --- Helper Function ---
def find_or_create_log(user_id, session):
    """Finds today's log for a user or creates a new one if it doesn't exist."""
    today = date.today()
    log = DailyNutritionLog.query.filter_by(user_id=user_id, date=today).first()
    if not log:
        log = DailyNutritionLog(user_id=user_id, date=today)
        session.add(log)
    return log

@food_detection_bp.route('/detect_food', methods=['POST'])
def detect_food():
    if 'file' not in request.files:
        return jsonify({'error': 'No file part in the request.'}), 400

    file = request.files['file']
    if file.filename == '':
        return jsonify({'error': 'No selected file.'}), 400

    file_path = os.path.join(UPLOAD_FOLDER, file.filename)
    file.save(file_path)

    with open(file_path, 'rb') as img:
        response = requests.post(API_URL, files={'image': img}, headers=HEADERS)

    os.remove(file_path)

    if response.status_code == 200:
        result = response.json()
        image_id = result.get('imageId')
        segmentation_results = result.get('segmentation_results', [])
        recognized_dishes = [dish for seg in segmentation_results for dish in seg.get('recognition_results', [])]
        valid_dishes = [dish for dish in recognized_dishes if dish.get('name') and dish.get('name') != '_empty_']
        top_dish = max(valid_dishes, key=lambda x: x.get('prob', 0)) if valid_dishes else {}

        return jsonify({
            'dish_name': top_dish.get('name', 'Unknown'),
            'imageId': image_id
        })
    return jsonify({'error': 'API Error', 'details': response.text}), response.status_code

@food_detection_bp.route('/get_nutritional_info', methods=['POST'])
def get_nutritional_info():
    data = request.get_json()
    image_id = data.get('imageId')

    if not image_id:
        return jsonify({'error': 'Missing imageId'}), 400

    nutrition_url = 'https://api.logmeal.com/v2/recipe/nutritionalInfo'
    nutrition_response = requests.post(nutrition_url, json={'imageId': image_id}, headers=HEADERS)

    if nutrition_response.status_code == 200:
        nutrition_data = nutrition_response.json()
        nutritional_info = nutrition_data.get('nutritional_info', {})
        total_nutrients = nutritional_info.get('totalNutrients', {})

        nutritional_info_response = {
            'calories': nutritional_info.get('calories', 'N/A'),
            'protein': total_nutrients.get('PROCNT', {}).get('quantity', 'N/A'),
            'fat': total_nutrients.get('FAT', {}).get('quantity', 'N/A'),
            'carbs': total_nutrients.get('CHOCDF', {}).get('quantity', 'N/A'),
            'folic_acid': total_nutrients.get('FOLAC', {}).get('quantity', 'N/A'),
            'iron': total_nutrients.get('FE', {}).get('quantity', 'N/A'),
            'zinc': total_nutrients.get('ZN', {}).get('quantity', 'N/A'),
            'calcium': total_nutrients.get('CA', {}).get('quantity', 'N/A'),
        }

        return jsonify({
            'nutritional_info': nutritional_info_response
        })
    
    return jsonify({'error': 'Failed to retrieve nutrition info', 'details': nutrition_response.text}), 500

@food_detection_bp.route('/store_nutritional_info', methods=['POST'])
@jwt_required()
def store_nutritional_info(): 
    from models import db  
    from models.daily_nutrition_log import DailyNutritionLog
    from models.user import User
    from datetime import date 

    print("Store nutritional info route hit")
    data = request.get_json()
    print("→ payload:", data)

    # Retrieve and cast the JWT identity to int
    raw_id = get_jwt_identity()
    try:
        user_id = int(raw_id)  # Highlight: convert string identity to integer
    except (TypeError, ValueError):
        return jsonify({'error': 'Invalid user_id format'}), 400

    calories = data.get('calories')
    protein = data.get('protein')
    fat = data.get('fat')
    carbs = data.get('carbs') 
    folic_acid = data.get('folic_acid', 0)
    iron = data.get('iron', 0)            
    calcium = data.get('calcium', 0)      
    zinc = data.get('zinc', 0)  

    if not user_id:
        return jsonify({'error': 'Missing user_id'}), 400

    user = User.query.get(user_id)
    if not user:
        return jsonify({'error': 'User not found'}), 404

    nutrition_entry = DailyNutritionLog(
        user_id=user_id,
        daily_calories=calories,
        daily_protein=protein,
        daily_fat=fat,
        daily_carbs=carbs,
        daily_folac_acid=folic_acid, 
        daily_iron=iron,             
        daily_calcium=calcium,       
        daily_zinc=zinc,  
        date=date.today()
    )
    db.session.add(nutrition_entry)
    try:
        db.session.commit()
        return jsonify({'message': 'Nutrition info saved successfully'})
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'Failed to save nutrition info: {str(e)}'}), 500

@food_detection_bp.route('/get_nutrition_by_text', methods=['POST'])
def get_nutrition_by_text():
    data = request.get_json()
    items = data.get('items', [])
    if not items:
        return jsonify({'error': 'Missing items list'}), 400

    lines = [f"{item['quantity']} {item['name']}" for item in items]
    query_text = "\n".join(lines)

    nx_headers = {
        'x-app-id':  NUTRITIONIX_APP_ID,
        'x-app-key': NUTRITIONIX_APP_KEY,
        'Content-Type': 'application/json'
    }
    nx_payload = {'query': query_text}
    nx_resp = requests.post(NUTRITIONIX_URL, json=nx_payload, headers=nx_headers)

    if nx_resp.status_code != 200:
        return jsonify({'error': 'Nutritionix API error', 'details': nx_resp.text}), nx_resp.status_code

    result = nx_resp.json()
    print("Nutritionix resp:", nx_resp.status_code, nx_resp.text)
    foods = result.get('foods', [])

    total_calories = sum(f.get('nf_calories', 0) for f in foods)
    total_protein  = sum(f.get('nf_protein',  0) for f in foods)
    total_fat      = sum(f.get('nf_total_fat', 0) for f in foods)
    total_carbs    = sum(f.get('nf_total_carbohydrate', 0) for f in foods)

    total_folic_acid = 0
    total_iron = 0
    total_calcium = 0
    total_zinc = 0

    for food in foods:
        for nutrient in food.get('full_nutrients', []):
            if nutrient['attr_id'] == 318: 
                total_folic_acid += nutrient.get('value', 0)
            elif nutrient['attr_id'] == 303: 
                total_iron += nutrient.get('value', 0)
            elif nutrient['attr_id'] == 301:
                total_calcium += nutrient.get('value', 0)
            elif nutrient['attr_id'] == 309: 
                total_zinc += nutrient.get('value', 0)


    return jsonify({
        'calories': total_calories,
        'protein':  total_protein,
        'fat':      total_fat,
        'carbs':    total_carbs,
        'folic_acid': total_folic_acid,
        'iron': total_iron,            
        'calcium': total_calcium,      
        'zinc': total_zinc
    })

@food_detection_bp.route('/goal', methods=['GET'])
@jwt_required()
def get_nutrition_goal():
    try:
        user_id = int(get_jwt_identity())
        user = User.query.get(user_id)

        if not user:
            return jsonify({'error': 'User not found'}), 404
        
        if not user.due_date:
            return jsonify({'error': 'Due date has not been set for this user.'}), 400

        nutrition_goals = calculate_nutrition_goals(
            age=user.age,
            weight=user.weight,
            height=user.height,
            due_date=user.due_date
        )

        nutrition_goals['water_ml'] = 2000  
        nutrition_goals['sleep_hours'] = 8.0

        return jsonify(nutrition_goals), 200

    except Exception as e:
        return jsonify({'error': f'An error occurred: {str(e)}'}), 500

@food_detection_bp.route('/log/today', methods=['GET'])
@jwt_required()
def get_today_log():
    user_id = int(get_jwt_identity())
    log = find_or_create_log(user_id, db.session)

    return jsonify(log.to_dict()), 200

@food_detection_bp.route('/log/water', methods=['POST'])
@jwt_required()
def log_water():
    """Increments the water log for the day by a fixed amount (1 glass = 250ml)."""
    user_id = int(get_jwt_identity())
    
    try:
        log = find_or_create_log(user_id, db.session)
        log.daily_water += 250  # Add 250ml for one glass of water
        db.session.commit()
        return jsonify({
            'message': 'Water logged successfully.',
            'new_total_water': log.daily_water
        }), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

# --- NEW ROUTE for logging sleep ---
@food_detection_bp.route('/log/sleep', methods=['POST'])
@jwt_required()
def log_sleep():
    """Adds sleep hours to the daily log from the request body."""
    user_id = int(get_jwt_identity())
    data = request.get_json()
    hours_to_add = data.get('hours')

    if not isinstance(hours_to_add, (int, float)) or hours_to_add <= 0:
        return jsonify({'error': 'Invalid "hours" value provided.'}), 400

    try:
        log = find_or_create_log(user_id, db.session)
        log.daily_sleep += hours_to_add
        db.session.commit()
        return jsonify({
            'message': 'Sleep logged successfully.',
            'new_total_sleep': log.daily_sleep
        }), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500