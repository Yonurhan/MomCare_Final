import threading
import json
import os
from datetime import date, timedelta, datetime
from flask import current_app
from typing import List, Dict, Any, Optional
from dataclasses import dataclass, field
import logging

from models import db
from models.user import User
from models.daily_nutrition_log import DailyNutritionLog
from models.weekly_assessment import WeeklyAssessment
from services.nutrition_service import calculate_nutrition_goals

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
    nutrient_key: Optional[str] = None  # Kunci untuk identifikasi internal
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
        {"type": "info", "text": "Fokus pada sumber kalori padat nutrisi untuk mendukung pertumbuhan janin."},
        {"food": "Alpukat", "serving_size": "1 buah sedang (200g)", "value": 322, "unit": "kcal", "tags": ["vegetarian", "vegan", "buah"]},
        {"food": "Kacang Almond", "serving_size": "1/4 cangkir (35g)", "value": 207, "unit": "kcal", "tags": ["vegetarian", "vegan", "kacang"]},
        {"food": "Ubi Jalar (panggang)", "serving_size": "1 buah besar (180g)", "value": 162, "unit": "kcal", "tags": ["vegetarian", "vegan", "umbi"]}
    ],
    "protein": [
        {"food": "Dada Ayam (panggang)", "serving_size": "100g", "value": 31, "unit": "g", "tags": ["non-veg", "daging"]},
        {"food": "Ikan Salmon (panggang)", "serving_size": "100g", "value": 22, "unit": "g", "tags": ["non-veg", "ikan"]},
        {"food": "Telur Rebus", "serving_size": "2 butir besar", "value": 12, "unit": "g", "tags": ["vegetarian", "telur"]},
        {"food": "Edamame (kukus)", "serving_size": "1 cangkir (155g)", "value": 17, "unit": "g", "tags": ["vegetarian", "vegan", "kacang"]}
    ],
    "carbs": [
        {"type": "info", "text": "Pilih karbohidrat kompleks untuk energi yang stabil dan serat yang tinggi."},
        {"food": "Nasi Merah (masak)", "serving_size": "1 cangkir (195g)", "value": 45, "unit": "g", "tags": ["vegetarian", "vegan", "biji-bijian"]},
        {"food": "Oatmeal (masak)", "serving_size": "1 cangkir (234g)", "value": 27, "unit": "g", "tags": ["vegetarian", "vegan", "biji-bijian"]}
    ],
    "fat": [
        {"type": "info", "text": "Lemak sehat sangat penting untuk perkembangan otak dan mata janin."},
        {"food": "Minyak Zaitun Extra Virgin", "serving_size": "1 sendok makan", "value": 14, "unit": "g", "tags": ["vegetarian", "vegan", "minyak"]},
        {"food": "Biji Chia", "serving_size": "2 sendok makan", "value": 9, "unit": "g", "tags": ["vegetarian", "vegan", "biji-bijian"]}
    ],
    "folic_acid": [
        {"food": "Bayam (dimasak)", "serving_size": "1 cangkir (180g)", "value": 263, "unit": "mcg", "tags": ["vegetarian", "vegan", "sayuran"]},
        {"food": "Brokoli (kukus)", "serving_size": "1 cangkir (156g)", "value": 168, "unit": "mcg", "tags": ["vegetarian", "vegan", "sayuran"]},
        {"food": "Jeruk", "serving_size": "1 buah besar", "value": 55, "unit": "mcg", "tags": ["vegetarian", "vegan", "buah"]}
    ],
    "iron": [
        {"food": "Lentil (dimasak)", "serving_size": "1 cangkir (200g)", "value": 6.6, "unit": "mg", "tags": ["vegetarian", "vegan", "kacang"]},
        {"food": "Daging Merah Tanpa Lemak (dimasak)", "serving_size": "100g", "value": 2.7, "unit": "mg", "tags": ["non-veg", "daging"]},
        {"food": "Tahu (dengan kalsium sulfat)", "serving_size": "100g", "value": 2.8, "unit": "mg", "tags": ["vegetarian", "vegan", "olahan kedelai"]}
    ],
    "calcium": [
        {"food": "Yoghurt Plain", "serving_size": "1 cangkir (245g)", "value": 450, "unit": "mg", "tags": ["vegetarian", "susu"]},
        {"food": "Susu Sapi", "serving_size": "1 cangkir (240ml)", "value": 300, "unit": "mg", "tags": ["vegetarian", "susu"]},
        {"food": "Tahu (dengan kalsium sulfat)", "serving_size": "100g", "value": 350, "unit": "mg", "tags": ["vegetarian", "vegan", "olahan kedelai"]}
    ],
    "sleep": [
        {"type": "info", "text": "Kualitas tidur sangat penting untuk kesehatan ibu dan perkembangan janin."},
        {"tip": "Jadwal Tidur Konsisten", "description": "Pergi tidur dan bangun pada waktu yang sama setiap hari."},
        {"tip": "Lingkungan Tidur Nyaman", "description": "Pastikan kamar tidur gelap, sejuk, dan tenang."}
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

class MealPlanner:
    def __init__(self, recommendations: Dict, preferences: Dict):
        self.recommendations = recommendations
        self.preferences = preferences
        self.logger = logging.getLogger(__name__)
        self.logger.setLevel(logging.DEBUG)

    def _get_filtered_foods(self, nutrient: str) -> List[Dict]:
        """Menyaring makanan berdasarkan nutrisi dan preferensi diet pengguna."""
        nutrient_key = nutrient.lower().replace(' ', '_')
        
        self.logger.debug(f"Mencari rekomendasi untuk nutrisi: '{nutrient_key}'")
        all_recs = self.recommendations.get(nutrient_key, [])
        
        if not all_recs:
            self.logger.warning(f"Tidak ada rekomendasi ditemukan untuk nutrisi: '{nutrient_key}'")
            return []

        filtered_list = []
        disliked_foods = {food.lower() for food in self.preferences.get('disliked_foods', [])}
        dietary_pref = self.preferences.get('dietary', 'all').lower()

        for rec in all_recs:
            if rec.get('type') == 'info' or rec.get('tip'):
                filtered_list.append(rec)
                continue
                
            if 'food' in rec:
                food_name = rec['food'].lower()
                
                if food_name in disliked_foods:
                    self.logger.debug(f"Melewati {food_name} karena ada di daftar tidak disukai")
                    continue
                
                tags = [tag.lower() for tag in rec.get('tags', [])]
                skip = False
                
                if dietary_pref == 'vegetarian':
                    if 'non-veg' in tags:
                        self.logger.debug(f"Melewati {food_name} karena preferensi vegetarian")
                        skip = True
                elif dietary_pref == 'vegan':
                    if any(tag in tags for tag in ['non-veg', 'daging', 'ikan', 'susu', 'telur']):
                        self.logger.debug(f"Melewati {food_name} karena preferensi vegan")
                        skip = True
                
                if not skip:
                    filtered_list.append(rec)

        self.logger.info(f"Menemukan {len(filtered_list)} rekomendasi untuk '{nutrient_key}' setelah filter")
        return filtered_list

    def generate_plan(self, deficient_nutrients: List[str]) -> Dict:
        """Menghasilkan ide rencana makan yang lebih andal."""
        self.logger.info(f"Memulai pembuatan meal plan untuk nutrisi: {deficient_nutrients}")
        
        if not deficient_nutrients:
            self.logger.info("Tidak ada nutrisi kurang spesifik, menggunakan plan umum")
            return self._get_general_plan()
        
        def format_food_entry(food):
            base = f"{food['food']} ({food['serving_size']})"
            if 'value' in food and 'unit' in food:
                return f"{base} - {food['value']}{food['unit']}"
            return base
        
        food_scores = {}
        all_relevant_foods = {}
        
        for nutrient in deficient_nutrients:
            foods = self._get_filtered_foods(nutrient)
            for food in foods:
                if 'food' not in food:
                    continue
                    
                food_name = food['food']
                all_relevant_foods[food_name] = food
                food_scores[food_name] = food_scores.get(food_name, 0) + 1
        
        if not food_scores:
            self.logger.warning("Tidak ada makanan yang cocok, menggunakan plan umum")
            return self._get_general_plan()

        sorted_foods = sorted(food_scores.items(), key=lambda item: item[1], reverse=True)
        used_foods = set()

        plan = {
            "breakfast": "Makanan kaya karbohidrat kompleks untuk energi pagi",
            "lunch": "Makanan bergizi seimbang dengan protein dan sayuran",
            "dinner": "Makanan ringan namun bergizi untuk malam hari",
            "snacks": "Camilan sehat di antara waktu makan",
            "note": "Rencana makan yang disesuaikan berdasarkan kebutuhan nutrisi"
        }
        
        # Sarapan: fokus pada karbohidrat kompleks
        breakfast_options = self._get_filtered_foods('carbs')
        for food in breakfast_options:
            if 'food' in food and food['food'] not in used_foods:
                plan['breakfast'] = format_food_entry(food)
                used_foods.add(food['food'])
                break
        
        # Makan siang: makanan paling bernutrisi
        if sorted_foods:
            lunch_food_name = sorted_foods[0][0]
            lunch_food = all_relevant_foods[lunch_food_name]
            plan['lunch'] = format_food_entry(lunch_food)
            used_foods.add(lunch_food_name)
        
        # Makan malam: makanan bernutrisi berbeda
        dinner_food = None
        for food_name, _ in sorted_foods:
            if food_name not in used_foods:
                dinner_food = all_relevant_foods[food_name]
                used_foods.add(food_name)
                break
        
        if dinner_food:
            plan['dinner'] = format_food_entry(dinner_food)
        
        # Tambahkan camilan sehat
        snack_options = self._get_filtered_foods('calories') + self._get_filtered_foods('protein')
        snack_recs = []
        for food in snack_options:
            if 'food' in food and food['food'] not in used_foods and len(snack_recs) < 2:
                snack_recs.append(format_food_entry(food))
                used_foods.add(food['food'])
        
        if snack_recs:
            plan['snacks'] = ", ".join(snack_recs)
        
        # Tambahkan rekomendasi khusus
        special_recs = []
        for nutrient in deficient_nutrients:
            for rec in self._get_filtered_foods(nutrient):
                if 'type' in rec and rec['type'] == 'info' and rec['text'] not in special_recs:
                    special_recs.append(rec['text'])
        
        if special_recs:
            plan['note'] += " | " + " | ".join(special_recs)
        
        self.logger.info(f"Berhasil membuat meal plan: {plan}")
        return plan

    def _get_general_plan(self) -> Dict:
        """Rencana makan umum untuk semua kehamilan."""
        return {
            "breakfast": "Oatmeal dengan buah segar dan kacang almond",
            "lunch": "Salad sayuran dengan dada ayam panggang dan quinoa",
            "dinner": "Ikan panggang dengan ubi jalar kukus dan brokoli",
            "snacks": "Yoghurt, buah segar, atau segenggam kacang",
            "note": "Rencana makan umum untuk kehamilan sehat"
        }

# --- Kelas Layanan Inti yang Disempurnakan ---
class WeeklyAssessmentService:
    def __init__(self, user_id: int, quiz_answers: Dict):
        self.user_id = user_id
        self.quiz_answers = quiz_answers
        self.logger = logging.getLogger(__name__)
        self.logger.setLevel(logging.DEBUG)
        self.user: Optional[User] = None
        self.preferences: Dict = {}
        self.health_profile: Dict = {}
        self.targets: Dict = {}
        self.metrics: Dict = {}
        self.historical_data: List[Dict] = []
        self.alerts: List[Alert] = []
        self.meal_planner: Optional[MealPlanner] = None

    def run(self) -> Dict:
        self.logger.info(f"Memulai asesmen mingguan untuk user_id: {self.user_id}")
        try:
            self._load_context_and_init_planner()
            self._calculate_targets()
            self._process_logs()
            self._load_historical_data()
            self._analyze_risks()
            
            self.alerts.sort(key=lambda a: a.risk_score, reverse=True)
            self.logger.info(f"Menghasilkan {len(self.alerts)} peringatan untuk user_id: {self.user_id}")
            
            goals = self._generate_weekly_goals()
            return self._compile_final_results(goals)
        except Exception as e:
            self.logger.exception(f"Error dalam asesmen mingguan: {e}")
            return {
                "error": "Terjadi kesalahan dalam pemrosesan asesmen",
                "details": str(e)
            }

    def _load_context_and_init_planner(self):
        self.user = User.query.get(self.user_id)
        if not self.user:
            raise UserNotFoundError(f"User dengan id {self.user_id} tidak ditemukan.")
        if not self.user.lmp_date:
            raise InsufficientDataError("Tanggal HPHT diperlukan untuk asesmen.")
        
        self.preferences = self.user.preferences or {'dietary': 'all', 'disliked_foods': []}
        self.health_profile = self.user.health_profile or {'pre_existing_conditions': []}
        self.health_profile['age'] = self.user.age
        self.meal_planner = MealPlanner(ACTIONABLE_RECOMMENDATIONS, self.preferences)
        self.logger.info(f"Konteks dimuat untuk user {self.user_id}")

    def _calculate_targets(self):
        """Menghitung target nutrisi dinamis dan statis."""
        if not all([self.user.age, self.user.weight, self.user.height, self.user.lmp_date]):
             raise InsufficientDataError("Usia, berat badan, tinggi badan, dan tanggal HPHT diperlukan untuk menghitung target.")
        
        try:
            dynamic_targets = calculate_nutrition_goals(
                age=self.user.age, 
                weight=self.user.weight, 
                height=self.user.height, 
                lmp_date=self.user.lmp_date
            )
            static_targets = {'folic_acid': 600, 'iron': 27, 'calcium': 1300, 'sleep': 8.0}
            self.targets = {**dynamic_targets, **static_targets}
            self.logger.debug(f"Target terhitung untuk user {self.user_id}: {self.targets}")
        except Exception as e:
            self.logger.error(f"Kesalahan dalam perhitungan target: {e}")
            # Gunakan nilai default jika perhitungan gagal
            self.targets = {
                'calories': 2200, 
                'protein': 75, 
                'carbs': 300, 
                'fat': 75, 
                'folic_acid': 600, 
                'iron': 27, 
                'calcium': 1300,
                'sleep': 8.0
            }

    def _process_logs(self):
        """Mengagregasi log harian sebelum membandingkan dengan target."""
        today = date.today()
        seven_days_ago = today - timedelta(days=7)
        weekly_logs = DailyNutritionLog.query.filter(
            DailyNutritionLog.user_id == self.user_id,
            DailyNutritionLog.date.between(seven_days_ago, today)
        ).all()

        # Inisialisasi metrik dengan nilai nol
        self.metrics = {
            'days_completed': {key: 0 for key in self.targets},
            'weekly_averages': {key: 0.0 for key in self.targets}
        }
        
        if not weekly_logs:
            self.logger.warning(f"Tidak ada log nutrisi dalam 7 hari terakhir untuk user {self.user_id}.")
            return

        # Pemetaan atribut log ke kunci target
        log_to_target_map = {
            'daily_calories': 'calories',
            'daily_protein': 'protein',
            'daily_fat': 'fat',
            'daily_carbs': 'carbs',
            'daily_folic_acid': 'folic_acid',
            'daily_iron': 'iron',
            'daily_calcium': 'calcium',
            'daily_sleep': 'sleep'
        }
        
        daily_totals = {}
        for log in weekly_logs:
            log_date = log.date
            if log_date not in daily_totals:
                daily_totals[log_date] = {key: 0.0 for key in self.targets}
            
            for log_attr, target_key in log_to_target_map.items():
                if hasattr(log, log_attr):
                    value = getattr(log, log_attr) or 0
                    daily_totals[log_date][target_key] += value

        # Hitung hari yang memenuhi target dan total mingguan
        weekly_totals = {key: 0.0 for key in self.targets}
        days_count = len(daily_totals)
        
        for date_key, nutrients in daily_totals.items():
            for nutrient, value in nutrients.items():
                weekly_totals[nutrient] += value
                if value >= self.targets.get(nutrient, 0) * 0.8:  # 80% dari target dianggap cukup
                    self.metrics['days_completed'][nutrient] += 1
        
        # Hitung rata-rata mingguan
        for nutrient in self.targets:
            self.metrics['weekly_averages'][nutrient] = weekly_totals[nutrient] / days_count if days_count > 0 else 0
        
        self.logger.info(f"Log diproses untuk {days_count} hari. Hari yang memenuhi target: {self.metrics['days_completed']}")

    def _load_historical_data(self):
        """Memuat hasil asesmen dari 4 minggu terakhir untuk analisis tren."""
        four_weeks_ago = date.today() - timedelta(weeks=4)
        past_assessments = WeeklyAssessment.query.filter(
            WeeklyAssessment.user_id == self.user_id,
            WeeklyAssessment.week_start_date >= four_weeks_ago,
            WeeklyAssessment.status == 'completed'
        ).order_by(WeeklyAssessment.week_start_date.desc()).limit(3).all()
        
        self.historical_data = []
        for pa in past_assessments:
            try:
                if pa.results and isinstance(pa.results, dict):
                    self.historical_data.append(pa.results)
            except Exception as e:
                self.logger.error(f"Error memuat hasil asesmen historis: {e}")
        
        self.logger.info(f"Memuat {len(self.historical_data)} asesmen sebelumnya untuk user {self.user_id}")

    def _analyze_risks(self):
        """Menganalisis risiko berdasarkan gejala dan kekurangan nutrisi."""
        # Proses gejala dari kuis
        symptoms = self.quiz_answers.get('general_symptoms', [])
        self.logger.debug(f"Gejala yang dilaporkan: {symptoms}")
        for symptom in symptoms:
            self._score_and_create_alert_for_symptom(symptom)
        
        # Proses nutrisi yang kurang
        for nutrient, days in self.metrics.get('days_completed', {}).items():
            if days < 5:  # Kurang dari 5 hari memenuhi target
                self._score_and_create_alert_for_nutrient(nutrient, days)

    def _score_and_create_alert_for_nutrient(self, nutrient: str, days_completed: int):
        target = self.targets.get(nutrient)
        if target is None: 
            self.logger.warning(f"Target tidak ditemukan untuk nutrisi: {nutrient}")
            return
        
        average = self.metrics.get('weekly_averages', {}).get(nutrient, 0)
        score = (1 - (days_completed / 7)) * 40
        
        # Hitung kekambuhan dari data historis
        recurrence_count = 0
        for past_result in self.historical_data:
            for past_alert in past_result.get('alerts', []):
                if (past_alert.get('level') == 'WARNING' and 
                    nutrient.lower() in past_alert.get('title', '').lower()):
                    recurrence_count += 1
        
        if recurrence_count >= 2: 
            score *= 1.5
        elif recurrence_count == 1: 
            score *= 1.2
            
        # Faktor risiko tambahan
        if nutrient == 'iron' and 'anemia' in self.health_profile.get('pre_existing_conditions', []): 
            score *= 2.0
            
        if nutrient == 'calcium' and self.health_profile.get('age', 30) > 35: 
            score *= 1.1
        
        if score < 15: 
            return
        
        level = 'WARNING' if score > 35 else 'INFO'
        nutrient_title = nutrient.replace('_', ' ').capitalize()
        message = (f"Asupan {nutrient_title} Anda belum konsisten ({days_completed}/7 hari). "
                   f"Rata-rata asupan Anda ~{average:.1f} dari target harian {target:.1f}.")
        
        # Dapatkan rekomendasi dengan penanganan khusus untuk tipe tip
        recommendations = []
        if self.meal_planner:
            nutrient_key = nutrient.lower().replace(' ', '_')
            foods = self.meal_planner._get_filtered_foods(nutrient_key)
            for rec in foods:
                if rec.get('type') == 'info':
                    recommendations.append({"type": "info", "text": rec['text']})
                elif 'tip' in rec:
                    tip_text = rec['tip']
                    if 'description' in rec:
                        tip_text += ": " + rec['description']
                    recommendations.append({"type": "tip", "text": tip_text})
                elif 'food' in rec:
                    food_entry = {
                        "type": "food",
                        "food": rec['food'],
                        "serving_size": rec.get('serving_size', ''),
                        "value": rec.get('value', 0),
                        "unit": rec.get('unit', ''),
                        "tags": rec.get('tags', [])
                    }
                    recommendations.append(food_entry)
            
            # Tambahkan rekomendasi umum jika tidak ada rekomendasi
            if not recommendations:
                recommendations.append({
                    "type": "info", 
                    "text": f"Konsultasikan dengan ahli gizi untuk meningkatkan asupan {nutrient_title}"
                })
        else:
            self.logger.warning("Meal planner tidak tersedia untuk rekomendasi")
            recommendations.append({
                "type": "info", 
                "text": f"Konsultasikan dengan ahli gizi mengenai asupan {nutrient_title}"
            })
        
        self.alerts.append(Alert(
            risk_score=round(score, 1),
            level=level,
            title=f"Perhatian pada Asupan {nutrient_title}",
            message=message,
            category='nutrition',
            nutrient_key=nutrient,
            recommendations=recommendations
        ))

    def _score_and_create_alert_for_symptom(self, symptom: str):
        symptom_key = symptom.lower().strip()
        
        if symptom_key not in SYMPTOM_KNOWLEDGE_BASE: 
            self.logger.debug(f"Gejala tidak dikenal: {symptom_key}")
            return
        
        knowledge = SYMPTOM_KNOWLEDGE_BASE[symptom_key]
        score = 67.5 if symptom_key == 'kelelahan' else 30.0

        related_nutrient_deficiencies = []
        for nutrient in knowledge['related_nutrients']:
            days_completed = self.metrics.get('days_completed', {}).get(nutrient, 7)
            if days_completed < 5:
                score *= 1.25
                related_nutrient_deficiencies.append(nutrient)

        # Tentukan level risiko dari score
        if score >= 75:
            level = 'DANGER'
        elif score >= 50:
            level = 'WARNING'
        else:
            level = 'INFO'

        # Judul alert fokus pada gejala, bukan nutrisi
        symptom_title = symptom.capitalize()
        message = f"Gejala '{symptom}' terdeteksi."
        if related_nutrient_deficiencies:
            # Jika ada nutrisi terkait yang kurang, tambahkan pesan
            nutrient_list = ", ".join([n.replace('_', ' ').capitalize() for n in related_nutrient_deficiencies])
            message += f" Mungkin terkait dengan kekurangan asupan {nutrient_list}."
        
        # Rekomendasi: lifestyle tips
        lifestyle_tips = knowledge.get('lifestyle_tips', [])
        # Format rekomendasi menjadi list of dict untuk konsisten
        recommendations = [{"type": "tip", "text": tip} for tip in lifestyle_tips]
        
        # Simpan sebagai alert
        self.alerts.append(Alert(
            risk_score=round(score, 1),
            level=level,
            title=f"Gejala {symptom_title} Terdeteksi",
            message=message,
            category='symptom_management',
            nutrient_key=None,  # Tidak ada nutrisi kunci spesifik
            recommendations=recommendations,
            lifestyle_tips=lifestyle_tips  # Simpan juga dalam lifestyle_tips untuk kemudahan
        ))
        
    def _generate_weekly_goals(self) -> List[Goal]:
        if not self.alerts: 
            self.logger.info("Tidak ada peringatan, tidak ada tujuan yang dihasilkan")
            return []
        
        goals = []
        top_alerts = self.alerts[:2]  # Ambil maksimal 2 peringatan teratas
        
        for i, alert in enumerate(top_alerts):
            title = ""
            description = ""
            if alert.category == 'nutrition' and alert.nutrient_key:
                nutrient_name = alert.nutrient_key.replace('_', ' ').capitalize()
                title = f"Prioritas #{i+1}: Meningkatkan Asupan {nutrient_name}"
                description = f"Fokus mencoba 2-3 rekomendasi makanan kaya {nutrient_name} dan catat asupan Anda."
            elif alert.category == 'symptom_management':
                title = f"Prioritas #{i+1}: {alert.title}"
                description = "Pilih dan terapkan 2 tips gaya hidup yang disarankan."
            else:
                continue
                
            goals.append(Goal(
                priority=i + 1,
                title=title,
                description=description,
                related_alert_title=alert.title
            ))
                
        return goals

    def _compile_final_results(self, goals: List[Goal]) -> Dict:
        # Dapatkan nutrisi yang kurang dari semua peringatan nutrisi
        deficient_nutrients = [
            a.nutrient_key 
            for a in self.alerts 
            if a.category == 'nutrition' and a.nutrient_key
        ]
        
        # Hasilkan meal plan
        meal_plan = {}
        if self.meal_planner:
            try:
                meal_plan = self.meal_planner.generate_plan(deficient_nutrients)
            except Exception as e:
                self.logger.error(f"Error generating meal plan: {e}")
                meal_plan = self.meal_planner._get_general_plan()
        else:
            meal_plan = {
                "breakfast": "Roti gandum utuh dengan telur dan alpukat",
                "lunch": "Nasi merah dengan tumis sayuran dan tahu/tempe",
                "dinner": "Sup ayam dengan sayuran dan kacang-kacangan",
                "snacks": "Buah segar atau yoghurt",
                "note": "Rencana makan default (karena meal planner tidak tersedia)"
            }
        
        # Jika meal plan kosong, gunakan rencana umum
        if not meal_plan or any(not v for v in meal_plan.values()):
            meal_plan = self.meal_planner._get_general_plan() if self.meal_planner else {
                "breakfast": "Roti gandum utuh dengan telur dan alpukat",
                "lunch": "Nasi merah dengan tumis sayuran dan tahu/tempe",
                "dinner": "Sup ayam dengan sayuran dan kacang-kacangan",
                "snacks": "Buah segar atau yoghurt",
                "note": "Rencana makan umum (fallback)"
            }
        
        # Tentukan fokus utama
        main_focus = self.alerts[0].title if self.alerts else "Kesehatan Optimal"
        highest_risk = self.alerts[0].risk_score if self.alerts else 0.0
        
        # Hitung trimester
        weeks_pregnant = (date.today() - self.user.lmp_date).days // 7
        if weeks_pregnant <= 13: 
            trimester = 'trimester_1'
        elif 14 <= weeks_pregnant <= 27: 
            trimester = 'trimester_2'
        else: 
            trimester = 'trimester_3'
        
        # Siapkan hasil akhir
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
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
        )
        logger = logging.getLogger(__name__)

        assessment = WeeklyAssessment.query.get(assessment_id)
        if not assessment:
            logger.error(f"Tugas asesmen gagal: Asesmen ID {assessment_id} tidak ditemukan.")
            return
            
        logger.info(f"Tugas background dimulai untuk asesmen ID {assessment_id} (user {assessment.user_id}).")
        
        try:
            service = WeeklyAssessmentService(assessment.user_id, assessment.quiz_answers or {})
            results = service.run()
            assessment.results = results
            assessment.status = 'completed'
            assessment.completed_at = datetime.utcnow()
            logger.info(f"Asesmen ID {assessment_id} untuk user {assessment.user_id} berhasil diselesaikan.")
        except (UserNotFoundError, InsufficientDataError) as e:
            logger.error(f"Tugas asesmen untuk ID {assessment_id} gagal karena kesalahan data: {e}")
            assessment.status = 'failed'
            assessment.results = {'error': str(e)}
        except Exception as e:
            logger.exception(f"Kesalahan tidak terduga terjadi dalam tugas asesmen untuk ID {assessment_id}: {e}")
            assessment.status = 'failed'
            assessment.results = {'error': 'Terjadi kesalahan internal yang tidak terduga saat memproses asesmen.'}
        
        db.session.commit()