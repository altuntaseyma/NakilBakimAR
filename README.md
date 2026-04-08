
# NakilBakimAR

> Karaciğer Nakli Öncesi ve Sonrası Hasta Bakımını Destekleyen Artırılmış Gerçeklik Mobil Uygulaması

![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![iOS](https://img.shields.io/badge/iOS-16.0+-blue)
![ARKit](https://img.shields.io/badge/ARKit-✓-green)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-blue)
![Firebase](https://img.shields.io/badge/Firebase-Cloud%20Messaging-yellow)

---

## 📱 Proje Hakkında

**NakilBakimAR**, İnönü Üniversitesi Turgut Özal Tıp Merkezi Karaciğer Nakli Enstitüsü iş birliğiyle geliştirilen, karaciğer nakli **öncesi (pre-op)** ve **sonrası (post-op)** dönemdeki hastaların bakım süreçlerini artırılmış gerçeklik (AR) ile destekleyen bir mobil uygulamadır.

### 🎯 Amaç
- Hastaların mobilizasyon, ilaç takibi, beslenme, sıvı alımı ve yara bakımını kolaylaştırmak.
- Hemşirelerin hastalara **kişiye özel bakım modülleri** atamasını sağlamak.
- **Pre-op** dönemde hastaları bilgilendirerek ameliyata hazırlık sürecini iyileştirmek.
- **Post-op** dönemde iyileşme sürecini takip etmek ve komplikasyonları azaltmak.
- Artırılmış gerçeklik ile etkileşimli, akılda kalıcı rehberlik sunmak.

---

## ✨ Özellikler

### 👥 Roller ve Giriş
- **Hemşire** ve **Hasta** olmak üzere iki rol.
- Güvenli giriş (e-posta + şifre) – backend PostgreSQL ile doğrulama.
- Hemşire, hastalar için **pre-op** veya **post-op** modüllerini aktif/pasif yapabilir → kişiselleştirilmiş deneyim.

### 🩺 Hemşire Paneli
- Hasta listesi ve detaylı profili.
- **Vital bulguları** (ateş, tansiyon, nabız, oksijen satürasyonu) saatli/dakikalı olarak kaydetme.
- Kaydedilen bulguları **hasta ile paylaş** / **paylaşma** seçeneği (toggle buton).
- Hastaya özel **modül yönetimi**: Mobilizasyon, Beslenme, Yara Bakımı, İlaç, Egzersiz modüllerini aç/kapat.
- Hastanın tamamladığı görevleri ve vital geçmişini görüntüleme.

### 📱 Hasta Paneli
- Kendisine açılmış modülleri görür (örneğin sadece “Mobilizasyon” ve “Beslenme” aktifse, diğerleri gizli).
- **AR destekli görevler:**
  - *Mobilizasyon/Egzersiz:* Elindeki **broşürü kameraya tuttuğunda** broşür üzerinde 3D animasyon canlanır (örneğin doğru yürüme pozisyonu gösteren bir karakter).
  - *İlaç:* İlaç kutusu üzerinde doz bilgisi görselleştirilir.
- **Beslenme ve su içme bildirimleri:** Firebase Cloud Messaging ve e-posta ile hatırlatmalar.
- Tüm atamaları listeleyip “Tamamlandı” işaretleyebilir.
- Kendi vital bulgularını (hemşire paylaşım izni verdiyse) görüntüleyebilir.

### 🧠 Veritabanı ve Backend
- **PostgreSQL** – hasta bilgileri, atamalar, vital bulgular, modül açıklıkları.
- **REST API** (Node.js / Python – tercihe göre) ile mobil uygulama ile iletişim.
- **JWT** tabanlı kimlik doğrulama.

### 📢 Bildirimler
- **Firebase Cloud Messaging (FCM)** – anlık hatırlatmalar (ilaç vakti, egzersiz zamanı, su içme).
- **E-posta entegrasyonu** – günlük özet veya kritik hatırlatmalar (SendGrid / SMTP).

### 🎨 Tasarım
- Modern, yumuşak geçişler, karaciğer temalı grafikler ve animasyonlar (örn. hepatosit hücresi animasyonu, damar ağları).
- Koyu / açık tema desteği.
- SwiftUI ile akıcı animasyonlar ve geçişler.

### 🔮 AR Teknolojisi (ARKit + RealityKit)
- **Broşür tanıma** – önceden tanımlanmış bir görseli (broşür üzerindeki marker) kameraya tutunca, o görselin üzerine 3D animasyon yerleştirilir.
- **İki ana AR deneyimi:**
  1. Egzersiz/Mobilizasyon: Animasyonlu insan modeli (yürüme, nefes egzersizi).
  2. İlaç: İlaç kutusu modeli + metin overlay.

---

## 🛠 Teknoloji Yığını

| Katman | Teknoloji |
|--------|------------|
| Mobil Uygulama | Swift, SwiftUI, ARKit, RealityKit |
| Backend API | Node.js (Express) veya Python (FastAPI) |
| Veritabanı | PostgreSQL 16 |
| Kimlik Doğrulama | JWT, bcrypt |
| Bildirimler | Firebase Cloud Messaging, Nodemailer/SendGrid |
| Sürüm Kontrolü | Git, GitHub |
| Proje Yönetimi | Trello |
| Test | XCTest (birim test), Postman (API testi) |

---

## 🚀 Kurulum ve Çalıştırma

### Gereksinimler
- macOS Ventura veya üzeri
- Xcode 15+
- iOS 16.0+ destekleyen bir cihaz (AR için gerçek cihaz önerilir)
- Node.js 18+ (backend için) veya Python 3.10+
- PostgreSQL 16

### 1. Backend Kurulumu (Örnek Node.js)

```bash
git clone https://github.com/username/NakilBakimAR-backend.git
cd NakilBakimAR-backend
npm install
# .env dosyası oluştur (DB_URL, JWT_SECRET, FIREBASE_CRED, EMAIL_USER, EMAIL_PASS)
npm run migrate
npm start
```

### 2. Mobil Uygulama

```bash
git clone https://github.com/username/NakilBakimAR.git
cd NakilBakimAR
open NakilBakimAR.xcodeproj
```
- Xcode’da hedef cihazı seçin (ARKit destekli gerçek cihaz).
- `Info.plist`’e kamera izni ekleyin.
- Backend API base URL’sini `Constants.swift` içinde güncelleyin.
- Çalıştırmak için `Cmd+R`.

### 3. PostgreSQL Şeması (Özet)

```sql
CREATE TABLE users (
  id UUID PRIMARY KEY,
  email VARCHAR UNIQUE NOT NULL,
  password_hash VARCHAR NOT NULL,
  role VARCHAR(10) CHECK (role IN ('nurse', 'patient')),
  name VARCHAR,
  created_at TIMESTAMP
);

CREATE TABLE patients (
  id UUID PRIMARY KEY REFERENCES users(id),
  nurse_id UUID REFERENCES users(id),
  phase VARCHAR(10) CHECK (phase IN ('preop', 'postop'))
);

CREATE TABLE modules (
  id SERIAL PRIMARY KEY,
  name VARCHAR(50) -- mobilization, nutrition, wound, medication, exercise
);

CREATE TABLE patient_modules (
  patient_id UUID REFERENCES patients(id),
  module_id INT REFERENCES modules(id),
  is_active BOOLEAN DEFAULT false,
  PRIMARY KEY (patient_id, module_id)
);

CREATE TABLE vitals (
  id SERIAL PRIMARY KEY,
  patient_id UUID REFERENCES patients(id),
  nurse_id UUID REFERENCES users(id),
  recorded_at TIMESTAMP DEFAULT NOW(),
  temperature DECIMAL(4,1),
  blood_pressure_systolic INT,
  blood_pressure_diastolic INT,
  heart_rate INT,
  oxygen_saturation INT,
  shared_with_patient BOOLEAN DEFAULT false
);

CREATE TABLE assignments (
  id SERIAL PRIMARY KEY,
  patient_id UUID REFERENCES patients(id),
  nurse_id UUID REFERENCES users(id),
  type VARCHAR(20) CHECK (type IN ('medication', 'exercise')),
  description TEXT,
  due_date TIMESTAMP,
  is_completed BOOLEAN DEFAULT false,
  completed_at TIMESTAMP
);
```

---

## 📄 API Uç Noktaları (Özet)

| Metot | Endpoint | Açıklama |
|-------|----------|-----------|
| POST | `/auth/login` | Giriş (email, şifre) → JWT token |
| GET | `/patients` | Hemşireye ait hastaları listele |
| POST | `/patients/:id/modules` | Hastanın modülünü aç/kapa |
| POST | `/vitals` | Vital bulguları kaydet |
| PUT | `/vitals/:id/share` | Paylaşım durumunu güncelle |
| GET | `/assignments/patient` | Hastanın atamalarını getir |
| POST | `/assignments` | Yeni atama oluştur |
| PUT | `/assignments/:id/complete` | Atamayı tamamla |

---


## 📞 İletişim

- **Geliştirici:** Şeyma Nur Altuntaş
- **Danışman:** Prof.Dr.Fatih Özkaynak
                Arş. Gör.Beyzanur Durmuş
- **Kurum:**- Fırat Üniversitesi, Teknoloji Fakültesi, Yazılım Mühendisliği Bölümü
- **Trello Panosu:** https://trello.com/invite/b/69c2df5dc85ecad05426a1d7/ATTI9e2c69797cd488f8f1c8190ac6efc44cD4DFD2F8/yazilim-muhendisliginde-guncel-konular-proje


---

## 🙏 Teşekkürler

- İnönü Üniversitesi Turgut Özal Tıp Merkezi Karaciğer Nakli Enstitüsü’ne destekleri için.
- Tüm açık kaynak kütüphanelerin geliştiricilerine.

---

**© 2026 NakilBakimAR Ekibi**

---
