import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var api: APIService
    @State private var screenError = ""

    private var patientName: String {
        api.myProfile?.fullName ?? "Hasta"
    }

    private var timeline: SurgeryTimeline? {
        SurgeryTimeline.parse(iso: api.myProfile?.transplantDate)
    }

    private var isPostOp: Bool {
        api.myProfile?.carePhase == "post_op"
    }

    var body: some View {
        ZStack {
            AnimatedBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    heroCard
                    healthScoreCard
                    quickStatusRow
                    moduleGrid
                    weeklyTrendCard

                    if !screenError.isEmpty {
                        errorCard
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
        .navigationTitle("Ana Sayfa")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            do {
                try await api.fetchMyProfile()
                if let id = api.myProfile?.id {
                    do { try await api.fetchTasks(patientProfileId: id) } catch { screenError = "Görevler yüklenemedi." }
                    do { try await api.fetchVitals(patientProfileId: id) } catch { screenError = "Vital verileri yüklenemedi." }
                    do { try await api.fetchMyModules() } catch { screenError = "Modüller yüklenemedi." }
                    do { try await api.fetchScenarioSummary(patientProfileId: id) } catch { /* Karar ozeti opsiyonel */ }
                }
            } catch {
                screenError = "Panel verileri yüklenemedi: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Hero Card (Mockup: "Merhaba Elif Hanım")
    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let tl = timeline {
                Text(tl.dayOffset < 0 ? "AMELİYATA HAZIRLIK" : "İYİLEŞME YOLCULUĞU")
                    .font(.caption.bold())
                    .tracking(1.2)
                    .foregroundStyle(.white.opacity(0.8))
            }

            Text("Merhaba, \(patientName).")
                .font(AppTypography.heroTitle)
                .foregroundStyle(.white)

            if let tl = timeline {
                Text(tl.statusTitle + ". Degerleriniz stabil seyrediyor.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
            } else {
                Text("Bugün için planlanan adımları aşağıda görebilirsin.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.xLarge)
        .padding(.vertical, 4)
        .background(LinearGradient.dashboardGradient)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.xLarge))
        .shadow(color: AppShadow.hero, radius: 16, x: 0, y: 8)
    }

    // MARK: - Health Score Card
    private var healthScoreCard: some View {
        let summary = api.scenarioSummary
        let score = summary?.successRate ?? 0

        return SurfaceCard(accentColor: InonuPalette.primary) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("GENEL SAĞLIK SKORU")
                        .font(.caption.bold())
                        .tracking(0.8)
                        .foregroundStyle(.secondary)
                    Text("%\(score)")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundStyle(score >= 70 ? InonuPalette.success : InonuPalette.warning)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 6) {
                    StatusPill(
                        text: isPostOp ? "Post-op" : "Pre-op",
                        color: isPostOp ? InonuPalette.primary : InonuPalette.info
                    )
                    if let summary {
                        Text("\(summary.correctDecisions ?? 0) doğru karar")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(InonuPalette.cream)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [InonuPalette.primary, InonuPalette.secondary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * CGFloat(min(score, 100)) / 100)
                }
            }
            .frame(height: 8)
        }
    }

    // MARK: - Quick Status Row
    private var quickStatusRow: some View {
        let nutritionCount = api.tasks.filter { $0.type == "nutrition" && !$0.isCompleted }.count
        let medCount = api.tasks.filter { $0.type == "medication" && !$0.isCompleted }.count
        let exerciseCount = api.tasks.filter { $0.type == "exercise" && !$0.isCompleted }.count

        return HStack(spacing: 10) {
            quickStatItem("İlaç", "\(medCount)", InonuPalette.medicationPurple)
            quickStatItem("Egzersiz", "\(exerciseCount)", InonuPalette.exerciseBlue)
            quickStatItem("Beslenme", "\(nutritionCount)", InonuPalette.nutritionOrange)
        }
    }

    private func quickStatItem(_ title: String, _ value: String, _ color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(color)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(color.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.medium)
                .stroke(color.opacity(0.12), lineWidth: 1)
        )
    }

    // MARK: - Module Grid
    private var moduleGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Bakım Modüllerim")
                .font(AppTypography.sectionTitle)
                .foregroundStyle(InonuPalette.deepNavy)

            if api.modulesLoading && api.patientModules.isEmpty {
                LoadingStateCard(text: "Modüller yükleniyor...")
            } else if api.patientModules.filter(\.isEnabled).isEmpty {
                EmptyStateCard(
                    title: "Aktif modül bulunamadı",
                    subtitle: "Hemşire aktif modül tanımladığında bu alan dolacak."
                )
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(api.patientModules.filter(\.isEnabled)) { module in
                        let style = ModuleStyleMap.style(for: module.name)
                        if module.name == "medication" {
                            Button {
                                api.selectedPatientTab = 1
                            } label: {
                                ModuleCard(
                                    title: style.title,
                                    subtitle: style.subtitle,
                                    icon: style.icon,
                                    accentColor: style.accent,
                                    lightBg: style.lightBg,
                                    isInteractive: true
                                )
                            }
                            .buttonStyle(.plain)
                        } else if module.name == "mobilization" {
                            Button {
                                api.selectedPatientTab = 2
                            } label: {
                                ModuleCard(
                                    title: style.title,
                                    subtitle: style.subtitle,
                                    icon: style.icon,
                                    accentColor: style.accent,
                                    lightBg: style.lightBg,
                                    isInteractive: true
                                )
                            }
                            .buttonStyle(.plain)
                        } else if module.name == "nutrition" {
                            Button {
                                api.selectedPatientTab = 3
                            } label: {
                                ModuleCard(
                                    title: style.title,
                                    subtitle: style.subtitle,
                                    icon: style.icon,
                                    accentColor: style.accent,
                                    lightBg: style.lightBg,
                                    isInteractive: true
                                )
                            }
                            .buttonStyle(.plain)
                        } else {
                            NavigationLink {
                                moduleDestination(for: module.name)
                            } label: {
                                ModuleCard(
                                    title: style.title,
                                    subtitle: style.subtitle,
                                    icon: style.icon,
                                    accentColor: style.accent,
                                    lightBg: style.lightBg,
                                    isInteractive: true
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Weekly Trend
    private var weeklyTrendCard: some View {
        let items = weeklyBars()
        let maxValue = max(items.map { $0.count }.max() ?? 1, 1)

        return SurfaceCard {
            SectionCardTitle(text: "Haftalık İlerleme", icon: "chart.bar.fill", color: InonuPalette.primary)
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(items, id: \.day) { item in
                    VStack(spacing: 5) {
                        Text("\(item.count)")
                            .font(.caption2.bold())
                            .foregroundStyle(item.count == 0 ? .secondary : InonuPalette.primary)
                        if item.count == 0 {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(InonuPalette.cream)
                                .frame(height: 6)
                        } else {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(
                                    LinearGradient(
                                        colors: [InonuPalette.primary, InonuPalette.secondary],
                                        startPoint: .bottom,
                                        endPoint: .top
                                    )
                                )
                                .frame(height: CGFloat(item.count) / CGFloat(maxValue) * 56 + 6)
                        }
                        Text(item.day)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    // MARK: - Error Card
    private var errorCard: some View {
        SurfaceCard(accentColor: InonuPalette.danger) {
            Label(screenError, systemImage: "exclamationmark.triangle.fill")
                .font(AppTypography.helper)
                .foregroundStyle(InonuPalette.danger)
        }
    }

    // MARK: - Module Destinations
    @ViewBuilder
    private func moduleDestination(for moduleName: String) -> some View {
        switch moduleName {
        case "mobilization":
            ExerciseModuleView(isPushed: false)
        case "nutrition":
            NutritionModuleView(isPushed: false)
        case "wound_care":
            WoundCareModuleView(isPushed: false)
        case "medication":
            MedicationModuleView(isPushed: false)
        case "vital_signs":
            VitalSignsModuleView(isPushed: false)
        default:
            EmptyStateCard(title: "Modül bulunamadı", subtitle: "Bu modül için ekran tanımı eksik.")
        }
    }

    // MARK: - Helpers
    private func weeklyBars() -> [(day: String, count: Int)] {
        let labels = ["Pzt", "Sal", "Çar", "Per", "Cum", "Cmt", "Paz"]
        var counts = Array(repeating: 0, count: 7)
        let parser = ISO8601DateFormatter()

        for task in api.tasks {
            let reference = task.completedAt ?? task.scheduledTime
            guard let source = reference,
                  let date = parser.date(from: source) else {
                continue
            }
            let weekday = Calendar.current.component(.weekday, from: date)
            let mondayBasedIndex = (weekday + 5) % 7
            counts[mondayBasedIndex] += 1
        }

        return zip(labels, counts).map { ($0.0, $0.1) }
    }
}

// MARK: - Wound Care Module View
struct WoundCareModuleView: View {
    @EnvironmentObject var api: APIService
    var isPushed: Bool = false
    @State private var screenError = ""

    private var woundTasks: [TaskItem] {
        api.tasks.filter { $0.type == "wound_care" }
    }

    private var pendingWoundTask: TaskItem? {
        woundTasks.first(where: { !$0.isCompleted })
    }

    var body: some View {
        ZStack {
            AnimatedBackground(accentColor: InonuPalette.woundCoral)
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.large) {
                    GlassTopBar(
                        title: "Yara Bakımı Modülü",
                        subtitle: "Kontrol adımları ve pansuman takibi",
                        icon: "bandage.fill",
                        accentColor: InonuPalette.woundCoral
                    )
                    woundHeroCard

                    if selectedPhase != .preOp {
                        SurfaceCard(accentColor: InonuPalette.woundCoral) {
                            SectionCardTitle(text: "Klinik Pansuman Protokolü", icon: "calendar.badge.clock", color: InonuPalette.woundCoral)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text(timeline?.statusTitle ?? "Ameliyat planı bekleniyor")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(InonuPalette.deepNavy)
                                
                                Text(postOpWoundMessage)
                                    .font(AppTypography.helper)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    SurfaceCard(accentColor: InonuPalette.woundCoral) {
                        SectionCardTitle(text: "Yara Bakımı Takibi", icon: "cross.vial", color: InonuPalette.woundCoral)
                        if api.tasksLoading && woundTasks.isEmpty {
                            ProgressView("Görevler yükleniyor...")
                        } else if woundTasks.isEmpty {
                            Text("Bu modül için yara bakımı görevi bulunamadı.")
                                .font(AppTypography.helper)
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(woundTasks.prefix(6)) { task in
                                HStack(spacing: 10) {
                                    Image(systemName: task.isCompleted ? "checkmark.seal.fill" : "bandage")
                                        .foregroundStyle(task.isCompleted ? InonuPalette.success : InonuPalette.woundCoral)
                                        .frame(width: 24)
                                    Text(task.title)
                                        .font(.subheadline)
                                    Spacer()
                                    if task.isCompleted {
                                        StatusPill(text: "Tamam", color: InonuPalette.success)
                                    }
                                }
                            }
                        }
                    }

                    if !screenError.isEmpty {
                        SurfaceCard(accentColor: InonuPalette.danger) {
                            Label(screenError, systemImage: "exclamationmark.triangle.fill")
                                .font(AppTypography.helper)
                                .foregroundStyle(InonuPalette.danger)
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Yara Bakımı")
        .toolbar(isPushed ? .hidden : .automatic, for: .tabBar)
        .task {
            guard let id = api.myProfile?.id else { return }
            do {
                try await api.fetchTasks(patientProfileId: id)
            } catch {
                // Hata mesaji ortak state ile gosteriliyor.
            }
        }
    }

    private var woundHeroCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Pansuman ve Kontrol")
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                    Text("Yara durumu ve bakım adımları")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.9))
                }
                Spacer()
                Image(systemName: "bandage.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.white.opacity(0.9))
            }
            HStack(spacing: 8) {
                MetricPill(title: "Bekleyen", value: "\(woundTasks.filter { !$0.isCompleted }.count)")
                MetricPill(title: "Tamamlanan", value: "\(woundTasks.filter(\.isCompleted).count)")
                Spacer()
            }
            if let next = pendingWoundTask, let patientId = api.myProfile?.id {
                Button {
                    Task {
                        do {
                            try await api.completeTask(taskId: next.id, patientProfileId: patientId)
                        } catch {
                            screenError = "Yara bakımı görevi tamamlanamadı: \(error.localizedDescription)"
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "checkmark.circle")
                        Text(next.title)
                    }
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Capsule())
                }
            }
        }
        .padding(AppSpacing.xLarge)
        .background(LinearGradient.woundGradient)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.xLarge))
        .shadow(color: InonuPalette.woundCoral.opacity(0.2), radius: 12, x: 0, y: 6)
    }

    // MARK: - Computed Properties
    private var timeline: SurgeryTimeline? {
        SurgeryTimeline.parse(iso: api.myProfile?.transplantDate)
    }

    private var selectedPhase: PostOpPhase {
        PostOpPhase(dayOffset: timeline?.dayOffset, carePhaseHint: api.myProfile?.carePhase)
    }

    private var postOpWoundMessage: String {
        guard let tl = timeline else { return "Pansuman planınız yükleniyor." }
        let day = tl.postOpDay
        if day == 1 {
            return "Operasyon sonrası 1. Gün: Pansumanlar kapalı kalacak. Drenaj ve yara yeri sızıntısı kontrol edilecek."
        } else if day == 2 {
            return "İlk Pansuman Zamanı ⏰\nSorumlu hemşireniz tarafından ilk steril pansuman değişimi bugün yapılacaktır."
        } else if day == 3 {
            return "Pansumanınız dünkü değişimden sonra temizse dokunulmaz. Enfeksiyon ve sızıntı takibi yapılır."
        } else if day == 4 {
            return "Kontrol Pansumanı Zamanı ⏰\nSteril şartlarda yara yeri kontrol edilip pansuman yenilenir."
        } else if day > 4 && day % 2 == 0 {
            return "Rutin Bakım Günü (İki günde bir): Steril pansuman değişimi ve yara yeri temizliği uygulanır."
        } else {
            return "Dokunulmaz bekleme günü. Sızıntı, koku veya yoğun ağrı durumunda butonu kullanarak görev oluşturun."
        }
    }
}

// MARK: - Vital Signs Module View
struct VitalSignsModuleView: View {
    @EnvironmentObject var api: APIService
    var isPushed: Bool = false
    @State private var screenError = ""
    @State private var showAllVitals = false

    var body: some View {
        ZStack {
            AnimatedBackground(accentColor: InonuPalette.vitalRose)
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.large) {
                    GlassTopBar(
                        title: "Vital Bulgular",
                        subtitle: "Paylaşılan ölçümlerin detaylı görünümü",
                        icon: "heart.text.square",
                        accentColor: InonuPalette.vitalRose
                    )
                    vitalHeroCard

                    SurfaceCard(accentColor: InonuPalette.vitalRose) {
                        SectionCardTitle(text: "Son Ölçümler", icon: "waveform.path.ecg", color: InonuPalette.vitalRose)
                        if api.vitalsLoading && api.vitals.isEmpty {
                            ProgressView("Vital kayıtları yükleniyor...")
                        } else if api.vitals.isEmpty {
                            Text("Paylaşılan vital kaydı bulunamadı.")
                                .font(AppTypography.helper)
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(displayedVitals) { vital in
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        vitalItem("Ateş", String(format: "%.1f°C", vital.bodyTemperature ?? 0))
                                        Spacer()
                                        vitalItem("Nabız", "\(vital.heartRate ?? 0)")
                                    }
                                    HStack {
                                        vitalItem("TA", "\(vital.bloodPressureSystolic ?? 0)/\(vital.bloodPressureDiastolic ?? 0)")
                                        Spacer()
                                        vitalItem("SpO2", "\(vital.oxygenSaturation ?? 0)%")
                                    }
                                    if let recordedAt = vital.recordedAt {
                                        Text(recordedAt.formatIsoDate())
                                            .font(AppTypography.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Divider()
                                }
                            }

                            Button(showAllVitals ? "Özet Liste" : "Tümünü Göster") {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    showAllVitals.toggle()
                                }
                            }
                            .font(.caption.bold())
                            .foregroundStyle(InonuPalette.vitalRose)
                        }
                    }

                    if !screenError.isEmpty {
                        SurfaceCard(accentColor: InonuPalette.danger) {
                            Label(screenError, systemImage: "exclamationmark.triangle.fill")
                                .font(AppTypography.helper)
                                .foregroundStyle(InonuPalette.danger)
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Vital Bulgular")
        .toolbar(isPushed ? .hidden : .automatic, for: .tabBar)
        .task {
            guard let id = api.myProfile?.id else { return }
            do {
                try await api.fetchVitals(patientProfileId: id)
            } catch {
                // Hata mesaji ortak state ile gosteriliyor.
            }
        }
    }

    private func vitalItem(_ title: String, _ value: String) -> some View {
        HStack(spacing: 4) {
            Text(title + ":")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.bold())
                .foregroundStyle(InonuPalette.deepNavy)
        }
    }

    private var vitalHeroCard: some View {
        let latest = api.vitals.first
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Vital Durum Özeti")
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                    Text("Son paylaşılan vital değerler")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.9))
                }
                Spacer()
                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.white.opacity(0.9))
            }
            HStack(spacing: 8) {
                MetricPill(title: "Ateş", value: String(format: "%.1f°C", latest?.bodyTemperature ?? 0))
                MetricPill(title: "Nabız", value: "\(latest?.heartRate ?? 0)")
                MetricPill(title: "SpO2", value: "\(latest?.oxygenSaturation ?? 0)%")
            }

            Button {
                Task {
                    guard let id = api.myProfile?.id else { return }
                    do {
                        try await api.fetchVitals(patientProfileId: id)
                    } catch {
                        screenError = "Vital kayıtları yenilenemedi: \(error.localizedDescription)"
                    }
                }
            } label: {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Yenile")
                }
                .font(.caption.bold())
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.2))
                .clipShape(Capsule())
            }
        }
        .padding(AppSpacing.xLarge)
        .background(LinearGradient.vitalGradient)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.xLarge))
        .shadow(color: InonuPalette.vitalRose.opacity(0.2), radius: 12, x: 0, y: 6)
    }

    private var displayedVitals: [VitalSign] {
        Array(api.vitals.prefix(showAllVitals ? 8 : 3))
    }
}
