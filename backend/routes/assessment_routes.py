# routes/assessment_routes.py

from flask import Blueprint, request, jsonify, current_app, url_for
from flask_jwt_extended import jwt_required, get_jwt_identity
from datetime import date, timedelta
import threading

from models import db
from models.weekly_assessment import WeeklyAssessment
from services.assessment_service import perform_weekly_assessment_task

assessment_bp = Blueprint('assessment', __name__, url_prefix='/assessment')


@assessment_bp.route('/status', methods=['GET'])
@jwt_required()
def get_assessment_status():
    """Endpoint untuk MEMERIKSA status asesmen minggu ini."""
    user_id = int(get_jwt_identity())
    
    # Tentukan tanggal awal minggu ini (Senin)
    today = date.today()
    start_of_week = today - timedelta(days=today.weekday())

    # Cari asesmen yang sudah selesai atau sedang diproses untuk minggu ini
    existing_assessment = WeeklyAssessment.query.filter(
        WeeklyAssessment.user_id == user_id,
        WeeklyAssessment.week_start_date == start_of_week,
        WeeklyAssessment.status.in_(['completed', 'processing'])
    ).first()

    if existing_assessment:
        # Jika ada, kirim status 'completed' dan ID-nya
        return jsonify({
            'status': 'completed',
            'assessment_id': existing_assessment.id
        }), 200
    else:
        # Jika tidak ada, kirim status 'pending'
        return jsonify({
            'status': 'pending'
        }), 200

@assessment_bp.route('/perform', methods=['POST'])
@jwt_required()
def perform_assessment_async():
    """Endpoint untuk MEMULAI proses asesmen."""
    user_id = int(get_jwt_identity())
    request_data = request.get_json()
    if not request_data or 'quiz_answers' not in request_data:
        return jsonify({'error': 'Request body harus berisi "quiz_answers".'}), 400
    
    quiz_answers = request_data['quiz_answers']

    start_of_week = date.today() - timedelta(days=date.today().weekday())
    
    existing = WeeklyAssessment.query.filter(
        WeeklyAssessment.user_id == user_id,
        WeeklyAssessment.week_start_date == start_of_week,
        WeeklyAssessment.status.in_(['completed', 'processing'])
    ).first()
    if existing:
        return jsonify({
            'message': 'Asesmen untuk minggu ini sudah selesai atau sedang diproses.',
            'status': existing.status,
            'result_url': url_for('assessment.get_assessment_result', assessment_id=existing.id, _external=True)
        }), 409

    new_assessment = WeeklyAssessment(
        user_id=user_id,
        week_start_date=start_of_week,
        quiz_answers=quiz_answers,
        status='processing'
    )
    db.session.add(new_assessment)
    db.session.commit()

    app = current_app._get_current_object()
    thread = threading.Thread(
        target=perform_weekly_assessment_task,
        args=(app, new_assessment.id)
    )
    thread.daemon = True
    thread.start()

    return jsonify({
        'message': 'Asesmen sedang diproses. Silakan periksa kembali dalam beberapa saat.',
        'status': 'processing',
        'result_url': url_for('assessment.get_assessment_result', assessment_id=new_assessment.id, _external=True)
    }), 202


@assessment_bp.route('/result/<int:assessment_id>', methods=['GET'])
@jwt_required()
def get_assessment_result(assessment_id):
    """Endpoint untuk MENGAMBIL hasil asesmen."""
    user_id = int(get_jwt_identity())
    
    assessment = WeeklyAssessment.query.filter_by(id=assessment_id, user_id=user_id).first_or_404(
        'Asesmen tidak ditemukan atau Anda tidak memiliki akses.'
    )

    if assessment.status == 'processing':
        return jsonify({
            'status': 'processing',
            'message': 'Hasil asesmen masih sedang diproses.'
        }), 202
    
    return jsonify({
        'status': assessment.status,
        'results': assessment.results,
        'created_at': assessment.created_at.isoformat() if assessment.created_at else None
    }), 200
