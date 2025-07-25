# -*- coding: utf-8 -*-

import threading
import json
import os
from datetime import date, timedelta
from flask import current_app
from typing import List, Dict, Any, Optional
from dataclasses import dataclass, field

# --- Impor Model & Layanan ---
from models import db
from models.user import User
from models.daily_nutrition_log import DailyNutritionLog
from models.weekly_assessment import WeeklyAssessment
from services.nutrition_service import calculate_nutrition_goals

# --- Struktur Data Formal ---
@dataclass
class Alert:
    """Mendefinisikan struktur objek Peringatan secara formal."""
    risk_score: float
    level: str
    title: str
    message: str
    category: str
    recommendations: List[Dict[str, Any]] = field(default_factory=list)
    lifestyle_tips: List[str] = field(default_factory=list)

@dataclass
class Goal:
    """Mendefinisikan struktur objek Tujuan Mingguan."""
    priority: int
    title: str
    description: str
    related_alert_title: str

# --- PERBAIKAN KRITIS: Basis Pengetahuan (Knowledge Base) Dimasukkan Langsung ke Kode ---
# Ini adalah solusi paling andal untuk menghilangkan semua masalah terkait pembacaan file.

ACTIONABLE_RECOMMENDATIONS = {
  "calories": [
    { "type": "info", "text": "Fokus pada sumber kalori padat nutrisi." },
    { "food": "Alpukat", "serving_size": "1 buah sedang (200g)", "value": 322, "unit": "kcal", "tags": ["vegetarian", "vegan"] },
    { "food": "Kacang Almond", "serving_size": "1/4 cangkir (35g)", "value": 207, "unit": "kcal", "tags": ["vegetarian", "vegan"] }
  ],
  "protein": [
    { "food": "Dada Ayam (panggang)", "serving_size": "100g", "value": 31, "unit": "g", "tags": ["non-veg"] },
    { "food": "Ikan Salmon (panggang)", "serving_size": "100g", "value": 22, "unit": "g", "tags": ["non-veg"] },
    { "food": "Telur Rebus", "serving_size": "2 butir besar", "value": 12, "unit": "g", "tags": ["vegetarian"] }
  ],
  "carbs": [
    { "type": "info", "text": "Pilih karbohidrat kompleks untuk energi yang stabil." },
    { "food": "Nasi Merah (masak)", "serving_size": "1 cangkir (195g)", "value": 45, "unit": "g", "tags": ["vegetarian", "vegan"] }
  ],
  "fat": [
    { "type": "info", "text": "Lemak sehat penting untuk perkembangan otak janin." },
    { "food": "Minyak Zaitun Extra Virgin", "serving_size": "1 sendok makan", "value": 14, "unit": "g", "tags": ["vegetarian", "vegan"] }
  ],
  "folic_acid": [
    { "food": "Bayam (dimasak)", "serving_size": "1 cangkir (180g)", "value": 263, "unit": "mcg", "tags": ["vegetarian", "vegan"] },
    { "food": "Brokoli (kukus)", "serving_size": "1 cangkir (156g)", "value": 168, "unit": "mcg", "tags": ["vegetarian", "vegan"] }
  ],
  "iron": [
    { "food": "Lentil (dimasak)", "serving_size": "1 cangkir (200g)", "value": 6.6, "unit": "mg", "tags": ["vegetarian", "vegan"] },
    { "food": "Daging Merah Tanpa Lemak (dimasak)", "serving_size": "100g", "value": 2.7, "unit": "mg", "tags": ["non-veg"] }
  ],
  "calcium": [
    { "food": "Yoghurt Plain", "serving_size": "1 cangkir (245g)", "value": 450, "unit": "mg", "tags": ["vegetarian"] },
    { "food": "Tahu (dengan kalsium sulfat)", "serving_size": "100g", "value": 350, "unit": "mg", "tags": ["vegetarian", "vegan"] }
  ],
  "zinc": [
    { "food": "Daging Sapi (cincang)", "serving_size": "100g", "value": 4.8, "unit": "mg", "tags": ["non-veg"] },
    { "food": "Biji Labu", "serving_size": "1/4 cangkir", "value": 2.5, "unit": "mg", "tags": ["vegetarian", "vegan"] }
  ],
  "water": [
    { "type": "habit", "text": "Selalu bawa botol air minum agar mudah dijangkau." },
    { "type": "habit", "text": "Setel pengingat setiap jam untuk minum segelas air." }
  ],
  "sleep": [
    { "type": "habit", "text": "Buat jadwal tidur dan bangun yang konsisten, bahkan di akhir pekan." },
    { "type": "habit", "text": "Ciptakan rutinitas santai sebelum tidur: membaca buku atau mandi air hangat." }
  ]
}

