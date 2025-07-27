# models/weekly_assessment.py

from models import db

class WeeklyAssessment(db.Model):
    __tablename__ = 'weekly_assessments'

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    week_start_date = db.Column(db.Date, nullable=False)

    # --- PERBAIKAN: Mengganti JSONB menjadi db.JSON ---
    # `db.JSON` adalah tipe data generik yang kompatibel dengan MySQL.
    quiz_answers = db.Column(db.JSON, nullable=True)
    results = db.Column(db.JSON, nullable=True)
    # ----------------------------------------------------

    status = db.Column(db.String(20), nullable=False, default='processing')
    has_critical_alert = db.Column(db.Boolean, nullable=False, default=False)

    created_at = db.Column(db.DateTime, server_default=db.func.current_timestamp())
    updated_at = db.Column(db.DateTime, server_default=db.func.current_timestamp(), onupdate=db.func.current_timestamp())

    # Definisikan relasi dengan User (jika belum ada)
    # user = db.relationship('User', back_populates='assessments')

    def to_dict(self):
        """Mengonversi objek model menjadi dictionary."""
        return {
            'id': self.id,
            'user_id': self.user_id,
            'week_start_date': self.week_start_date.isoformat() if self.week_start_date else None,
            'quiz_answers': self.quiz_answers,
            'results': self.results,
            'status': self.status,
            'has_critical_alert': self.has_critical_alert,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at else None
        }