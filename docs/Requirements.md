# Gereksinim Analizi ve THS Hedefi Raporu

**Proje Adı:** NakilBakimAR
**Tarih:** 10 Haziran 2026

Bu doküman, NakilBakimAR projesinin geliştirilmesi sırasında hedeflenen yazılımsal gereksinimleri (fonksiyonel ve fonksiyonel olmayan) ve Teknoloji Hazırlık Seviyesi (THS) planlamasını içerir.

---

## 1. Fonksiyonel Gereksinimler (Functional Requirements)

Sistemin "ne" yapması gerektiğini tanımlayan temel özelliklerdir.

### Kimlik Doğrulama ve Rol Yönetimi
- **FR1:** Sistem, "Hemşire" ve "Hasta" olmak üzere iki temel rol barındırmalıdır.
- **FR2:** Hemşireler e-posta ve şifre ile JWT tabanlı güvenli giriş yapabilmelidir.
- **FR3:** Hastalar, kolaylık sağlaması adına TC Kimlik No ve 4 haneli PIN ile hızlı giriş yapabilmelidir.

### Hemşire Modülü
- **FR4:** Hemşireler yeni hasta kaydı oluşturabilmeli, mevcut hastaları listeleyebilmelidir.
- **FR5:** Hemşire, hastanın ameliyat (operasyon) tarihini sisteme girebilmeli, sistem hastanın `pre_op` veya `post_op` durumunu buna göre otomatik belirlemelidir.
- **FR6:** Hemşire, hasta bazlı "Modül Yönetimi" yapabilmelidir (Solunum, Mobilizasyon, İlaç, Vital gibi modülleri açıp kapatabilme).
- **FR7:** Hemşire, hastaların günlük görev tamamlama durumlarını ve girdikleri vital verileri görüntüleyebilmelidir.

### Hasta Modülü
- **FR8:** Hasta, kendisine atanan aktif modülleri ve görevleri ana sayfasında (Dashboard) görebilmelidir.
- **FR9:** Hasta, vital verilerini (tansiyon, nabız vb.) tarih ve saat seçerek sisteme kaydedebilmelidir.
- **FR10:** Hasta, AR (Artırılmış Gerçeklik) modülünü açıp cihaz kamerasını kullanabilmelidir.

### AR (Artırılmış Gerçeklik) Modülü
- **FR11:** Sistem, ARKit altyapısı ile belirlenen referans görselleri (image tracking) tanıyabilmelidir.
- **FR12:** Marker tanındığında, API'den ilgili senaryo çekilmeli ve ilgili 3D model ekrana (marker'ın üzerine) yerleştirilerek animasyonu oynatılmalıdır.
- **FR13:** Hastanın AR ekranındaki kararları (doğru/yanlış hareket seçimi) sistem veritabanına loglanmalıdır.

---

## 2. Fonksiyonel Olmayan Gereksinimler (Non-Functional Requirements)

Sistemin "nasıl" çalışması gerektiğini tanımlayan kalite ve altyapı özellikleridir.

- **NFR1 (Performans):** AR model yükleme süreleri kısa olmalı (ortalama < 2 saniye), cihazın kamerasını dondurmamalıdır. API yanıt süreleri mobil deneyimi aksatmamalıdır (< 200ms).
- **NFR2 (Güvenlik):** Şifreler veritabanında (PostgreSQL) hashlenerek (ör: bcrypt) saklanmalı, tüm veri transferi HTTPS üzerinden yapılmalı, hasta bilgilerine sadece ilgili hemşire erişebilmelidir.
- **NFR3 (Kullanılabilirlik - UX/UI):** Hasta hedef kitlesi ileri yaşlı ve ameliyat yorgunu olabileceği için, hasta arayüzü büyük butonlar, okunabilir fontlar ve karmaşadan uzak (minimum tıklama) bir tasarıma sahip olmalıdır.
- **NFR4 (Uyumluluk):** iOS tarafı ARKit gereksinimi nedeniyle minimum iOS 16 sürümünü destekleyen Apple cihazlarında (iPhone 8 ve üzeri) sorunsuz çalışmalıdır.
- **NFR5 (Hata Toleransı):** İnternet bağlantısı koptuğunda sistem çökmemeli, uygun hata uyarıları göstermeli ve fail-safe prensibiyle çalışmalıdır (RAMS İlkeleri).

---

## 3. Hedef THS Seviyesi Planlaması

TÜBİTAK TEYDEB standartları temel alınarak proje için hedeflenen Teknoloji Hazırlık Seviyesi (THS) aşağıda belirtilmiştir:

* **Başlangıç Durumu (Hafta 1-3):** THS 2-3 (Konsept ve Gereksinimlerin Belirlenmesi)
* **Ara Sınav Hedefi (Hafta 7):** THS 4 (Laboratuvar Ortamında Doğrulanmış Temel Teknoloji - MVP)
* **Şu Anki Durum:** **THS 5** (İlgili Ortam Doğrulama - Gerçekçi Verilerle Simülasyon)
* **Final Hedefi (Hafta 14):** **THS 6 veya THS 7**
  - **THS 6 (İlgili Ortam Demo):** Sistem prototipinin tam donanımlı olarak iOS cihazlarda ve gerçek sunucularla gösterilmesi.
  - **THS 7 (Operasyonel Demo):** Uygulamanın gerçek bir hastane ağı koşullarında (TestFlight ile dağıtılarak) uçtan uca çalıştırılıp demo edilmesi.
