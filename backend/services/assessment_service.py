# -*- coding: utf-8 -*-

import threading
import json
import os
from datetime import date, timedelta
from flask import current_app
from typing import List, Dict, Any, Optional
from dataclasses import dataclass, field
import logging

# --- Impor Model & Layanan ---
# Pastikan path impor ini sesuai dengan struktur proyek Anda
from models import db
from models.user import User
from models.daily_nutrition_log import DailyNutritionLog
from models.weekly_assessment import WeeklyAssessment
# Asumsi Anda memiliki file ini untuk kalkulasi nutrisi
from services.nutrition_service import calculate_nutrition_goals

# --- Definisi Exception Kustom ---
class UserNotFoundError(Exception):
    """Exception raised when a user is not found in the database."""
    pass

class InsufficientDataError(Exception):
    """Exception raised when essential user data (like LMP date) is missing."""
    pass

@dataclass
class Alert:
    """Mendefinisikan struktur objek Peringatan secara formal."""
    risk_score: float
    level: str
    title: str
    message: str
    category: str
    nutrient_key: Optional[str] = None # Kunci untuk identifikasi internal
    recommendations: List[Dict[str, Any]] = field(default_factory=list)
    lifestyle_tips: List[str] = field(default_factory=list)

@dataclass
class Goal:
    """Mendefinisikan struktur objek Tujuan Mingguan."""
    priority: int
    title: str
    description: str
    related_alert_title: str

# --- Basis Pengetahuan (Knowledge Base) yang Diperkaya ---
ACTIONABLE_RECOMMENDATIONS = {
    "calories": [
        { "type": "info", "text": "Fokus pada sumber kalori padat nutrisi untuk mendukung pertumbuhan janin." },
        { "food": "Alpukat", "serving_size": "1 buah sedang (200g)", "value": 322, "unit": "kcal", "tags": ["vegetarian", "vegan", "buah"] },
        { "food": "Kacang Almond", "serving_size": "1/4 cangkir (35g)", "value": 207, "unit": "kcal", "tags": ["vegetarian", "vegan", "kacang"] },
        { "food": "Ubi Jalar (panggang)", "serving_size": "1 buah besar (180g)", "value": 162, "unit": "kcal", "tags": ["vegetarian", "vegan", "umbi"]}
    ],
    "protein": [
        { "food": "Dada Ayam (panggang)", "serving_size": "100g", "value": 31, "unit": "g", "tags": ["non-veg", "daging"] },
        { "food": "Ikan Salmon (panggang)", "serving_size": "100g", "value": 22, "unit": "g", "tags": ["non-veg", "ikan"] },
        { "food": "Telur Rebus", "serving_size": "2 butir besar", "value": 12, "unit": "g", "tags": ["vegetarian", "telur"] },
        { "food": "Edamame (kukus)", "serving_size": "1 cangkir (155g)", "value": 17, "unit": "g", "tags": ["vegetarian", "vegan", "kacang"]}
    ],
    "carbs": [
        { "type": "info", "text": "Pilih karbohidrat kompleks untuk energi yang stabil dan serat yang tinggi." },
        { "food": "Nasi Merah (masak)", "serving_size": "1 cangkir (195g)", "value": 45, "unit": "g", "tags": ["vegetarian", "vegan", "biji-bijian"] },
        { "food": "Oatmeal (masak)", "serving_size": "1 cangkir (234g)", "value": 27, "unit": "g", "tags": ["vegetarian", "vegan", "biji-bijian"]}
    ],
    "fat": [
        { "type": "info", "text": "Lemak sehat sangat penting untuk perkembangan otak dan mata janin." },
        { "food": "Minyak Zaitun Extra Virgin", "serving_size": "1 sendok makan", "value": 14, "unit": "g", "tags": ["vegetarian", "vegan", "minyak"] },
        { "food": "Biji Chia", "serving_size": "2 sendok makan", "value": 9, "unit": "g", "tags": ["vegetarian", "vegan", "biji-bijian"]}
    ],
    "folic_acid": [
        { "food": "Bayam (dimasak)", "serving_size": "1 cangkir (180g)", "value": 263, "unit": "mcg", "tags": ["vegetarian", "vegan", "sayuran"] },
        { "food": "Brokoli (kukus)", "serving_size": "1 cangkir (156g)", "value": 168, "unit": "mcg", "tags": ["vegetarian", "vegan", "sayuran"] },
        { "food": "Jeruk", "serving_size": "1 buah besar", "value": 55, "unit": "mcg", "tags": ["vegetarian", "vegan", "buah"]}
    ],
    "iron": [
        { "food": "Lentil (dimasak)", "serving_size": "1 cangkir (200g)", "value": 6.6, "unit": "mg", "tags": ["vegetarian", "vegan", "kacang"] },
        { "food": "Daging Merah Tanpa Lemak (dimasak)", "serving_size": "100g", "value": 2.7, "unit": "mg", "tags": ["non-veg", "daging"] },
        { "food": "Tahu (dengan kalsium sulfat)", "serving_size": "100g", "value": 2.8, "unit": "mg", "tags": ["vegetarian", "vegan", "olahan kedelai"]}
    ],
    "calcium": [
        { "food": "Yoghurt Plain", "serving_size": "1 cangkir (245g)", "value": 450, "unit": "mg", "tags": ["vegetarian", "susu"] },
        { "food": "Susu Sapi", "serving_size": "1 cangkir (240ml)", "value": 300, "unit": "mg", "tags": ["vegetarian", "susu"]},
        { "food": "Tahu (dengan kalsium sulfat)", "serving_size": "100g", "value": 350, "unit": "mg", "tags": ["vegetarian", "vegan", "olahan kedelai"] }
    ]
}

