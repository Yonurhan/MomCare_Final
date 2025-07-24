from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from datetime import date, timedelta

# Impor model dan service yang relevan
from models import db
from models.weekly_assessment import WeeklyAssessment
from services.assessment_service import perform_weekly_assessment

assessment_bp = Blueprint('assessment', __name__, url_prefix='/assessment')

@assessment_bp.route('/status', methods=['GET'])
@jwt_required()
def get_assessment_status():
    """
    Memeriksa apakah pengguna sudah melakukan asesmen untuk minggu ini.
    """
    user_id = int(get_jwt_identity())
    
    # Tentukan awal minggu ini (hari Senin)
    today = date.today()
    start_of_week = today - timedelta(days=today.weekday())

    # Cek apakah sudah ada entri asesmen untuk minggu ini
    existing_assessment = WeeklyAssessment.query.filter(
        WeeklyAssessment.user_id == user_id,
        WeeklyAssessment.week_start_date == start_of_week
    ).first()

    if existing_assessment:
        return jsonify({'status': 'completed'})
    else:
        return jsonify({'status': 'available'})

@assessment_bp.route('/perform', methods=['POST'])
@jwt_required()
def perform_assessment():
    """
    Menjalankan asesmen mingguan, menyimpan hasilnya, dan mengembalikannya.
    """
    user_id = int(get_jwt_identity())
    quiz_answers = request.get_json()

    # Cek apakah asesmen sudah dilakukan untuk minggu ini untuk mencegah duplikasi
    today = date.today()
    start_of_week = today - timedelta(days=today.weekday())
    existing_assessment = WeeklyAssessment.query.filter_by(
        user_id=user_id, week_start_date=start_of_week
    ).first()

    if existing_assessment:
        return jsonify({'error': 'Asesmen untuk minggu ini sudah dilakukan.'}), 409

    try:
        # Panggil service untuk menjalankan logika asesmen
        results = perform_weekly_assessment(user_id, quiz_answers)
        
        new_assessment = WeeklyAssessment(
            user_id=user_id,
            week_start_date=start_of_week,
            results=results, 
            energy_level=quiz_answers.get('energy_level'),
            mood=quiz_answers.get('mood'),
            symptoms=quiz_answers.get('symptoms')
        )
        db.session.add(new_assessment)
        db.session.commit()

        return jsonify(results)

    except ValueError as e:
        return jsonify({'error': str(e)}), 400
    except Exception as e:
        db.session.rollback()
        print(f"ASSESSMENT ERROR: {str(e)}") 
        return jsonify({'error': 'Terjadi kesalahan saat menjalankan asesmen.'}), 500