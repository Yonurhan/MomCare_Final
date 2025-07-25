# test_service.py (Versi Final yang Benar)

import json
import os
from app import app
# --- PERBAIKAN UTAMA: Impor modulnya, bukan variabelnya ---
import services.assessment_service as assessment_service

def check_knowledge_bases():
    """
    Fungsi untuk menjalankan _lazy_load_knowledge_bases dan memeriksa
    variabel asli di dalam modulnya.
    """
    print("--- Memulai Pengecekan Basis Pengetahuan ---")
    
    with app.app_context():
        try:
            # Panggil fungsi lazy loader
            assessment_service._lazy_load_knowledge_bases()

            # --- PERBAIKAN UTAMA: Periksa variabel melalui modulnya ---
            if assessment_service.ACTIONABLE_RECOMMENDATIONS:
                print("\n✅ BERHASIL: 'recommendations.json' berhasil dimuat.")
                print("   Contoh data 'iron':", json.dumps(assessment_service.ACTIONABLE_RECOMMENDATIONS.get('iron', 'Tidak ditemukan'), indent=2, ensure_ascii=False))
            else:
                print("\n❌ GAGAL: 'recommendations.json' kosong atau tidak ditemukan.")

            if assessment_service.SYMPTOM_KNOWLEDGE_BASE:
                print("\n✅ BERHASIL: 'symptoms.json' berhasil dimuat.")
                print("   Contoh data 'kelelahan':", json.dumps(assessment_service.SYMPTOM_KNOWLEDGE_BASE.get('kelelahan', 'Tidak ditemukan'), indent=2, ensure_ascii=False))
            else:
                print("\n❌ GAGAL: 'symptoms.json' kosong atau tidak ditemukan.")

        except Exception as e:
            print(f"\n❌ Terjadi error saat menjalankan tes: {e}")

    print("\n--- Pengecekan Selesai ---")

if __name__ == '__main__':
    check_knowledge_bases()