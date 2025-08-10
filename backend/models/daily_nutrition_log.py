from datetime import date
from models import db

class DailyNutritionLog(db.Model):
    __tablename__ = 'daily_nutrition_log'

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    
    date = db.Column(db.Date, nullable=False, default=date.today)

    daily_calories = db.Column(db.Float, nullable=False, default=0)
    daily_protein = db.Column(db.Float, nullable=False, default=0)
    daily_fat = db.Column(db.Float, nullable=False, default=0)
    daily_carbs = db.Column(db.Float, nullable=False, default=0)
    daily_folic_acid = db.Column(db.Float, nullable=False, default=0)
    daily_iron = db.Column(db.Float, nullable=False, default=0)
    daily_calcium = db.Column(db.Float, nullable=False, default=0)
    daily_zinc = db.Column(db.Float, nullable=False, default=0)
    daily_water = db.Column(db.Integer, nullable=False, default=0) 
    daily_sleep = db.Column(db.Float, nullable=False, default=0)

    def to_dict(self):
        """Mengonversi objek menjadi dictionary untuk respons API."""
        return {
            'id': self.id,
            'user_id': self.user_id,
            'date': self.date.isoformat(),
            'daily_calories': self.daily_calories,
            'daily_protein': self.daily_protein,
            'daily_fat': self.daily_fat,
            'daily_carbs': self.daily_carbs,
            'daily_folic_acid': self.daily_folic_acid,
            'daily_iron': self.daily_iron,
            'daily_calcium': self.daily_calcium,
            'daily_zinc': self.daily_zinc,
            'daily_water': self.daily_water,
            'daily_sleep': self.daily_sleep,
        }

    def __repr__(self):
        return f"<DailyNutritionLog user_id={self.user_id} date='{self.date}'>"
