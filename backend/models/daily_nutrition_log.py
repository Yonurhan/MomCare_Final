from datetime import date
from models import db

class DailyNutritionLog(db.Model):
    __tablename__ = 'daily_nutrition_log'

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    date = db.Column(db.Date, nullable=False, default=date.today)

    daily_calories = db.Column(db.Float, default=0)
    daily_protein = db.Column(db.Float, default=0)
    daily_fat = db.Column(db.Float, default=0)
    daily_carbs = db.Column(db.Float, default=0)

    daily_folac_acid = db.Column(db.Float, default=0)
    daily_iron = db.Column(db.Float, default=0)
    daily_calcium = db.Column(db.Float, default=0)
    daily_zinc = db.Column(db.Float, default=0)

    daily_water = db.Column(db.Integer, default=0) 
    daily_sleep = db.Column(db.Float, default=0)  

    def __init__(self, user_id, daily_calories=0, 
                 daily_protein=0, daily_fat=0, daily_carbs=0, 
                 daily_water=0, daily_sleep=0, daily_folac_acid=0,
                 daily_iron = 0, daily_calcium = 0, daily_zinc = 0,
                  date=None):
        self.user_id = user_id
        self.daily_calories = daily_calories
        self.daily_protein = daily_protein
        self.daily_fat = daily_fat
        self.daily_carbs = daily_carbs
        self.daily_water = daily_water
        self.daily_sleep = daily_sleep
        self.daily_folac_acid = daily_folac_acid
        self.daily_iron = daily_iron
        self.daily_calcium = daily_calcium
        self.daily_zinc = daily_zinc
        self.date = date or date.today()

    def to_dict(self):
        """Converts the object to a dictionary for API responses."""
        return {
            'id': self.id,
            'user_id': self.user_id,
            'date': self.date.isoformat(),
            'daily_calories': self.daily_calories,
            'daily_protein': self.daily_protein,
            'daily_fat': self.daily_fat,
            'daily_carbs': self.daily_carbs,
            'daily_water': self.daily_water,
            'daily_sleep': self.daily_sleep,
            'daily_folac_acid': self.daily_folac_acid,
            'daily_iron': self.daily_iron,
            'daily_zinc': self.daily_zinc,
            'daily_calcium': self.daily_calcium,
        }

