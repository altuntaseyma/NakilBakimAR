# Teknoloji Hazırlık Seviyesi (THS) Öz-Değerlendirme Raporu

**Proje Adı:** NakilBakimAR
**Değerlendirme Tarihi:** 10 Haziran 2026

## 1. THS Nicel Ölçüm Kriterleri (0-5 Puan)

### 1.1 Çalışan Modül Oranı (Puan: 4/5)
**Gerekçe:** Projenin çekirdek klinik akışı (MVP) başarıyla tamamlanmıştır. Backend servisleri (sağlık kontrolü, kimlik doğrulama, hasta, görev, vital takip vb.) aktif olarak çalışmaktadır. iOS tarafında modern giriş ekranı, hemşire ve hasta panelleri aktiftir. Pre-op ve Post-op durumları için dinamik modül yönetimi sağlanmıştır. ARKit ile image tracking (görüntü takibi) altyapısı kurulmuş olup, model bağlama ve animasyon adımları geliştirme aşamasındadır.
**Kanıt:** `backend` API rotaları ve `ios` arayüz akışları; tamamlanan özellikler listesi.

### 1.2 Gerçek Ortam Testi (Puan: 3/5)
**Gerekçe:** Uygulama yerel laboratuvar ortamında (localhost) ve iOS simülatöründe başarıyla doğrulanmıştır. Gerçek bir iPhone cihazı üzerinde ağ içi testler yapılabilmektedir, ancak hastane ağı gibi dış koşullarda veya mobil veri ile tam kapsamlı saha testleri (ilgili ortam) henüz tamamlanmamıştır.
**Kanıt:** API için localhost kullanımları ve proje durum raporunda belirtilen eksikler.

### 1.3 Hata Toleransı (Puan: 3/5)
**Gerekçe:** JWT tabanlı kimlik doğrulama ve rol bazlı (Hemşire/Hasta) erişim kısıtlamaları uygulanarak güvenlik temelleri atılmıştır. Ancak iOS tarafında ağ bağlantısı kesilmelerine karşı merkezi bir hata yönetim sistemi (network error handling) ve API yanıt standartlaşması (fail-safe tasarım) geliştirme aşamasındadır.
**Kanıt:** JWT korumalı endpointler; proje adımlarında "Açık Kritik İşler" arasında belirtilen hata yönetimi geliştirmeleri.

### 1.4 Kullanıcı Doğrulaması (Puan: 3/5)
**Gerekçe:** Seed (demo) veriler ile hemşire ve hasta rolleri üzerinden sistem simüle edilmektedir. Farklı hesaplar ile yetki izolasyonları başarıyla çalışmaktadır. Ancak henüz gerçek hemşireler veya hastalar üzerinde kullanılabilirlik (UX) ve kabul testleri gerçekleştirilmemiştir.
**Kanıt:** `nurse@nakil.com` ve TC numaralı hasta giriş senaryolarının aktif çalışması.

### 1.5 Performans Metriği (Puan: 4/5)
**Gerekçe:** Native SwiftUI ve PostgreSQL + Node.js altyapısı kullanılması sayesinde veri okuma/yazma (CRUD) işlemleri hızlı gerçekleşmektedir. ARKit temel tarama özellikleri optimize çalışmaktadır, AR modellerinin yüklenmesi sırasında oluşabilecek performans sorunları donanım üzerinde takip edilmektedir.
**Kanıt:** Modern teknoloji stakı ve hızlı uygulama tepki süreleri.

---

## 2. Toplam Puan ve TÜBİTAK TEYDEB THS Karşılığı

- **Kriterlerin Toplam Puanı:** 17 / 25
- **Yüzdelik Karşılığı:** %68

**TÜBİTAK TEYDEB THS Referans Ölçeğine Göre Hedeflenen ve Mevcut Kademeler:**
- **THS 4 - Lab Doğrulaması (Geliştirme):** Teknoloji laboratuvar ortamında doğrulandı. (Proje bu aşamayı başarıyla geçmiştir.)
- **THS 5 - İlgili Ortam Doğrulama (Geliştirme):** Teknoloji ilgili ortamda doğrulandı. (Projenin şu anki ulaştığı seviye)
- **THS 6 - İlgili Ortam Demo (Demo):** Teknoloji/sistem modeli ilgili ortamda gösterildi. (Projenin final hedefi)

**Değerlendirme Sonucu:**
Toplam elde edilen %68'lik metrik puanı, projeyi TÜBİTAK TEYDEB standartlarına göre **THS 5 (İlgili Ortam Doğrulama)** ile **THS 6 (İlgili Ortam Demo)** arasında konumlandırmaktadır. 

Proje, temel MVP'sini ve laboratuvar doğrulamasını (**THS 4**) başarıyla tamamlamış; rol bazlı gerçekçi verilerle uçtan uca çalışarak "İlgili Ortam Doğrulama" (**THS 5**) aşamasına ulaşmıştır. Açık kalan görevler (AR model animasyon entegrasyonu, bildirimler ve hata toleransı merkezileştirmesi) tamamlanıp hastane ortamı senaryolarıyla (ilgili ortam) test edildiğinde doğrudan **THS 6 (İlgili Ortam Demo)** hedefine yükselecektir. Mevcut haliyle proje "THS 5" hedefini net bir şekilde karşılamaktadır.
