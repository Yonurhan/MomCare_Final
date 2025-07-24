from flask import Blueprint, request, jsonify
from flask_jwt_extended import create_access_token, jwt_required, get_jwt_identity
from services.nutrition_service import calculate_nutrition_goals 
from models.daily_nutrition import DailyNutrition            
from models import db
from models.user import User
import datetime
from datetime import datetime, date, timedelta
auth_bp = Blueprint('auth', __name__)

@auth_bp.route('/register', methods=['POST'])
def register():
    """
    Endpoint untuk registrasi pengguna baru.
    Sekarang menggunakan 'lmp_date' (HPHT).
    """
    data = request.get_json()

    required_fields = ['username', 'email', 'password', 'age', 'weight', 'height', 'lmp_date']
    if not all(key in data for key in required_fields):
        return jsonify({'success': False, 'message': 'Data tidak lengkap'}), 400
    
    if User.find_by_email(data['email']):
        return jsonify({'success': False, 'message': 'Email sudah terdaftar'}), 400
    
    try:
        lmp_date_obj = datetime.strptime(data['lmp_date'], '%Y-%m-%d').date()

        new_user = User.create(
            data['username'], 
            data['email'], 
            data['password'], 
            data['age'], 
            data['height'], 
            data['weight'], 
            lmp_date_obj 
        )
        
        goals = calculate_nutrition_goals(
            new_user.age,
            new_user.weight,
            new_user.height,
            new_user.lmp_date
        )

        initial_goal = DailyNutrition(
            user_id=new_user.id,
            calories=goals['calories'],
            protein=goals['protein'],
            fat=goals['fat'],
            carbs=goals['carbs']
        )
        db.session.add(initial_goal)
        db.session.commit()
        
        access_token = create_access_token(identity=str(new_user.id))
        return jsonify({
            'success': True,
            'message': 'Registrasi berhasil',
            'user': new_user.to_dict(),
            'token': access_token
        }), 201
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'message': str(e)}), 500


@auth_bp.route('/login', methods=['POST'])
def login():
    try:
        data = request.get_json()
        
        # Validasi payload
        if not all(field in data for field in ['email', 'password']):
            return jsonify({
                'success': False,
                'message': 'Email dan password wajib diisi'
            }), 400

        email = data['email'].strip().lower()
        password = data['password']

        # Cari user berdasarkan email
        user = User.find_by_email(email)
        
        # Verifikasi user dan password
        if not user or not user.verify_password(password):
            return jsonify({
                'success': False,
                'message': 'Email atau password salah'
            }), 401

#         # Generate JWT token
#         access_token = create_access_token(
#             identity=user.to_dict(),  # INI MASALAHNYA - menggunakan dictionary sebagai identity
#             expires_delta=datetime.timedelta(hours=1)
# )
        # Generate JWT token
        access_token = create_access_token(
            identity=str(user.id),
            expires_delta=timedelta(hours=1)
        )

        return jsonify({
            'success': True,
            'message': 'Login berhasil',
            'user': user.to_dict(),
            'token': access_token
        }), 200

    except Exception as e:
        return jsonify({
            'success': False,
            'message': f'Terjadi kesalahan server: {str(e)}'
        }), 500

# NEW: Added /profile endpoint
@auth_bp.route('/profile', methods=['GET'])
@jwt_required()
def get_user_profile():
    """
    Endpoint to get the current logged-in user's profile data.
    """
    try:
        user_id = int(get_jwt_identity())
    except (TypeError, ValueError):
        return jsonify({'error': 'Invalid user identity'}), 400
        
    user = User.query.get(user_id)
    if not user:
        return jsonify({'error': 'User not found'}), 404
        
    # The user.to_dict() method already includes the due_date
    return jsonify(user.to_dict()), 200


@auth_bp.route('/protected', methods=['GET'])
@jwt_required()
def protected():
    """
    Endpoint contoh yang memerlukan autentikasi JWT.
    """
    current_user = get_jwt_identity()
    return jsonify({'success': True, 'user': current_user}), 200
