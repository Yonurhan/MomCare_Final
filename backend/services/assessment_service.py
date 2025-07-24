from datetime import date, timedelta
from models import db
from models.user import User
from models.daily_nutrition_log import DailyNutritionLog
from services.nutrition_service import calculate_nutrition_goals

MICRO_TARGETS = {
    'folic_acid': 600, 'iron': 27, 'calcium': 1300, 'zinc': 11,
    'water': 2000, 'sleep': 8.0
}

FOOD_RECOMMENDATIONS = {
    'folic_acid': 'Sayuran hijau (bayam, brokoli), alpukat, dan sereal yang diperkaya.',
    'iron': 'Daging merah tanpa lemak, unggas, ikan, dan kacang-kacangan.',
    'calcium': 'Produk susu (yoghurt, keju), tahu, dan sayuran seperti kale.',
    'zinc': 'Daging sapi, biji labu, buncis, dan gandum utuh.',
    'protein': 'Telur, dada ayam, ikan salmon, dan tempe.',
    'calories': 'Alpukat, kacang-kacangan, dan ubi jalar untuk sumber kalori sehat.',
    'carbs': 'Nasi merah, oatmeal, dan buah-buahan sebagai sumber karbohidrat kompleks.',
    'fat': 'Ikan salmon, alpukat, dan minyak zaitun untuk lemak sehat.',
    'water': 'Pastikan untuk minum setidaknya 8 gelas air setiap hari agar tetap terhidrasi.',
    'sleep': 'Tidur yang cukup sangat penting untuk pemulihan energi dan pertumbuhan janin.'
}

ALERT_THRESHOLD_DAYS = 5

def perform_weekly_assessment(user_id, quiz_answers):
    user = User.query.get(user_id)
    if not user or not user.lmp_date:
        raise ValueError("Pengguna tidak ditemukan atau belum mengatur HPHT.")

    dynamic_targets = calculate_nutrition_goals(
        age=user.age, weight=user.weight, height=user.height, lmp_date=user.lmp_date
    )
    targets = {**dynamic_targets, **MICRO_TARGETS}
    
    today = date.today()
    seven_days_ago = today - timedelta(days=7)
    weekly_logs = DailyNutritionLog.query.filter(
        DailyNutritionLog.user_id == user_id,
        DailyNutritionLog.date >= seven_days_ago
    ).all()

    days_completed = { key: 0 for key in targets.keys() }
    log_to_target_map = {
        'daily_calories': 'calories', 'daily_protein': 'protein', 'daily_fat': 'fat',
        'daily_carbs': 'carbs', 'daily_folac_acid': 'folic_acid', 'daily_iron': 'iron',
        'daily_calcium': 'calcium', 'daily_zinc': 'zinc',
        'daily_water': 'water', 'daily_sleep': 'sleep'
    }
    
    logs_by_date = {}
    for log in weekly_logs:
        if log.date not in logs_by_date:
            logs_by_date[log.date] = { key: 0 for key in targets.keys() }
        for log_attr, target_key in log_to_target_map.items():
            logs_by_date[log.date][target_key] += getattr(log, log_attr, 0)

    for day_totals in logs_by_date.values():
        for nutrient, total_value in day_totals.items():
            if nutrient in targets and total_value >= targets[nutrient]:
                days_completed[nutrient] += 1

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
    
    energy_level = quiz_answers.get('energy_level')
    mood = quiz_answers.get('mood') 
    general_symptoms = quiz_answers.get('general_symptoms', [])
    healthy_habits = quiz_answers.get('healthy_habits', [])

    if energy_level and energy_level <= 2 and final_results['iron']['days_completed'] < ALERT_THRESHOLD_DAYS:
        final_results['iron']['recommendation'] += " Asupan zat besi yang cukup sangat penting untuk mengatasi kelelahan."

    if mood in ['sedih', 'cemas'] and final_results['zinc']['days_completed'] < ALERT_THRESHOLD_DAYS:
        final_results['zinc']['recommendation'] += " Zinc juga berperan penting dalam menjaga kestabilan suasana hati lho."

    if ('sulit tidur' in general_symptoms or 'sakit punggung' in general_symptoms) and final_results['sleep']['days_completed'] < ALERT_THRESHOLD_DAYS:
        final_results['sleep']['recommendation'] += " Kualitas tidur yang baik dapat membantu mengurangi nyeri punggung dan gejala lainnya."
    
    if 'vitamin prenatal' not in healthy_habits:
        if 'general_recommendation' not in final_results:
            final_results['general_recommendation'] = []
        final_results['general_recommendation'].append("Jangan lupa untuk rutin mengonsumsi vitamin prenatal sesuai anjuran dokter ya.")
    
    if 'aktivitas fisik' not in healthy_habits:
        if 'general_recommendation' not in final_results:
            final_results['general_recommendation'] = []
        final_results['general_recommendation'].append("Aktivitas fisik ringan seperti berjalan kaki dapat membantu menjaga kebugaran selama kehamilan.")

    return final_results