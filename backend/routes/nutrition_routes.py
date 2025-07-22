from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from services.nutrition_service import calculate_nutrition_goals
from models import db
from models.daily_nutrition import DailyNutrition
from models.user import User   
from sqlalchemy import func 
import datetime
from datetime import date
from models.daily_nutrition_log import DailyNutritionLog

nutrition_bp = Blueprint('nutrition', __name__, url_prefix='/nutrition')

@nutrition_bp.route('/set_goal', methods=['POST'])
@jwt_required()
def set_nutrition_goal():
    raw_id = get_jwt_identity()
    try:
        user_id = int(raw_id)
    except (TypeError, ValueError):
        return jsonify({'error': 'Invalid user identity'}), 400

    user = User.query.get(user_id)
    if not user:
        return jsonify({'error': 'User not found'}), 404

    age = user.age
    weight = user.weight
    height = user.height
    due_date = user.due_date

    if not due_date:
        return jsonify({'error': 'Due date has not been set for this user.'}), 400

    goals = calculate_nutrition_goals(age, weight, height, due_date)

    new_goal = DailyNutrition(
        user_id=user_id,
        calories=goals["calories"],
        protein=goals["protein"],
        fat=goals["fat"],
        carbs=goals["carbs"]
    )

    try:
        db.session.add(new_goal)
        db.session.commit()
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'Failed to save goal: {str(e)}'}), 500

    return jsonify({"message": "Nutrition goal set successfully", "status": "success"}), 201

@nutrition_bp.route('/log/today', methods=['GET'])
@jwt_required()
def get_today_log():
    """Return today's nutrition log for the current user (zeros if none)."""
    raw_id = get_jwt_identity()
    try:
        user_id = int(raw_id)
    except (TypeError, ValueError):
        return jsonify({'error': 'Invalid user identity'}), 400

    today = date.today()
    log = DailyNutritionLog.query.filter_by(user_id=user_id, date=today).first()
    if not log:
        return jsonify({
            'date': today.isoformat(),
            'daily_calories': 0,
            'daily_protein':  0,
            'daily_fat':      0,
            'daily_carbs':    0,
        }), 200

    return jsonify({
        'date':           log.date.isoformat(),
        'daily_calories': log.daily_calories,
        'daily_protein':  log.daily_protein,
        'daily_fat':      log.daily_fat,
        'daily_carbs':    log.daily_carbs,
    }), 200

@nutrition_bp.route('/goal', methods=['GET'])
@jwt_required()
def get_nutrition_goal():
    """Return the current user's nutrition goal (from daily_nutrition)."""
    try:
        user_id = int(get_jwt_identity())
    except (TypeError, ValueError):
        return jsonify({'error': 'Invalid user identity'}), 400

    # pull the most recent goal row
    goal = (DailyNutrition.query
              .filter_by(user_id=user_id)
              .order_by(DailyNutrition.id.desc())
              .first())

    return jsonify(goal.to_dict()), 200

@nutrition_bp.route('/summary', methods=['GET'])
@jwt_required()
def get_nutrition_summary():
    """
    Mengembalikan total konsumsi hari ini + target harian.
    SEKARANG MENJUMLAHKAN SEMUA LOG HARIAN.
    """
    try:
        user_id = int(get_jwt_identity())
        user = User.query.get(user_id)
        if not user:
            return jsonify({'error': 'User not found'}), 404
    except (TypeError, ValueError):
        return jsonify({'error': 'Invalid user identity'}), 400

    today = date.today()
    goal = DailyNutrition.query.filter_by(user_id=user_id).order_by(DailyNutrition.id.desc()).first()

    if not goal:
        if not user.due_date:
            return jsonify({'error': 'Due date not set, cannot create nutrition goal'}), 400
        
        calculated_goals = calculate_nutrition_goals(user.age, user.weight, user.height, user.due_date)
        goal = DailyNutrition(
            user_id=user_id, calories=calculated_goals['calories'],
            protein=calculated_goals['protein'], fat=calculated_goals['fat'],
            carbs=calculated_goals['carbs']
        )
        db.session.add(goal)
        db.session.commit()

    goal_data = {
        'calories': goal.calories, 'protein': goal.protein, 'fat': goal.fat,
        'carbs': goal.carbs, 'water_ml': 2000, 'sleep_hours': 8.0
    }

    # --- PERBAIKAN UTAMA ADA DI SINI ---
    # Alih-alih .first(), kita akan menjumlahkan semua log untuk hari ini
    
    # Query untuk menjumlahkan semua nutrisi
    sum_query = db.session.query(
        func.sum(DailyNutritionLog.daily_calories).label('total_calories'),
        func.sum(DailyNutritionLog.daily_protein).label('total_protein'),
        func.sum(DailyNutritionLog.daily_fat).label('total_fat'),
        func.sum(DailyNutritionLog.daily_carbs).label('total_carbs')
    ).filter(
        DailyNutritionLog.user_id == user_id,
        DailyNutritionLog.date == today
    ).one()

    # Query terpisah untuk mengambil log air dan tidur (karena ini tidak dijumlahkan)
    water_sleep_log = DailyNutritionLog.query.filter(
        DailyNutritionLog.user_id == user_id,
        DailyNutritionLog.date == today
    ).first()

    consumed_data = {
        'daily_calories': sum_query.total_calories or 0,
        'daily_protein':  sum_query.total_protein or 0,
        'daily_fat':      sum_query.total_fat or 0,
        'daily_carbs':    sum_query.total_carbs or 0,
        'daily_water':    water_sleep_log.daily_water if water_sleep_log else 0,
        'daily_sleep':    water_sleep_log.daily_sleep if water_sleep_log else 0,
    }

    return jsonify({
        'date':       today.isoformat(),
        'goal':       goal_data,
        'consumed':   consumed_data
    }), 200