SYMPTOM_KNOWLEDGE_BASE = {
  "mual": {
    "related_nutrients": ["b6", "protein"],
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
    "related_nutrients": ["calcium", "vitamin_d"],
    "lifestyle_tips": [
      "Lakukan peregangan kucing-unta (cat-cow stretch) untuk fleksibilitas tulang belakang.",
      "Gunakan bantal kehamilan untuk menopang punggung dan perut saat tidur.",
      "Pilih kursi dengan sandaran punggung yang baik dan hindari duduk terlalu lama."
    ]
  }
}

# --- Kelas MealPlanner ---
class MealPlanner:
    def __init__(self, recommendations: Dict, preferences: Dict):
        self.recommendations = recommendations
        self.preferences = preferences

    def _get_filtered_foods(self, nutrient: str) -> List[Dict]:
        recs = self.recommendations.get(nutrient.lower(), [])
        filtered_foods = []
        for rec in recs:
            if rec.get('type') == 'food':
                if rec['food'].lower() in self.preferences.get('disliked_foods', []): continue
                if self.preferences.get('dietary') == 'vegetarian' and 'non-veg' in rec['tags']: continue
                if self.preferences.get('dietary') == 'vegan' and ('non-veg' in rec['tags'] or 'vegetarian' in rec['tags']): continue
                filtered_foods.append(rec)
        return filtered_foods

    def generate_plan(self, deficient_nutrients: List[str]) -> Optional[Dict]:
        if not deficient_nutrients: return None
        food_scores, all_relevant_foods = {}, {}
        for nutrient in deficient_nutrients:
            for food in self._get_filtered_foods(nutrient):
                food_name = food['food']
                all_relevant_foods[food_name] = food
                food_scores[food_name] = food_scores.get(food_name, 0) + 1
        
        sorted_foods = sorted(food_scores.items(), key=lambda item: item[1], reverse=True)
        if not sorted_foods: return None
            
        plan, used_foods = {'breakfast': None, 'lunch': None, 'dinner': None}, set()
        if sorted_foods:
            lunch_food = all_relevant_foods[sorted_foods[0][0]]
            plan['lunch'] = f"{lunch_food['food']} ({lunch_food['serving_size']}) - Baik untuk {' & '.join(deficient_nutrients)}."
            used_foods.add(lunch_food['food'])
        if len(sorted_foods) > 1:
            dinner_food = all_relevant_foods[sorted_foods[1][0]]
            plan['dinner'] = f"{dinner_food['food']} ({dinner_food['serving_size']})."
            used_foods.add(dinner_food['food'])
            
        breakfast_options = self._get_filtered_foods('carbs') + self._get_filtered_foods('protein')
        for food in breakfast_options:
            if food['food'] not in used_foods:
                plan['breakfast'] = f"{food['food']} sebagai sumber energi pagi."
                break
        return plan

