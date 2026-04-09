# NakilBakimAR - Proje Adimlari

Bu dosya GitHub uzerinde proje adimlarini net gostermek icin tutulur.

## Faz 0 - Altyapi ve Kurulum
- [x] Monorepo yapisi olusturuldu (`backend`, `ios`, `docs`).
- [x] PostgreSQL migration/seed altyapisi kuruldu.
- [x] JWT auth ve temel role bazli yetki yapisi kuruldu.
- [x] iOS SwiftUI temel proje dosyalari eklendi.

## Faz 1 - Cekirdek Klinik Akis (MVP)
- [x] Auth endpointleri (`register`, `login`, `refresh`).
- [x] Hemsire hasta listesi ve profil akislari.
- [x] Gorev olusturma, listeleme, tamamlama.
- [x] Vital kayit, listeleme, paylasim secenegi.
- [x] AR marker endpoint (`/api/ar/marker/:markerId`).
- [x] iOS nurse/patient dashboard temel ekranlari.

## Faz 2 - Kisisellestirme ve Pre-op / Post-op
- [x] Hastanin fazi (`pre_op` / `post_op`) backendden turetiliyor.
- [x] Hemsire operasyon tarih-saat girerek post-op yapabiliyor.
- [x] Hemsire pre-op olarak geri alabiliyor.
- [x] Hemsire modulleri ac/kapatabiliyor.
- [x] Pre-op/Post-op icin modullerde tek tik preset uygulanabiliyor.
- [x] Hasta dashboard aktif modullere gore dinamik gosterim yapiyor.

## Faz 3 - AR Senaryo ve Egitim Akisi
- [x] ARKit image tracking altyapisi (iOS tarafi).
- [x] Marker ID ile backend AR icerik cekme.
- [x] Mobilizasyon senaryo karar log kaydi (dogru/yanlis secim) eklendi.
- [ ] Marker tanininca otomatik model bind + animasyon oynatma.
- [ ] Ilac senaryosu icin ikinci AR marker ve model akisi.

## Faz 4 - Klinik Takip ve Analitik
- [x] Hemsire gorev/vital kayitlarini hasta detayinda gorebiliyor.
- [x] Hemsire gorev ve vital silebiliyor.
- [x] Vital kaydi icin tarih-saat secimi eklendi.
- [x] Senaryo log ozet endpointi (`/summary`) eklendi.
- [x] Hasta panelinde uyum analizi karti eklendi.
- [ ] Hasta panelinde mini trend grafikler.
- [ ] Hemsire panelinde haftalik uyum toplami.

## Faz 5 - Bildirimler ve Uretime Hazirlik
- [ ] FCM token yonetimi (iOS + backend).
- [ ] Gorev bazli push bildirim tetikleme.
- [ ] Email hatirlatma akisi (nodemailer) uretim konfigu.
- [ ] Offline fallback local notification.

## Faz 6 - Tasarim ve Sunum Hazirligi
- [ ] Karaciger temali ozel grafik assetleri.
- [ ] Mikro animasyonlar (kart, gecis, durum degisimi).
- [ ] Bos durum ekranlari ve onboarding.
- [ ] TestFlight hazirligi ve surum notlari.
- [ ] Kullanici kilavuzu (hemsire/hasta) ve demo video.

## Kisa Teknik Backlog
- [ ] API response hata standartlasmasi
- [ ] iOS tarafi network error handling merkezilestirme
- [ ] Unit/integration test coverage artisi
- [ ] CI pipeline (lint + test + build)