SYMPTOM_KNOWLEDGE_BASE = {
    "mual": {
        "related_nutrients": ["protein"],
        "lifestyle_tips": [
            "Makan dalam porsi kecil tapi sering (misalnya, cracker atau roti kering) sebelum beranjak dari tempat tidur.",
            "Hindari makanan berlemak, pedas, atau beraroma kuat yang dapat memicu mual.",
            "Coba konsumsi jahe dalam bentuk teh hangat atau permen jahe."
        ]
    },
    "kelelahan": {
        "related_nutrients": ["iron", "protein", "calories"],
        "lifestyle_tips": [
            "Prioritaskan tidur malam yang berkualitas selama 7-9 jam.",
            "Lakukan tidur siang singkat (20-30 menit) jika memungkinkan.",
            "Lakukan aktivitas fisik ringan seperti berjalan kaki untuk meningkatkan sirkulasi dan energi."
        ]
    },
    "sakit punggung": {
        "related_nutrients": ["calcium"],
        "lifestyle_tips": [
            "Lakukan peregangan kucing-unta (cat-cow stretch) untuk fleksibilitas tulang belakang.",
            "Gunakan bantal kehamilan untuk menopang punggung dan perut saat tidur.",
            "Pilih kursi dengan sandaran punggung yang baik dan hindari duduk terlalu lama."
        ]
    }
}

