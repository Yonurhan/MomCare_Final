# test_weekly_assessment_service.py
import unittest
from datetime import date, timedelta
from unittest.mock import patch, MagicMock
from services.assessment_service import (
    WeeklyAssessmentService,
    Alert,
    Goal,
    UserNotFoundError,
    InsufficientDataError
)
from models.user import User
from models.daily_nutrition_log import DailyNutritionLog
from models.weekly_assessment import WeeklyAssessment
from models import db


class TestWeeklyAssessmentService(unittest.TestCase):
    def setUp(self):
        # Setup in-memory database
        self.app = MagicMock()
        self.app.config = {'SQLALCHEMY_DATABASE_URI': 'sqlite:///:memory:'}
        db.init_app(self.app)
        with self.app.app_context():
            db.create_all()
        
        # Create test user
        self.user = User(
            id=1,
            name="Test User",
            email="test@example.com",
            lmp_date=date.today() - timedelta(weeks=10),
            weight=60,
            height=165,
            age=25
        )
        db.session.add(self.user)
        db.session.commit()

        # Sample quiz answers
        self.quiz_answers = {
            'general_symptoms': ['mual', 'kelelahan']
        }

    def tearDown(self):
        with self.app.app_context():
            db.session.remove()
            db.drop_all()

    def test_service_init_valid_user(self):
        """Test service initialization with valid user"""
        service = WeeklyAssessmentService(self.user.id, self.quiz_answers)
        self.assertEqual(service.user_id, 1)
        self.assertEqual(service.quiz_answers, self.quiz_answers)

    def test_service_init_invalid_user(self):
        """Test service initialization with invalid user"""
        with self.assertRaises(UserNotFoundError):
            WeeklyAssessmentService(999, self.quiz_answers)

    def test_service_init_missing_lmp(self):
        """Test missing LMP date raises error"""
        self.user.lmp_date = None
        db.session.commit()
        
        with self.assertRaises(InsufficientDataError):
            WeeklyAssessmentService(self.user.id, self.quiz_answers)

    def test_calculate_targets(self):
        """Test nutrition targets calculation"""
        service = WeeklyAssessmentService(self.user.id, self.quiz_answers)
        service._load_context_and_init_planner()
        service._calculate_targets()
        
        self.assertIn('calories', service.targets)
        self.assertIn('protein', service.targets)
        self.assertIn('folic_acid', service.targets)
        self.assertEqual(service.targets['folic_acid'], 600)
        self.assertGreater(service.targets['calories'], 2000)

    @patch('services.weekly_assessment_service.DailyNutritionLog.query')
    def test_process_logs_no_data(self, mock_query):
        """Test processing with no nutrition logs"""
        mock_query.filter.return_value.all.return_value = []
        
        service = WeeklyAssessmentService(self.user.id, self.quiz_answers)
        service._load_context_and_init_planner()
        service._process_logs()
        
        # Verify metrics
        self.assertEqual(service.metrics['days_completed']['calories'], 0)
        self.assertEqual(service.metrics['weekly_averages']['calories'], 0)
        
        # Verify alert was added
        self.assertEqual(len(service.alerts), 1)
        self.assertEqual(service.alerts[0].title, "Data Nutrisi Tidak Lengkap")

    def test_process_logs_with_data(self):
        """Test processing with actual nutrition logs"""
        # Create sample logs
        today = date.today()
        for i in range(7):
            log = DailyNutritionLog(
                user_id=self.user.id,
                date=today - timedelta(days=i),
                daily_calories=2200,
                daily_protein=80,
                daily_carbs=300,
                daily_fat=70,
                daily_folic_acid=550,
                daily_iron=25,
                daily_calcium=1200
            )
            db.session.add(log)
        db.session.commit()
        
        service = WeeklyAssessmentService(self.user.id, self.quiz_answers)
        service._load_context_and_init_planner()
        service._calculate_targets()
        service._process_logs()
        
        # Verify metrics
        self.assertEqual(service.metrics['days_completed']['calories'], 7)
        self.assertEqual(service.metrics['weekly_averages']['calories'], 2200)
        self.assertEqual(service.metrics['days_completed']['folic_acid'], 0)  # Below target

    def test_analyze_risks(self):
        """Test risk analysis logic"""
        # Create sample logs with deficiencies
        today = date.today()
        for i in range(7):
            log = DailyNutritionLog(
                user_id=self.user.id,
                date=today - timedelta(days=i),
                daily_calories=2200,
                daily_protein=80,
                daily_carbs=300,
                daily_fat=70,
                daily_folic_acid=400,  # Below target (600)
                daily_iron=15,         # Below target (27)
                daily_calcium=1000      # Below target (1300)
            )
            db.session.add(log)
        db.session.commit()
        
        service = WeeklyAssessmentService(self.user.id, self.quiz_answers)
        service.run()
        
        # Verify alerts generated
        self.assertGreater(len(service.alerts), 0)
        
        # Verify nutrient alerts
        nutrient_alerts = [a for a in service.alerts if a.category == 'nutrition']
        self.assertGreaterEqual(len(nutrient_alerts), 2)
        
        # Verify symptom alerts
        symptom_alerts = [a for a in service.alerts if a.category == 'symptom_management']
        self.assertEqual(len(symptom_alerts), 2)

    def test_alert_scoring(self):
        """Test risk scoring logic"""
        service = WeeklyAssessmentService(self.user.id, self.quiz_answers)
        service._load_context_and_init_planner()
        service._calculate_targets()
        
        # Simulate low iron intake
        service.metrics = {
            'days_completed': {'iron': 3},  # 3/7 days
            'weekly_averages': {'iron': 18}
        }
        
        # Add historical data for recurrence
        service.historical_data = [
            {'alerts': [{'title': 'Perhatian pada Asupan Iron'}]},
            {'alerts': [{'title': 'Perhatian pada Asupan Iron'}]}
        ]
        
        service._score_and_create_alert_for_nutrient('iron', 3)
        
        self.assertEqual(len(service.alerts), 1)
        alert = service.alerts[0]
        self.assertGreater(alert.risk_score, 35)
        self.assertEqual(alert.level, 'WARNING')
        self.assertIn('Iron', alert.title)
        self.assertGreater(len(alert.recommendations), 0)

    def test_meal_plan_generation(self):
        """Test meal plan generation"""
        service = WeeklyAssessmentService(self.user.id, self.quiz_answers)
        service._load_context_and_init_planner()
        
        # Test with deficient nutrients
        meal_plan = service.meal_planner.generate_plan(['iron', 'calcium'])
        self.assertIsNotNone(meal_plan)
        self.assertIn('breakfast', meal_plan)
        self.assertIn('lunch', meal_plan)
        self.assertIn('dinner', meal_plan)
        
        # Test with preferences
        service.preferences = {
            'dietary': 'vegetarian',
            'disliked_foods': ['Tahu']
        }
        meal_plan = service.meal_planner.generate_plan(['iron', 'calcium'])
        self.assertNotIn('Tahu', str(meal_plan))

    def test_goal_generation(self):
        """Test weekly goal generation"""
        service = WeeklyAssessmentService(self.user.id, self.quiz_answers)
        
        # Add sample alerts
        service.alerts = [
            Alert(
                risk_score=75,
                level='WARNING',
                title="Perhatian pada Asupan Zat Besi",
                message="",
                category='nutrition',
                nutrient_key='iron'
            ),
            Alert(
                risk_score=65,
                level='INFO',
                title="Tips Mengelola Kelelahan",
                message="",
                category='symptom_management'
            )
        ]
        
        goals = service._generate_weekly_goals()
        self.assertEqual(len(goals), 2)
        self.assertEqual(goals[0].priority, 1)
        self.assertIn("Zat Besi", goals[0].title)
        self.assertEqual(goals[1].priority, 2)
        self.assertIn("Kelelahan", goals[1].title)

    @patch('services.weekly_assessment_service.MealPlanner.generate_plan')
    def test_meal_plan_fallback(self, mock_generate):
        """Test meal plan fallback mechanism"""
        mock_generate.return_value = {}
        
        service = WeeklyAssessmentService(self.user.id, self.quiz_answers)
        results = service.run()
        
        self.assertIn('meal_plan_idea', results)
        self.assertIn('breakfast', results['meal_plan_idea'])
        self.assertIn('lunch', results['meal_plan_idea'])
        self.assertIn('dinner', results['meal_plan_idea'])

if __name__ == '__main__':
    unittest.main()