from datetime import date, timedelta

def calculate_nutrition_goals(age, weight, height, due_date):
    """
    Calculates daily nutrition goals based on user's stats and due date.
    """
    today = date.today()
    
    if not isinstance(due_date, date):
        raise TypeError("due_date must be a valid date object.")

    pregnancy_duration_days = 280
    days_remaining = (due_date - today).days

    current_pregnancy_day = pregnancy_duration_days - days_remaining
    current_week = (current_pregnancy_day / 7)

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