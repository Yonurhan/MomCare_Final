Untuk menjalankan aplikasi prototype MomCare, lakukan langkah-langkah berikut

1. Clone Repository
git clone https://github.com/yonurhan/MomCare_Final.git
cd MomCare/backend

2. Install Python Dependencies
pip install -r requirements.txt && python nltk_setup.py

3. Setup dan Jalankan MySQL Database
flask db upgrade
   
3. Masuk ke Direktori Frontend
cd MomCare/frontend

4. Konfigurasi IP Address di .env
Pada bagian .env, ganti IP dengan IP device anda. Untuk melihat ip anda, buka command prompt dan ketik ipconfig. Setelah itu acopy bagian IPv4 Address dan masukan pada BaseURL di .env

6. Jalankan dependency flutter
flutter pub get
flutter run
