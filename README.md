# NakilBakimAR

Karaciger nakli pre-op ve post-op bakim asistani icin iOS + PostgreSQL backend proje iskeleti.

## Tamamlanan ilk adimlar
- `backend` klasorunde Express + JWT + PostgreSQL tabanli MVP endpointleri olusturuldu.
- Veritabani icin migration ve seed dosyalari eklendi.
- `NakilBakimAR` klasorunde SwiftUI dosya yapisi ve modern giris ekrani iskeleti olusturuldu.

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
1. Xcode ile yeni bir iOS App projesi ac ve adini `NakilBakimAR` yap.
2. Bu depodaki `NakilBakimAR` klasorunun altindaki Swift dosyalarini projeye ekle.
3. `Signing & Capabilities` altinda camera ve push izinlerini ekleyecegiz (sonraki adim).
4. `LoginView` veya `DashboardView` icin Canvas Preview ac:
   - Editorde dosyayi ac
   - `Resume` ile SwiftUI canvas'i calistir
5. Simulatorde test et:
   - API base URL `localhost` yerine Mac IP adresi kullan (gercek cihazda zorunlu)

## Sonraki adim
- Nurse/Patient ekranlarinin gercek API baglantilarini tamamlamak
- AR marker tarama (`ARImageTrackingConfiguration`) ekranini eklemek
- FCM + email bildirim entegrasyonu
