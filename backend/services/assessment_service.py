from datetime import date, timedelta
from models import db
from models.user import User
from models.daily_nutrition_log import DailyNutritionLog
# --- 1. TAMBAHKAN IMPORT INI ---
from services.nutrition_service import calculate_nutrition_goals

# --- Bagian 1: Definisi Target STATIS (Hanya untuk Mikronutrien) ---

MICRO_TARGETS = {
    'folic_acid': 600,  # mcg
    'iron': 27,       # mg
    'calcium': 1300,    # mg
    'zinc': 11        # mg
}

FOOD_RECOMMENDATIONS = {
    'folic_acid': 'Sayuran hijau (bayam, brokoli), alpukat, dan sereal yang diperkaya.',
    'iron': 'Daging merah tanpa lemak, unggas, ikan, dan kacang-kacangan.',
    'calcium': 'Produk susu (yoghurt, keju), tahu, dan sayuran seperti kale.',
    'zinc': 'Daging sapi, biji labu, buncis, dan gandum utuh.',
    'protein': 'Telur, dada ayam, ikan salmon, dan tempe.'
}

ALERT_THRESHOLD_DAYS = 5

def perform_weekly_assessment(user_id, quiz_answers):
    """
    Menjalankan asesmen mingguan untuk seorang pengguna.
    """
    user = User.query.get(user_id)
    if not user or not user.lmp_date:
        raise ValueError("Pengguna tidak ditemukan atau belum mengatur HPL.")

    dynamic_targets = calculate_nutrition_goals(
        age=user.age,
        weight=user.weight,
        height=user.height,
        lmp_date=user.lmp_date
    )

    targets = {**dynamic_targets, **MICRO_TARGETS}
    
    today = date.today()
    seven_days_ago = today - timedelta(days=7)
    weekly_logs = DailyNutritionLog.query.filter(
        DailyNutritionLog.user_id == user_id,
        DailyNutritionLog.date >= seven_days_ago
    ).all()

    days_completed = {
        'calories': 0, 'protein': 0, 'fat': 0, 'carbs': 0,
        'folic_acid': 0, 'iron': 0, 'calcium': 0, 'zinc': 0
    }

    log_to_target_map = {
        'daily_calories': 'calories',
        'daily_protein': 'protein',
        'daily_fat': 'fat',
        'daily_carbs': 'carbs',
        'daily_folac_acid': 'folic_acid',
        'daily_iron': 'iron',
        'daily_calcium': 'calcium',
        'daily_zinc': 'zinc'
    }

    logs_by_date = {}
    for log in weekly_logs:
        if log.date not in logs_by_date:
            logs_by_date[log.date] = {}
        # Jumlahkan nilai untuk hari yang sama
        for log_attr, target_key in log_to_target_map.items():
            current_value = logs_by_date[log.date].get(target_key, 0)
            logs_by_date[log.date][target_key] = current_value + getattr(log, log_attr, 0)

    # Sekarang bandingkan total harian dengan target
    for day_total in logs_by_date.values():
        for nutrient, total_value in day_total.items():
            if total_value >= targets.get(nutrient, float('inf')):
                days_completed[nutrient] += 1

    # 4. Buat hasil akhir dan rekomendasi
    final_results = {}
    for nutrient, days in days_completed.items():
        recommendation = None
        if days < ALERT_THRESHOLD_DAYS:
            recommendation = FOOD_RECOMMENDATIONS.get(nutrient)
        
        final_results[nutrient] = {
            "days_completed": days,
            "target_daily": targets.get(nutrient),
            "recommendation": recommendation
        }

    # Tambahkan rekomendasi personal berdasarkan jawaban kuis
    energy_level = quiz_answers.get('energy_level')
    if energy_level and energy_level <= 2 and final_results['iron']['days_completed'] < ALERT_THRESHOLD_DAYS:
        final_results['iron']['recommendation'] += " Asupan zat besi yang cukup sangat penting untuk mengatasi kelelahan."

     # Logika untuk Kalori & Energi
    if energy_level and energy_level <= 2 and final_results['calories']['days_completed'] < ALERT_THRESHOLD_DAYS:
        final_results['calories']['recommendation'] += " Kalori adalah sumber energi utama, pastikan asupannya cukup."

    # Logika untuk Zinc & Suasana Hati (Mood)
    if mood == 'sedih' and final_results['zinc']['days_completed'] < ALERT_THRESHOLD_DAYS:
        final_results['zinc']['recommendation'] += " Zinc berperan penting dalam menjaga kestabilan suasana hati."

    # Logika untuk Kalsium & Gejala Sulit Tidur atau Sakit Punggung
    if ('sulit tidur' in symptoms or 'sakit punggung' in symptoms) and final_results['calcium']['days_completed'] < ALERT_THRESHOLD_DAYS:
        final_results['calcium']['recommendation'] += " Kalsium membantu relaksasi otot dan dapat meningkatkan kualitas tidur."

    # Logika untuk Asam Folat (selalu penting)
    if final_results['folic_acid']['days_completed'] < ALERT_THRESHOLD_DAYS:
        final_results['folic_acid']['recommendation'] += " Ini adalah nutrisi krusial untuk perkembangan sistem saraf bayi Anda."
    
    return final_results