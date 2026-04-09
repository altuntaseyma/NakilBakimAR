# NakilBakimAR

Karaciger nakli pre-op ve post-op bakim asistani icin iOS (SwiftUI + ARKit) ve PostgreSQL backend projesi.

## Proje Takip Dokumanlari
- Adim adim gelistirme plani ve checklist: `docs/PROJECT_STEPS.md`
- Durum ozeti ve tamamlanan isler: `docs/STATUS.md`

## Backend calistirma
1. `backend/.env.example` dosyasini `backend/.env` olarak kopyala.
2. PostgreSQL'de `nakilbakimar` adli DB olustur.
3. `backend` klasorunde:
   - `npm install`
   - `npm run migrate`
   - `npm run seed`
   - `npm run dev`
4. Kontrol: `GET http://localhost:8080/health`

## iOS onizleme nasil yapilir?
1. Xcode projesini ac: `ios/NakilBakimARios/NakilBakimAR.xcodeproj`
2. Simulatorde test icin `Constants.swift` icinde API adresini `http://localhost:8080/api` olarak tut.
3. `Signing & Capabilities` altinda camera ve push izinlerini ekle (AR ve bildirimler icin).
4. `LoginView` veya `DashboardView` icin Canvas Preview ac:
   - Editorde dosyayi ac
   - `Resume` ile SwiftUI canvas'i calistir
5. Gercek cihazda test icin API hostunu Mac IP adresine cevir.

## Demo Kullanici Bilgileri (Seed)
- Hemsire: `nurse@nakil.com` / `123456`
- Hasta: `patient1@nakil.com` / `123456`
