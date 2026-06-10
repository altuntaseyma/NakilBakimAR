import SwiftUI

// MARK: - Task Category Model
private struct TaskCategory {
    let id: String
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let lightBg: Color
    let templates: [TaskTemplate]
}

private struct TaskTemplate {
    let title: String
    let description: String
}

// MARK: - AddTaskView
struct AddTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var api: APIService

    let patient: PatientProfile

    @State private var selectedCategoryId = "exercise"
    @State private var title = ""
    @State private var description = ""
    @State private var useScheduledDate = false
    @State private var scheduledDate = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var loading = false
    @State private var errorText = ""
    @State private var showPreview = false

    private static let categories: [TaskCategory] = [
        TaskCategory(
            id: "exercise",
            title: "Egzersiz",
            subtitle: "Mobilizasyon & nefes",
            icon: "figure.walk",
            color: InonuPalette.exerciseBlue,
            lightBg: InonuPalette.exerciseLight,
            templates: [
                TaskTemplate(title: "10 dk yürüyüş", description: "Koridorda yavaş tempolu 10 dakikalık yürüyüş yapınız. Nefes darlığı hissedildiğinde durunuz."),
                TaskTemplate(title: "Derin nefes egzersizi", description: "Yatakta 10 tekrar derin nefes alma-verme egzersizi. Her nefes 4 saniye tutulacak."),
                TaskTemplate(title: "Ayak bileği rotasyonu", description: "Pulmoner emboli riskini azaltmak için her iki ayak bileğini 10'ar kez saat yönünde çeviriniz."),
                TaskTemplate(title: "Diz bükme egzersizi", description: "Sırtüstü pozisyonda dizi göğse doğru çekerek 5 saniye tutunuz. Her bacak için 5 tekrar yapınız."),
                TaskTemplate(title: "Otur-kalk egzersizi", description: "Hemşire gözetiminde yataktan kalkıp sandalyeye oturma ve geri yatma. 3 tekrar yapınız.")
            ]
        ),
        TaskCategory(
            id: "medication",
            title: "İlaç",
            subtitle: "İmmünosupresan & destek",
            icon: "pills.fill",
            color: InonuPalette.medicationPurple,
            lightBg: InonuPalette.medicationLight,
            templates: [
                TaskTemplate(title: "Sabah dozu: Takrolimus (FK506)", description: "Sabah aç karnına Takrolimus alınacak. Dozun tam saatinde alınması kritiktir. Greyfurt suyu ile alınmaması gerekir."),
                TaskTemplate(title: "Öğle dozu: Mikofenolat Mofetil", description: "Öğle yemeğiyle birlikte Mikofenolat Mofetil alınacak. Mide bulantısı durumunda hemşireye bildirin."),
                TaskTemplate(title: "Akşam dozu: Prednizon", description: "Akşam yemeği ile birlikte Prednizon alınacak. Kan şekeri takibi yapılmalıdır."),
                TaskTemplate(title: "Kan basıncı ilacı", description: "Kan basıncı ilacı sabah ölçümü yapıldıktan sonra alınacak. TA değerini kaydediniz."),
                TaskTemplate(title: "İlaç düzeyi kan testi", description: "Takrolimus kan düzeyi (trough level) ölçümü için sabah doz öncesi kan alınacak. Açlık durumu kontrol edilecek.")
            ]
        ),
        TaskCategory(
            id: "nutrition",
            title: "Beslenme",
            subtitle: "Diyet & sıvı takibi",
            icon: "fork.knife",
            color: InonuPalette.nutritionOrange,
            lightBg: InonuPalette.nutritionLight,
            templates: [
                TaskTemplate(title: "Düşük tuzlu öğün takibi", description: "Günlük tuz alımı 2 gr ile sınırlandırılacak. İşlenmiş gıda, konserve ve hazır çorba tüketiminden kaçınılacak."),
                TaskTemplate(title: "Protein takviyesi", description: "Her öğünde yeterli protein alımı sağlanacak (yumurta, tavuk, balık). Günlük hedef: vücut ağırlığının 1.2 katı gram protein."),
                TaskTemplate(title: "Sıvı alımı takibi", description: "Günlük sıvı alımı 1.5-2 litre ile sınırlandırılacak. Çay, kahve ve meyve suyu dahildir. Bardak sayısı kaydedilecek."),
                TaskTemplate(title: "Şeker kısıtlı diyet", description: "Prednizon kaynaklı hiperglisemi riski nedeniyle şekerli içecek ve tatlıdan kaçınılacak. Kan şekeri ölçümü yapılacak."),
                TaskTemplate(title: "Potasyum kısıtlaması", description: "Takrolimus kaynaklı hiperkalemi riskine karşı muz, portakal, patates ve domates tüketimi sınırlandırılacak.")
            ]
        ),
        TaskCategory(
            id: "wound_care",
            title: "Yara Bakımı",
            subtitle: "Pansuman & enfeksiyon takibi",
            icon: "bandage.fill",
            color: InonuPalette.woundCoral,
            lightBg: InonuPalette.woundLight,
            templates: [
                TaskTemplate(title: "Steril pansuman değişimi", description: "Karın bölgesi ameliyat yarası steril teknikle temizlenecek ve yeni pansuman uygulanacak. Enfeksiyon belirtileri not edilecek."),
                TaskTemplate(title: "Yara yeri enfeksiyon kontrolü", description: "Ameliyat bölgesinde kızarıklık, ısı artışı, akıntı veya şişlik var mı değerlendirilecek. Bulgular belgelenecek."),
                TaskTemplate(title: "Dren takibi ve boşaltma", description: "Jackson-Pratt dreninin içeriği ve miktarı değerlendirilecek. Günlük drenaj miktarı kaydedilecek."),
                TaskTemplate(title: "T-tüp bakımı", description: "T-tüp çıkış bölgesi temizlenecek ve tüp çevresindeki cilt bütünlüğü değerlendirilecek. Safra drenaj miktarı not edilecek."),
                TaskTemplate(title: "İnsizyonel herni değerlendirmesi", description: "Kesi bölgesinde şişlik veya çıkıntı olup olmadığı kontrol edilecek. Karın içi basınç artışına yol açan durumlardan kaçınılacak.")
            ]
        )
    ]

    private var selectedCategory: TaskCategory {
        Self.categories.first { $0.id == selectedCategoryId } ?? Self.categories[0]
    }

    var body: some View {
        ZStack {
            AnimatedBackground(accentColor: selectedCategory.color)
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.large) {

                    // Hero
                    heroHeader

                    // Kategori Seçici
                    categoryPicker

                    // Şablon Önerileri
                    templateSection

                    // Manuel Giriş
                    manualInputSection

                    // Zamanlama
                    schedulingSection

                    // Görev Önizlemesi
                    if showPreview && !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        previewCard
                    }

                    // Hata
                    if !errorText.isEmpty {
                        SurfaceCard {
                            Label(errorText, systemImage: "exclamationmark.triangle.fill")
                                .font(AppTypography.helper)
                                .foregroundStyle(InonuPalette.danger)
                        }
                    }

                    // Eylem Butonları
                    actionButtons
                }
                .padding()
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Görev Ata")
        .navigationBarTitleDisplayMode(.inline)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: selectedCategoryId)
    }

    // MARK: - Hero Header
    private var heroHeader: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(selectedCategory.color.opacity(0.15))
                    .frame(width: 52, height: 52)
                Image(systemName: selectedCategory.icon)
                    .font(.title3.bold())
                    .foregroundStyle(selectedCategory.color)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text("Görev Ata")
                    .font(.title3.bold())
                    .foregroundStyle(InonuPalette.deepNavy)
                Text(patient.fullName ?? "Hasta için görev planlaması")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            StatusPill(text: selectedCategory.title, color: selectedCategory.color)
        }
        .padding(AppSpacing.large)
        .background(Color.white.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.large))
        .overlay(RoundedRectangle(cornerRadius: AppRadius.large).stroke(selectedCategory.color.opacity(0.2), lineWidth: 1.5))
        .shadow(color: selectedCategory.color.opacity(0.12), radius: 12, x: 0, y: 5)
    }

    // MARK: - Category Picker
    private var categoryPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("KATEGORİ SEÇİN")
                .font(.caption.bold())
                .tracking(1.0)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(Self.categories, id: \.id) { cat in
                    categoryCard(cat)
                }
            }
        }
    }

    private func categoryCard(_ cat: TaskCategory) -> some View {
        let isSelected = selectedCategoryId == cat.id
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                selectedCategoryId = cat.id
                title = ""
                description = ""
            }
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isSelected ? cat.color : cat.color.opacity(0.12))
                            .frame(width: 34, height: 34)
                        Image(systemName: cat.icon)
                            .font(.subheadline.bold())
                            .foregroundStyle(isSelected ? .white : cat.color)
                    }
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(cat.color)
                            .font(.subheadline)
                    }
                }
                Text(cat.title)
                    .font(.subheadline.bold())
                    .foregroundStyle(isSelected ? cat.color : InonuPalette.deepNavy)
                Text(cat.subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .padding(12)
            .background(isSelected ? cat.color.opacity(0.08) : Color.white.opacity(0.95))
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.medium)
                    .stroke(isSelected ? cat.color : InonuPalette.cardBorder, lineWidth: isSelected ? 2 : 1)
            )
            .shadow(color: isSelected ? cat.color.opacity(0.18) : AppShadow.card, radius: isSelected ? 8 : 4, x: 0, y: isSelected ? 4 : 2)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Template Section
    private var templateSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("HIZLI ŞABLONLAR")
                    .font(.caption.bold())
                    .tracking(1.0)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("Seçince otomatik dolar")
                    .font(.caption2)
                    .foregroundStyle(selectedCategory.color)
            }

            VStack(spacing: 8) {
                ForEach(selectedCategory.templates, id: \.title) { template in
                    templateRow(template)
                }
            }
        }
    }

    private func templateRow(_ template: TaskTemplate) -> some View {
        let isActive = title == template.title
        return Button {
            withAnimation(.easeOut(duration: 0.2)) {
                title = template.title
                description = template.description
                showPreview = true
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: isActive ? "checkmark.circle.fill" : "doc.text")
                    .font(.subheadline)
                    .foregroundStyle(isActive ? selectedCategory.color : .secondary)
                    .frame(width: 20)

                VStack(alignment: .leading, spacing: 2) {
                    Text(template.title)
                        .font(.subheadline.bold())
                        .foregroundStyle(isActive ? selectedCategory.color : InonuPalette.deepNavy)
                    Text(template.description)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption2.bold())
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .background(isActive ? selectedCategory.color.opacity(0.07) : Color.white.opacity(0.95))
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.medium)
                    .stroke(isActive ? selectedCategory.color.opacity(0.4) : InonuPalette.cardBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Manual Input
    private var manualInputSection: some View {
        SurfaceCard(accentColor: selectedCategory.color) {
            SectionCardTitle(text: "Manuel Görev Tanımı", icon: "pencil.and.list.clipboard", color: selectedCategory.color)

            VStack(alignment: .leading, spacing: 6) {
                Text("BAŞLIK")
                    .font(.caption.bold())
                    .tracking(0.6)
                    .foregroundStyle(selectedCategory.color)
                TextField("Görev başlığı girin...", text: $title)
                    .glassInputField()
                    .onChange(of: title) { _ in showPreview = !title.isEmpty }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("AÇIKLAMA")
                    .font(.caption.bold())
                    .tracking(0.6)
                    .foregroundStyle(selectedCategory.color)
                TextField("Görev açıklaması (opsiyonel)...", text: $description, axis: .vertical)
                    .lineLimit(3...5)
                    .glassInputField()
            }
        }
    }

    // MARK: - Scheduling
    private var schedulingSection: some View {
        SurfaceCard {
            SectionCardTitle(text: "Zamanlama", icon: "calendar.badge.clock")

            Toggle(isOn: $useScheduledDate.animation()) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Planlı tarih ve saat ekle")
                        .font(.subheadline)
                    Text("Eklenmezse hemşire takvimine göre uygulanır")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .tint(selectedCategory.color)

            if useScheduledDate {
                VStack(spacing: 10) {
                    // Hızlı kısayollar
                    HStack(spacing: 8) {
                        quickDateButton("Bugün", date: todayAt9)
                        quickDateButton("Yarın", date: tomorrowAt9)
                        quickDateButton("Öğlen", date: todayAtNoon)
                        quickDateButton("Akşam", date: todayAt18)
                    }

                    DatePicker("", selection: $scheduledDate, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                        .labelsHidden()
                        .datePickerStyle(.compact)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .tint(selectedCategory.color)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private func quickDateButton(_ label: String, date: Date) -> some View {
        let isSelected = Calendar.current.isDate(scheduledDate, equalTo: date, toGranularity: .hour)
        return Button {
            withAnimation { scheduledDate = date }
        } label: {
            Text(label)
                .font(.caption.bold())
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(isSelected ? selectedCategory.color : selectedCategory.color.opacity(0.08))
                .foregroundStyle(isSelected ? .white : selectedCategory.color)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Preview Card
    private var previewCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Görev Önizlemesi", systemImage: "eye.fill")
                    .font(.caption.bold())
                    .foregroundStyle(selectedCategory.color)
                Spacer()
            }
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(selectedCategory.color.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: selectedCategory.icon)
                        .foregroundStyle(selectedCategory.color)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline.bold())
                        .foregroundStyle(InonuPalette.deepNavy)
                    if !description.isEmpty {
                        Text(description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    HStack(spacing: 6) {
                        StatusPill(text: selectedCategory.title, color: selectedCategory.color)
                        if useScheduledDate {
                            StatusPill(text: scheduledDate.formatted(date: .abbreviated, time: .shortened), color: InonuPalette.info)
                        }
                    }
                }
            }
        }
        .padding(AppSpacing.large)
        .background(selectedCategory.color.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.large))
        .overlay(RoundedRectangle(cornerRadius: AppRadius.large).stroke(selectedCategory.color.opacity(0.25), lineWidth: 1))
        .transition(.opacity.combined(with: .scale(scale: 0.97)))
    }

    // MARK: - Action Buttons
    private var actionButtons: some View {
        HStack(spacing: AppSpacing.medium) {
            Button("İptal") { dismiss() }
                .buttonStyle(CustomButtonStyle(tint: InonuPalette.deepNavy, isSecondary: true))

            Button {
                Task { await saveTask() }
            } label: {
                HStack(spacing: 6) {
                    if loading {
                        ProgressView().tint(.white).scaleEffect(0.85)
                    } else {
                        Image(systemName: "checkmark")
                    }
                    Text(loading ? "Kaydediliyor..." : "Görevi Kaydet")
                }
            }
            .disabled(loading || isTitleInvalid)
            .buttonStyle(CustomButtonStyle(tint: selectedCategory.color))
        }
    }

    // MARK: - Helpers
    private var isTitleInvalid: Bool {
        title.trimmingCharacters(in: .whitespacesAndNewlines).count < 3
    }

    private var todayAt9: Date {
        Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    }
    private var todayAtNoon: Date {
        Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date()) ?? Date()
    }
    private var todayAt18: Date {
        Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date()) ?? Date()
    }
    private var tomorrowAt9: Date {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        return Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: tomorrow) ?? tomorrow
    }

    private func saveTask() async {
        loading = true
        defer { loading = false }
        do {
            let iso = useScheduledDate ? ISO8601DateFormatter().string(from: scheduledDate) : nil
            try await api.createTask(
                patientProfileId: patient.id,
                type: selectedCategoryId,
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                description: description.trimmingCharacters(in: .whitespacesAndNewlines),
                scheduledAtISO: iso
            )
            dismiss()
        } catch {
            errorText = "Görev kaydedilemedi: \(error.localizedDescription)"
        }
    }
}
