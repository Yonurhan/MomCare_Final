from datetime import datetime
from models import db

class WeeklyAssessment(db.Model):
    __tablename__ = 'weekly_assessments'

    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    week_start_date = db.Column(db.Date, nullable=False)

    # --- KOLOM-KOLOM BARU DITAMBAHKAN DI SINI ---

    # 1. Gejala Berisiko (Red Flags)
    red_flag_symptoms = db.Column(db.JSON, nullable=True) # Contoh: ["pendarahan", "sakit kepala hebat"]

    # 2. Kondisi Fisik & Kesejahteraan
    energy_level = db.Column(db.Integer, nullable=True) # Skala 1-5
    general_symptoms = db.Column(db.JSON, nullable=True) # Mengganti 'symptoms' menjadi lebih spesifik

    # 3. Kesehatan Mental
    mood = db.Column(db.String(50), nullable=True) # 'senang', 'cemas', 'sedih'

    # 4. Gaya Hidup Sehat
    healthy_habits = db.Column(db.JSON, nullable=True) # Contoh: ["minum air", "vitamin"]

    # Mengganti nama 'results' menjadi lebih spesifik
    nutrition_results = db.Column(db.JSON, nullable=False)

    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    # Memperbarui constructor __init__
    def __init__(self, user_id, week_start_date, nutrition_results, red_flag_symptoms=None, 
                 energy_level=None, mood=None, general_symptoms=None, healthy_habits=None):
        self.user_id = user_id
        self.week_start_date = week_start_date
        self.nutrition_results = nutrition_results
        self.red_flag_symptoms = red_flag_symptoms
        self.energy_level = energy_level
        self.mood = mood
        self.general_symptoms = general_symptoms
        self.healthy_habits = healthy_habits

    # Memperbarui to_dict untuk menyertakan semua data baru
    def to_dict(self):
        return {
            'id': self.id,
            'user_id': self.user_id,
            'week_start_date': self.week_start_date.isoformat(),
            'red_flag_symptoms': self.red_flag_symptoms,
            'energy_level': self.energy_level,
            'mood': self.mood,
            'general_symptoms': self.general_symptoms,
            'healthy_habits': self.healthy_habits,
            'nutrition_results': self.nutrition_results,
            'created_at': self.created_at.isoformat()
        }