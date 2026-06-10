# Kullanıcı Senaryosu (User Scenario) ve Problem Tanımı

**Proje Adı:** NakilBakimAR
**Hazırlayan:** [İsminizi Buraya Yazabilirsiniz]

## 1. Problem Tanımı

Karaciğer nakli (transplantasyon) ameliyatı geçiren hastaların, ameliyat öncesi (pre-op) hazırlık ve ameliyat sonrası (post-op) iyileşme süreçleri oldukça kritiktir. Bu süreçte hastaların düzenli nefes/hareket egzersizleri yapması, vitallerini ölçmesi ve ilaçlarını vaktinde kullanması gerekmektedir. Ancak pratikte;
- Hastalar kendilerine verilen basılı broşürlerdeki egzersizleri anlamakta zorluk çekmektedir.
- Hemşirelerin ve doktorların, hastanın evdeki uyumunu ve vital durumunu anlık takip etmesi zordur.
- Hastaların operasyon tarihine göre değişkenlik gösteren "görev" döngülerini unutması, iyileşme sürecini geciktirebilmekte veya komplikasyon riskini artırmaktadır.

NakilBakimAR projesi, Artırılmış Gerçeklik (AR) teknolojisini kullanarak hastanın egzersiz broşürlerini 3 boyutlu canlandırmayı, görevlerini günlük olarak takip etmesini sağlamayı ve hemşireler için anlık bir uzaktan takip ekranı sunmayı hedefleyerek bu sorunu çözer.

---

## 2. Kullanıcı Profilleri (Aktörler)

1. **Hemşire (Klinik Yöneticisi):** Hastaları sisteme ekler, durumlarını pre-op / post-op olarak belirler ve onlara uygun görev/modülleri aktif veya pasif hale getirir.
2. **Hasta:** Kendi ekranından kendisine o gün atanan görevleri (vital ölçüm, AR egzersiz vb.) görür ve tamamlar.

---

## 3. Temel Kullanıcı Senaryoları (User Scenarios)

### Senaryo 1: Hemşirenin Hasta Kabulü ve Modül Ataması
- Hemşire sisteme e-posta ve şifresi ile giriş yapar.
- Hemşire, "Hasta Listesi" ekranına girer ve yeni bir hasta oluşturur (TC Kimlik No, Ad, Soyad).
- Hemşire, hastanın ameliyat tarihini girerek hastayı **Pre-op** veya **Post-op** durumuna alır.
- Hastanın durumuna göre sistem, "Mobilizasyon", "Solunum", "İlaç", "Vital" gibi modülleri otomatik açar. Hemşire dilerse bu modülleri manuel olarak açıp kapatabilir.

### Senaryo 2: Hastanın Günlük Kontrolü
- Hasta, uygulamayı açarak TC Kimlik No ve PIN kodu ile hızlı giriş yapar.
- Ana ekranda (Dashboard), o anki fazına (Pre-op/Post-op) uygun olan aktif görevlerini görür.
- Hasta, "Vital Gir" butonuna tıklar, tansiyon ve nabız değerlerini yazarak kaydeder.
- Bu işlem anında buluta senkronize olur ve hemşire paneline düşer.

### Senaryo 3: AR Destekli Egzersiz Deneyimi
- Hasta ana ekrandan "AR Egzersiz" (Mobilizasyon) modülüne girer.
- Kamera açılır. Hasta, hastane tarafından kendisine verilen "Egzersiz Broşürü"ne telefonun kamerasını tutar.
- iOS cihazındaki **ARKit**, broşürü tanır (Image Tracking) ve broşürün hemen üzerinde 3 Boyutlu bir karakter belirir.
- Karakter, hastanın yapması gereken nefes veya yürüme egzersizini 3 boyutlu animasyon olarak uygulamalı olarak gösterir.
- Hasta egzersizi tamamladığında "Bitir" diyerek görevini tamamlar, arka planda log kaydı oluşturulur.

### Senaryo 4: Hemşirenin Veri Analizi
- Hemşire, hasta detay sayfasına girdiğinde "Uyum Analizi" grafiğini görür.
- Hastanın o gün hangi görevleri tamamladığı, hangi AR modüllerini ne zaman açtığı ve girdiği vital ölçümler listelenir.
- Hemşire olağan dışı bir tansiyon/nabız gördüğünde doğrudan hastayı arayarak müdahale eder.
