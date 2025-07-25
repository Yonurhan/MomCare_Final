from flask import Blueprint, request, jsonify, current_app, url_for
from flask_jwt_extended import jwt_required, get_jwt_identity
from datetime import date, timedelta
import threading

from models import db
from models.weekly_assessment import WeeklyAssessment
from services.assessment_service import perform_weekly_assessment_task

assessment_bp = Blueprint('assessment', __name__, url_prefix='/assessment')

@assessment_bp.route('/perform', methods=['POST'])
@jwt_required()
def perform_assessment_async():
    """
    Endpoint untuk MEMULAI proses asesmen. Proses berjalan di background.
    (Tidak ada perubahan, kode ini sudah siap)
    """
    user_id = int(get_jwt_identity())
    quiz_answers = request.get_json()
    if not quiz_answers:
        return jsonify({'error': 'Request body tidak boleh kosong.'}), 400

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
    """
    Endpoint untuk MENGAMBIL hasil asesmen setelah selesai diproses.
    (Tidak ada perubahan, kode ini sudah siap)
    """
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
        'created_at': assessment.created_at.isoformat()
    }), 200