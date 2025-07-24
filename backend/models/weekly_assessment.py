from datetime import datetime, date
from models import db

class WeeklyAssessment(db.Model):
    __tablename__ = 'weekly_assessments'

    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    
    # Mencatat tanggal asesmen ini dimulai (misalnya, setiap hari Senin)
    week_start_date = db.Column(db.Date, nullable=False)

    # Kolom untuk menyimpan jawaban kuis subjektif
    energy_level = db.Column(db.Integer, nullable=True) # Skala 1-5
    mood = db.Column(db.String(50), nullable=True)      # 'senang', 'biasa', 'sedih'
    symptoms = db.Column(db.JSON, nullable=True)        # Contoh: ["mual", "sakit punggung"]

    # Kolom untuk menyimpan hasil analisis nutrisi
    results = db.Column(db.JSON, nullable=False)        # Contoh: {"zinc_days": 3, "iron_days": 7}

    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    def __init__(self, user_id, week_start_date, results, energy_level=None, mood=None, symptoms=None):
        self.user_id = user_id
        self.week_start_date = week_start_date
        self.results = results
        self.energy_level = energy_level
        self.mood = mood
        self.symptoms = symptoms

    def to_dict(self):
        """Mengubah objek ke dictionary untuk respons API."""
        return {
            'id': self.id,
            'user_id': self.user_id,
            'week_start_date': self.week_start_date.isoformat(),
            'energy_level': self.energy_level,
            'mood': self.mood,
            'symptoms': self.symptoms,
            'results': self.results,
            'created_at': self.created_at.isoformat()
        }