# --- Kelas MealPlanner yang Ditingkatkan ---
class MealPlanner:
    def __init__(self, recommendations: Dict, preferences: Dict):
        self.recommendations = recommendations
        self.preferences = preferences
        self.logger = logging.getLogger(__name__)

    def _get_filtered_foods(self, nutrient: str) -> List[Dict]:
        """Menyaring makanan berdasarkan nutrisi dan preferensi diet pengguna."""
        nutrient_key = nutrient.lower().replace(' ', '_')
        all_recs = self.recommendations.get(nutrient_key, [])
        if not all_recs:
            return []

        filtered_list = []
        disliked_foods = {food.lower() for food in self.preferences.get('disliked_foods', [])}
        dietary_pref = self.preferences.get('dietary', 'all')

        for rec in all_recs:
            if 'food' in rec:
                if rec.get('food', '').lower() in disliked_foods:
                    continue

                tags = rec.get('tags', [])
                if dietary_pref == 'vegetarian' and 'non-veg' in tags:
                    continue
                if dietary_pref == 'vegan' and any(tag in tags for tag in ['non-veg', 'susu', 'telur']):
                    continue
                
                filtered_list.append(rec)
        return filtered_list

    def generate_plan(self, deficient_nutrients: List[str]) -> Optional[Dict]:
        if not deficient_nutrients:
            return None
        
        food_scores = {}
        all_relevant_foods = {}
        
        for nutrient in deficient_nutrients:
            for food in self._get_filtered_foods(nutrient):
                if 'food' not in food:
                    continue
                    
                food_name = food['food']
                all_relevant_foods[food_name] = food
                food_scores[food_name] = food_scores.get(food_name, 0) + 1
        
        sorted_foods = sorted(food_scores.items(), key=lambda item: item[1], reverse=True)
        if not sorted_foods:
            return None
            
        plan = {'breakfast': None, 'lunch': None, 'dinner': None}
        used_foods = set()

        if sorted_foods:
            lunch_food_name = sorted_foods[0][0]
            lunch_food = all_relevant_foods[lunch_food_name]
            plan['lunch'] = f"{lunch_food['food']} ({lunch_food['serving_size']}) - Sumber kaya nutrisi."
            used_foods.add(lunch_food_name)

        if len(sorted_foods) > 1:
            dinner_food_name = sorted_foods[1][0]
            dinner_food = all_relevant_foods[dinner_food_name]
            plan['dinner'] = f"{dinner_food['food']} ({dinner_food['serving_size']})."
            used_foods.add(dinner_food_name)

        breakfast_options = self._get_filtered_foods('carbs')
        for food in breakfast_options:
            if 'food' in food and food['food'] not in used_foods:
                plan['breakfast'] = f"{food['food']} sebagai sumber energi pagi."
                break

        return plan

