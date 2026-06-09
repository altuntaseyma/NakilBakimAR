import os
import re

files_to_fix = [
    "NakilBakimAR/Views/Patient/DashboardView.swift",
    "NakilBakimAR/Views/Patient/ExerciseModuleView.swift",
    "NakilBakimAR/Views/Patient/NutritionModuleView.swift",
    "NakilBakimAR/Views/Patient/MedicationModuleView.swift",
    "NakilBakimAR/Views/Patient/WoundCareModuleView.swift",
    "NakilBakimAR/Views/Patient/VitalSignsModuleView.swift",
    "NakilBakimAR/Views/Patient/TaskListView.swift",
    "NakilBakimAR/Views/Nurse/PatientList.swift",
    "NakilBakimAR/Views/Nurse/PatientDetail.swift",
    "NakilBakimAR/Views/Nurse/AddTaskView.swift",
    "NakilBakimAR/Views/Nurse/AddVitalView.swift"
]

replacements = {
    '"Gorevler yuklenemedi."': '"Görevler yüklenemedi."',
    '"Vital verileri yuklenemedi."': '"Vital verileri yüklenemedi."',
    '"Moduller yuklenemedi."': '"Modüller yüklenemedi."',
    '"Panel verileri yuklenemedi: ': '"Panel verileri yüklenemedi: ',
    '"AMELIYATA HAZIRLIK"': '"AMELİYATA HAZIRLIK"',
    '"IYILESME YOLCULUGU"': '"İYİLEŞME YOLCULUĞU"',
    '"Genel Saglik"': '"Genel Sağlık"',
    '"Ameliyat sonrasi "': '"Ameliyat sonrası "',
    '"Degerleriniz stabil seyrediyor."': '"Değerleriniz stabil seyrediyor."',
    '"Dikkatli olmaniz gereken"': '"Dikkatli olmanız gereken"',
    '"Bugun icin planlanan adimlari asagida gorebilirsin."': '"Bugün için planlanan adımları aşağıda görebilirsin."',
    '"Bakim Modullerim"': '"Bakım Modüllerim"',
    '"Moduller yukleniyor..."': '"Modüller yükleniyor..."',
    '"Aktif modul bulunamadi"': '"Aktif modül bulunamadı"',
    '"Hemsire aktif modul tanimladiginda bu alan dolacak."': '"Hemşire aktif modül tanımladığında bu alan dolacak."',
    '"Haftalik Ilerleme"': '"Haftalık İlerleme"',
    '"Ilaclarim"': '"İlaçlarım"',
    '"Siradaki Ilaciniz"': '"Sıradaki İlacınız"',
    '"Tum Ilaclar"': '"Tüm İlaçlar"',
    '"Bekleyen ilaciniz yok"': '"Bekleyen ilacınız yok"',
    '"Ilac Takvimi"': '"İlaç Takvimi"',
    '"Gunluk ilac dozu"': '"Günlük İlaç Dozu"',
    '"Guvenlik Uyarilari"': '"Güvenlik Uyarıları"',
    '"Aclik/Tokluk Kurallari"': '"Açlık/Tokluk Kuralları"',
    '"Bazi ilaclarin besinlerle etkilesiminden kacinilmalidir. Detaylar."': '"Bazı ilaçların besinlerle etkileşiminden kaçınılmalıdır. Detaylar."',
    '"Olası Yan Etkiler"': '"Olası Yan Etkiler"',
    '"Mide bulantisi vb. yan etkilerde doktorunuza basvurun."': '"Mide bulantısı vb. yan etkilerde doktorunuza başvurun."',
    '"Egzersiz Plani"': '"Egzersiz Planı"',
    '"Gunluk Solunum"': '"Günlük Solunum"',
    '"Basla"': '"Başla"',
    '"Egzersiz Rehberi"': '"Egzersiz Rehberi"',
    '"Mobilizasyon"': '"Mobilizasyon"',
    '"Ogunler"': '"Öğünler"',
    '"Aksam"': '"Akşam"',
    '"Sabah"': '"Sabah"',
    '"Ogle"': '"Öğle"',
    '"Tuketim"': '"Tüketim"',
    '"Hedefine ulastin"': '"Hedefine ulaştın"',
    '"Beslenme Notlari"': '"Beslenme Notları"',
    '"Su tuketimi"': '"Su Tüketimi"',
    '"kalan: "': '"kalan: "',
    '"Tamamlanan: "': '"Tamamlanan: "',
    '"Aktif Hastalar"': '"Aktif Hastalar"', # Already fine
    '"Yara Bakimi"': '"Yara Bakımı"',
    '"Acik yara"': '"Açık Yara"',
    '"Tansiyon/Nabiz"': '"Tansiyon/Nabız"',
    '"Ates/Kilo"': '"Ateş/Kilo"',
    '"Karaciger Nakli Enstitusu"': '"Karaciğer Nakli Enstitüsü"',
    '"Turgut Ozal Tip Merkezi"': '"Turgut Özal Tıp Merkezi"',
    '"Gorev Ekle"': '"Görev Ekle"',
    '"Kaydediliyor..."': '"Kaydediliyor..."',
    '"Kaydet"': '"Kaydet"',
    '"Gorev Basligi"': '"Görev Başlığı"',
    '"Aciklama (Opsiyonel)"': '"Açıklama (Opsiyonel)"',
    '"Tarih ve Saat"': '"Tarih ve Saat"',
    '"Vital Ekle"': '"Vital Ekle"',
    '"Buyuk Tansiyon"': '"Büyük Tansiyon"',
    '"Kucuk Tansiyon"': '"Küçük Tansiyon"',
    '"Nabiz"': '"Nabız"',
    '"Ates (Orn: 36.5)"': '"Ateş (Örn: 36.5)"',
    '"Solunum Sayisi"': '"Solunum Sayısı"',
    '"Kilo (Orn: 70.5)"': '"Kilo (Örn: 70.5)"',
    '"VARDİYA ÖZETİ"': '"VARDİYA ÖZETİ"',
    '"Tamamlanan"': '"Tamamlanan"',
    '"Modül Kontrolleri"': '"Modül Kontrolleri"',
    '"Operasyon Durumu"': '"Operasyon Durumu"',
    '"Son Aktiviteler"': '"Son Aktiviteler"',
    '"Vardiya Özeti"': '"Vardiya Özeti"',
    '"Gorev"': '"Görev"',
    '"Vitaller yukleniyor..."': '"Vitaller yükleniyor..."',
    '"Gorevler yukleniyor..."': '"Görevler yükleniyor..."',
    '"Görev Tamamlandi"': '"Görev Tamamlandı"',
    '"Vital Veri Karsilandi"': '"Vital Veri Eklendi"'
}

for file_path in files_to_fix:
    if not os.path.exists(file_path):
        continue
    with open(file_path, "r", encoding="utf-8") as f:
        content = f.read()

    for old, new in replacements.items():
        content = content.replace(old, new)
        
    with open(file_path, "w", encoding="utf-8") as f:
        f.write(content)

print("Turkish characters fixed.")