# --- Kelas Layanan Inti ---
class WeeklyAssessmentService:
    def __init__(self, user_id: int, quiz_answers: Dict):
        self.user_id = user_id
        self.quiz_answers = quiz_answers
        self.user: Optional[User] = None
        self.preferences: Dict = {}
        self.health_profile: Dict = {}
        self.targets: Dict = {}
        self.metrics: Dict = {}
        self.historical_data: List[Dict] = []
        self.alerts: List[Alert] = []
        self.meal_planner: Optional[MealPlanner] = None

    def run(self) -> Dict:
        self._load_context_and_init_planner()
        self._calculate_targets()
        self._process_logs()
        self._load_historical_data()
        self._analyze_risks()
        self.alerts.sort(key=lambda a: a.risk_score, reverse=True)
        goals = self._generate_weekly_goals()
        return self._compile_final_results(goals)

    def _load_context_and_init_planner(self):
        self.user = User.query.get(self.user_id)
        if not self.user or not self.user.lmp_date:
            raise ValueError("Pengguna atau HPHT tidak ditemukan.")
        self.preferences = self.user.preferences or {'dietary': 'all', 'disliked_foods': []}
        self.health_profile = self.user.health_profile or {'pre_existing_conditions': [], 'age': self.user.age}
        self.meal_planner = MealPlanner(ACTIONABLE_RECOMMENDATIONS, self.preferences)

    def _calculate_targets(self):
        dynamic_targets = calculate_nutrition_goals(age=self.user.age, weight=self.user.weight, height=self.user.height, lmp_date=self.user.lmp_date)
        static_targets = {'folic_acid': 600, 'iron': 27, 'calcium': 1300, 'zinc': 11, 'water': 2000, 'sleep': 8.0}
        self.targets = {**dynamic_targets, **static_targets}

    def _process_logs(self):
        today = date.today()
        seven_days_ago = today - timedelta(days=7)
        weekly_logs = DailyNutritionLog.query.filter(DailyNutritionLog.user_id == self.user_id, DailyNutritionLog.date.between(seven_days_ago, today)).all()
        if not weekly_logs:
            self.metrics = {'days_completed': {}, 'weekly_averages': {}}
            return
        days_completed = {key: 0 for key in self.targets.keys()}
        weekly_totals = {key: 0 for key in self.targets.keys()}
        log_to_target_map = {
            'daily_calories': 'calories', 'daily_protein': 'protein', 'daily_fat': 'fat',
            'daily_carbs': 'carbs', 'daily_folic_acid': 'folic_acid', 'daily_iron': 'iron',
            'daily_calcium': 'calcium', 'daily_zinc': 'zinc', 'daily_water': 'water', 'daily_sleep': 'sleep'
        }
        logs_by_date = {}
        for log in weekly_logs:
            if log.date not in logs_by_date:
                logs_by_date[log.date] = {key: 0 for key in self.targets.keys()}
            for log_attr, target_key in log_to_target_map.items():
                value = getattr(log, log_attr, 0) or 0
                logs_by_date[log.date][target_key] += value
                weekly_totals[target_key] += value
        for day_totals in logs_by_date.values():
            for nutrient, total_value in day_totals.items():
                if nutrient in self.targets and self.targets[nutrient] is not None and total_value >= self.targets[nutrient]:
                    days_completed[nutrient] += 1
        weekly_averages = {}
        log_count = len(logs_by_date)
        for nutrient, total in weekly_totals.items():
            weekly_averages[nutrient] = total / log_count if log_count > 0 else 0
        self.metrics = {'days_completed': days_completed, 'weekly_averages': weekly_averages}

    def _load_historical_data(self):
        four_weeks_ago = date.today() - timedelta(weeks=4)
        start_of_this_week = date.today() - timedelta(days=date.today().weekday())
        past_assessments = WeeklyAssessment.query.filter(
            WeeklyAssessment.user_id == self.user_id,
            WeeklyAssessment.week_start_date >= four_weeks_ago,
            WeeklyAssessment.week_start_date < start_of_this_week,
            WeeklyAssessment.status == 'completed'
        ).order_by(WeeklyAssessment.week_start_date.desc()).all()
        self.historical_data = [pa.results for pa in past_assessments if pa.results]

    def _analyze_risks(self):
        for nutrient, days in self.metrics.get('days_completed', {}).items():
            if days < 5:
                self._score_and_create_alert_for_nutrient(nutrient, days)
        for symptom in self.quiz_answers.get('general_symptoms', []):
            self._score_and_create_alert_for_symptom(symptom)

    def _score_and_create_alert_for_nutrient(self, nutrient: str, days_completed: int):
        target = self.targets.get(nutrient)
        if target is None: return
        average = self.metrics.get('weekly_averages', {}).get(nutrient, 0)
        score = (1 - (days_completed / 7)) * 40
        recurrence_count = 0
        for past_result in self.historical_data:
            for past_alert in past_result.get('alerts', []):
                if past_alert.get('category') == 'nutrition' and past_alert.get('level') == 'WARNING' and nutrient.lower() in past_alert.get('title', '').lower():
                    recurrence_count += 1
                    break
        if recurrence_count >= 2: score *= 1.5
        elif recurrence_count == 1: score *= 1.2
        if nutrient == 'iron' and 'anemia' in self.health_profile.get('pre_existing_conditions', []):
            score *= 2.0
        if nutrient == 'calcium' and self.health_profile.get('age', 30) > 35:
            score *= 1.1
        if score < 15: return
        level = 'WARNING' if score > 35 else 'INFO'
        # Menggunakan .capitalize() untuk tampilan yang lebih baik di judul
        nutrient_title = nutrient.replace('_', ' ').capitalize()
        message = (f"Asupan {nutrient_title} Anda belum konsisten ({days_completed}/7 hari). "
                   f"Rata-rata asupan Anda ~{average:.1f} dari target harian {target:.1f}.")
        
        self.alerts.append(Alert(
            risk_score=score, level=level, title=f"Perhatian pada Asupan {nutrient_title}",
            message=message, category='nutrition', recommendations=self.meal_planner._get_filtered_foods(nutrient)
        ))

    def _score_and_create_alert_for_symptom(self, symptom: str):
        symptom_key = symptom.lower()
        if symptom_key not in SYMPTOM_KNOWLEDGE_BASE: return
        knowledge = SYMPTOM_KNOWLEDGE_BASE[symptom_key]
        score = 20.0
        for nutrient in knowledge['related_nutrients']:
            if self.metrics.get('days_completed', {}).get(nutrient, 7) < 5:
                score *= 1.5
        self.alerts.append(Alert(
            risk_score=score, level='INFO', title=f"Tips Mengelola {symptom.title()}",
            message=f"Untuk membantu mengelola {symptom}, beberapa tips gaya hidup dan nutrisi bisa dicoba.",
            category='symptom_management', lifestyle_tips=knowledge['lifestyle_tips']
        ))
        
    def _generate_weekly_goals(self) -> List[Goal]:
        if not self.alerts: return []
        goals = []
        top_alerts = sorted(self.alerts, key=lambda a: a.risk_score, reverse=True)[:2]
        for i, alert in enumerate(top_alerts):
            description = ""
            if alert.category == 'nutrition':
                nutrient_name = alert.title.split(' Asupan ')[-1]
                description = f"Fokus untuk mencoba 2-3 rekomendasi makanan kaya {nutrient_name} dan catat asupan Anda setiap hari."
            elif alert.category == 'symptom_management':
                description = f"Pilih dan terapkan 2 tips gaya hidup yang kami sarankan untuk mengurangi gejala ini."
            if description:
                goals.append(Goal(
                    priority=i + 1,
                    title=f"Prioritas #{i+1}: {alert.title.replace('Perhatian pada Asupan', 'Meningkatkan Asupan')}",
                    description=description,
                    related_alert_title=alert.title
                ))
        return goals

    def _compile_final_results(self, goals: List[Goal]) -> Dict:
        deficient_nutrients = [a.title.split(' Asupan ')[-1].lower() for a in self.alerts if a.category == 'nutrition' and a.risk_score > 30]
        meal_plan = self.meal_planner.generate_plan(deficient_nutrients) if self.meal_planner else None
        alerts_as_dict = [vars(a) for a in self.alerts]
        goals_as_dict = [vars(g) for g in goals]
        main_focus = self.alerts[0].title if self.alerts else "Semua target terpenuhi dengan baik."
        highest_risk = self.alerts[0].risk_score if self.alerts else 0
        weeks_pregnant = (date.today() - self.user.lmp_date).days // 7
        if weeks_pregnant <= 13: trimester = 'trimester_1'
        elif 14 <= weeks_pregnant <= 27: trimester = 'trimester_2'
        else: trimester = 'trimester_3'
        return {
            "risk_overview": {"highest_risk_score": highest_risk, "main_focus": main_focus},
            "weekly_goals": goals_as_dict,
            "meal_plan_idea": meal_plan,
            "alerts": alerts_as_dict,
            "user_context": {"trimester": trimester, "preferences": self.preferences, "health_profile": self.health_profile}
        }

def perform_weekly_assessment_task(app, assessment_id: int):
    """Fungsi yang akan dijalankan di background."""
    with app.app_context():
        assessment = WeeklyAssessment.query.get(assessment_id)
        if not assessment:
            current_app.logger.warning(f"Assessment task started but assessment ID {assessment_id} not found.")
            return
        try:
            service = WeeklyAssessmentService(assessment.user_id, assessment.quiz_answers)
            results = service.run()
            assessment.results = results
            assessment.status = 'completed'
        except Exception as e:
            current_app.logger.error(f"Assessment task failed for ID {assessment_id}: {e}", exc_info=True)
            assessment.status = 'failed'
            assessment.results = {'error': 'Terjadi kesalahan internal saat memproses asesmen.'}
        db.session.commit()