# --- Kelas Layanan Inti yang Disempurnakan ---
class WeeklyAssessmentService:
    def __init__(self, user_id: int, quiz_answers: Dict):
        self.user_id = user_id
        self.quiz_answers = quiz_answers
        self.logger = logging.getLogger(__name__)
        self.user: Optional[User] = None
        self.preferences: Dict = {}
        self.health_profile: Dict = {}
        self.targets: Dict = {}
        self.metrics: Dict = {}
        self.historical_data: List[Dict] = []
        self.alerts: List[Alert] = []
        self.meal_planner: Optional[MealPlanner] = None

    def run(self) -> Dict:
        self.logger.info(f"Starting weekly assessment for user_id: {self.user_id}")
        self._load_context_and_init_planner()
        self._calculate_targets()
        self._process_logs()
        self._load_historical_data()
        self._analyze_risks()
        
        self.alerts.sort(key=lambda a: a.risk_score, reverse=True)
        self.logger.info(f"Generated {len(self.alerts)} alerts for user_id: {self.user_id}")
        
        goals = self._generate_weekly_goals()
        return self._compile_final_results(goals)

    def _load_context_and_init_planner(self):
        """Memuat data user, preferensi, dan profil kesehatan dari database."""
        self.user = User.query.get(self.user_id)
        if not self.user:
            raise UserNotFoundError(f"User with id {self.user_id} not found.")
        if not self.user.lmp_date:
            raise InsufficientDataError("LMP Date (HPHT) is required for assessment.")
        
        self.preferences = self.user.preferences or {'dietary': 'all', 'disliked_foods': []}
        self.health_profile = self.user.health_profile or {'pre_existing_conditions': [], 'age': 30}
        self.health_profile['age'] = self.user.age
        self.meal_planner = MealPlanner(ACTIONABLE_RECOMMENDATIONS, self.preferences)
        self.logger.info(f"Context loaded for user {self.user_id}")

    def _calculate_targets(self):
        """Menghitung target nutrisi dinamis dan statis."""
        dynamic_targets = calculate_nutrition_goals(age=self.user.age, weight=self.user.weight, height=self.user.height, lmp_date=self.user.lmp_date)
        static_targets = {'folic_acid': 600, 'iron': 27, 'calcium': 1300}
        self.targets = {**dynamic_targets, **static_targets}
        self.logger.debug(f"Calculated targets for user {self.user_id}: {self.targets}")

    def _process_logs(self):
        """Mengambil dan memproses log nutrisi mingguan."""
        today = date.today()
        seven_days_ago = today - timedelta(days=7)
        weekly_logs = DailyNutritionLog.query.filter(
            DailyNutritionLog.user_id == self.user_id,
            DailyNutritionLog.date.between(seven_days_ago, today)
        ).all()
        
        if not weekly_logs:
            self.logger.warning(f"No nutrition logs in the last 7 days for user {self.user_id}.")
            self.metrics = {
                'days_completed': {key: 0 for key in self.targets},
                'weekly_averages': {key: 0 for key in self.targets}
            }
            return
            
        days_completed = {key: 0 for key in self.targets}
        weekly_totals = {key: 0 for key in self.targets}
        
        log_count = len(set(log.date for log in weekly_logs))
        
        for log in weekly_logs:
            for nutrient, target_value in self.targets.items():
                log_value = getattr(log, f"daily_{nutrient}", 0) or 0
                weekly_totals[nutrient] += log_value
                if log_value >= target_value:
                    days_completed[nutrient] += 1
        
        weekly_averages = {k: v / log_count if log_count > 0 else 0 for k, v in weekly_totals.items()}
        
        self.metrics = {'days_completed': days_completed, 'weekly_averages': weekly_averages}
        self.logger.info(f"Processed {log_count} days of logs for user {self.user_id}")

    def _load_historical_data(self):
        """Memuat hasil asesmen dari 4 minggu terakhir untuk analisis tren."""
        four_weeks_ago = date.today() - timedelta(weeks=4)
        past_assessments = WeeklyAssessment.query.filter(
            WeeklyAssessment.user_id == self.user_id,
            WeeklyAssessment.week_start_date >= four_weeks_ago,
            WeeklyAssessment.status == 'completed'
        ).order_by(WeeklyAssessment.week_start_date.desc()).limit(3).all()
        self.historical_data = [pa.results for pa in past_assessments if pa.results]
        self.logger.info(f"Loaded {len(self.historical_data)} past assessments for user {self.user_id}")

    def _analyze_risks(self):
        """Menganalisis risiko berdasarkan gejala dan kekurangan nutrisi."""
        for symptom in self.quiz_answers.get('general_symptoms', []):
            self._score_and_create_alert_for_symptom(symptom)
        
        for nutrient, days in self.metrics.get('days_completed', {}).items():
            if days < 5:
                self._score_and_create_alert_for_nutrient(nutrient, days)

    def _score_and_create_alert_for_nutrient(self, nutrient: str, days_completed: int):
        target = self.targets.get(nutrient)
        if target is None: return
        
        average = self.metrics.get('weekly_averages', {}).get(nutrient, 0)
        score = (1 - (days_completed / 7)) * 40
        
        recurrence_count = sum(1 for past_result in self.historical_data 
                               for past_alert in past_result.get('alerts', []) 
                               if past_alert.get('level') == 'WARNING' and nutrient.lower() in past_alert.get('title', '').lower())
        
        if recurrence_count >= 2: score *= 1.5
        elif recurrence_count == 1: score *= 1.2
            
        if nutrient == 'iron' and 'anemia' in self.health_profile.get('pre_existing_conditions', []): score *= 2.0
            
        if nutrient == 'calcium' and self.health_profile.get('age', 30) > 35: score *= 1.1
        
        if score < 15: return
        
        level = 'WARNING' if score > 35 else 'INFO'
        nutrient_title = nutrient.replace('_', ' ').capitalize()
        message = (f"Asupan {nutrient_title} Anda belum konsisten ({days_completed}/7 hari). "
                   f"Rata-rata asupan Anda ~{average:.1f} dari target harian {target:.1f}.")
        
        self.alerts.append(Alert(
            risk_score=score,
            level=level,
            title=f"Perhatian pada Asupan {nutrient_title}",
            message=message,
            category='nutrition',
            nutrient_key=nutrient,
            recommendations=self.meal_planner._get_filtered_foods(nutrient) if self.meal_planner else []
        ))

    def _score_and_create_alert_for_symptom(self, symptom: str):
        symptom_key = symptom.lower().strip()
        if symptom_key not in SYMPTOM_KNOWLEDGE_BASE: return
        
        knowledge = SYMPTOM_KNOWLEDGE_BASE[symptom_key]
        score = 67.5 if symptom_key == 'kelelahan' else 30.0
        
        for nutrient in knowledge['related_nutrients']:
            days_completed = self.metrics.get('days_completed', {}).get(nutrient, 7)
            if days_completed < 5:
                score *= 1.25
        
        self.alerts.append(Alert(
            risk_score=score,
            level='INFO',
            title=f"Tips Mengelola {symptom.title()}",
            message=f"Untuk membantu mengelola {symptom}, beberapa tips gaya hidup dan nutrisi bisa dicoba.",
            category='symptom_management',
            lifestyle_tips=knowledge['lifestyle_tips']
        ))
        
    def _generate_weekly_goals(self) -> List[Goal]:
        if not self.alerts: return []
        
        goals = []
        top_alerts = self.alerts[:2]
        
        for i, alert in enumerate(top_alerts):
            title = ""
            description = ""
            if alert.category == 'nutrition':
                nutrient_name = alert.title.split(' Asupan ')[-1]
                title = f"Prioritas #{i+1}: Meningkatkan Asupan {nutrient_name}"
                description = f"Fokus mencoba 2-3 rekomendasi makanan kaya {nutrient_name} dan catat asupan Anda."
            elif alert.category == 'symptom_management':
                title = f"Prioritas #{i+1}: {alert.title}"
                description = "Pilih dan terapkan 2 tips gaya hidup yang disarankan."
            
            if title and description:
                goals.append(Goal(
                    priority=i + 1,
                    title=title,
                    description=description,
                    related_alert_title=alert.title
                ))
                
        return goals

    def _compile_final_results(self, goals: List[Goal]) -> Dict:
        deficient_nutrients = [
            a.nutrient_key for a in self.alerts 
            if a.category == 'nutrition' and a.risk_score > 30 and a.nutrient_key
        ]
        
        meal_plan = self.meal_planner.generate_plan(deficient_nutrients) if self.meal_planner else None
        if not meal_plan:
            meal_plan = {
                "breakfast": "Sarapan sehat (misal: oatmeal dengan buah)",
                "lunch": "Makan siang bergizi (misal: nasi merah dengan sayuran)",
                "dinner": "Makan malam ringan (misal: ikan panggang dengan salad)"
            }
        
        main_focus = self.alerts[0].title if self.alerts else "Kesehatan Optimal"
        highest_risk = self.alerts[0].risk_score if self.alerts else 0.0
        
        weeks_pregnant = (date.today() - self.user.lmp_date).days // 7
        if weeks_pregnant <= 13: trimester = 'trimester_1'
        elif 14 <= weeks_pregnant <= 27: trimester = 'trimester_2'
        else: trimester = 'trimester_3'
        
        return {
            "risk_overview": {
                "highest_risk_score": highest_risk,
                "main_focus": main_focus
            },
            "weekly_goals": [vars(g) for g in goals],
            "meal_plan_idea": meal_plan,
            "alerts": [vars(a) for a in self.alerts],
            "user_context": {
                "trimester": trimester,
                "preferences": self.preferences,
                "health_profile": self.health_profile
            }
        }

