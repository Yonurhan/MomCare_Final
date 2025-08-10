from models import db

class DailyNutrition(db.Model):
    __tablename__ = 'daily_nutrition'

    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    calories = db.Column(db.Float, nullable=False)
    protein = db.Column(db.Float, nullable=False)
    fat = db.Column(db.Float, nullable=False)
    carbs = db.Column(db.Float, nullable=False)

    def __init__(self, user_id, calories, protein, fat, carbs):
        self.user_id = user_id
        self.calories = calories
        self.protein = protein
        self.fat = fat
        self.carbs = carbs

    def to_dict(self):
        """Mengubah objek ke dictionary untuk respons API"""
        return {
            'id': self.id,
            'user_id': self.user_id,
            'calories': self.calories,
            'protein': self.protein,
            'fat': self.fat,
            'carbs': self.carbs,
        }