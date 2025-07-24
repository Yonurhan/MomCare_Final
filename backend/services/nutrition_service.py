# services/nutrition_service.py

from datetime import date, timedelta

def calculate_due_date(lmp_date):
    """Menghitung perkiraan tanggal lahir (HPL) dari HPHT."""
    return lmp_date + timedelta(days=280)

def calculate_nutrition_goals(age, weight, height, lmp_date):
    """
    Menghitung target nutrisi harian berdasarkan statistik pengguna dan HPHT.
    """
    today = date.today()
    
    if not isinstance(lmp_date, date):
        raise TypeError("lmp_date harus berupa objek date yang valid.")

    days_since_lmp = (today - lmp_date).days
    
    current_week = (days_since_lmp / 7)

    if 1 <= current_week <= 13:
        trimester = 1
    elif 14 <= current_week <= 27:
        trimester = 2
    elif current_week >= 28:
        trimester = 3
    else:
        trimester = 1

    eer = 354 - 6.91 * age + 1 * (9.36 * weight + 726 * (float(height) / 100))

    if trimester == 1:
        extra_calories = 0
    elif trimester == 2:
        extra_calories = 340
    else:
        extra_calories = 452
    
    total_calories = eer + extra_calories

    protein_grams = weight * 1.1
    protein_calories = protein_grams * 4

    fat_calories = 0.30 * total_calories
    fat_grams = fat_calories / 9

    remaining_calories = total_calories - (protein_calories + fat_calories)
    carbs_grams = remaining_calories / 4

    return {
        "calories": total_calories,
        "protein": protein_grams,
        "fat": fat_grams,
        "carbs": carbs_grams
    }