# --- Fungsi Latar Belakang (Background Task) ---
def perform_weekly_assessment_task(app, assessment_id: int):
    """Fungsi yang dijalankan di background thread untuk memproses asesmen."""
    with app.app_context():
        logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
        logger = logging.getLogger(__name__)

        assessment = WeeklyAssessment.query.get(assessment_id)
        if not assessment:
            logger.error(f"Assessment task failed: Assessment ID {assessment_id} not found.")
            return
            
        logger.info(f"Background task started for assessment ID {assessment_id} for user {assessment.user_id}.")
        
        try:
            service = WeeklyAssessmentService(assessment.user_id, assessment.quiz_answers or {})
            results = service.run()
            assessment.results = results
            assessment.status = 'completed'
            logger.info(f"Assessment ID {assessment_id} for user {assessment.user_id} completed successfully.")
        except (UserNotFoundError, InsufficientDataError) as e:
            logger.error(f"Assessment task for ID {assessment_id} failed due to data error: {e}")
            assessment.status = 'failed'
            assessment.results = {'error': str(e)}
        except Exception as e:
            logger.error(f"An unexpected error occurred in assessment task for ID {assessment_id}: {e}", exc_info=True)
            assessment.status = 'failed'
            assessment.results = {'error': 'Terjadi kesalahan internal yang tidak terduga saat memproses asesmen.'}
        
        db.session.commit()