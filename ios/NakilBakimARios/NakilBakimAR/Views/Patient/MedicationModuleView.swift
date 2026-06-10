import SwiftUI

struct MedicationModuleView: View {
    @EnvironmentObject var api: APIService
    var isPushed: Bool = false
    @State private var localError = ""
    @State private var showDetailedGuide = false

    // e-Nabız
    @State private var showEnabizSheet = false
    @State private var enabizLoading = false
    @State private var enabizMedications: [EnabizMedication] = []

    private var medicationTasks: [TaskItem] {
        api.tasks.filter { $0.type == "medication" }
    }

    private var pendingTasks: [TaskItem] {
        medicationTasks.filter { !$0.isCompleted }
    }

    var body: some View {
        ZStack {
            AnimatedBackground(accentColor: InonuPalette.medicationPurple)
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    medicationHeroCard
                    enabizCard
                    timelineStatusCard
                    nextDoseCard
                    taskCard

                    if showDetailedGuide {
                        detailedCareGuide
                    }

                    if !localError.isEmpty {
                        SurfaceCard(accentColor: InonuPalette.danger) {
                            Label(localError, systemImage: "exclamationmark.triangle.fill")
                                .font(AppTypography.helper)
                                .foregroundStyle(InonuPalette.danger)
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("İlaçlarım")
        .toolbar(isPushed ? .hidden : .automatic, for: .tabBar)
        .sheet(isPresented: $showEnabizSheet) {
            EnabizSheet(medications: enabizMedications)
        }
        .task {
            enabizMedications = EnabizMedication.mockList(for: api.myProfile?.fullName)
            guard let id = api.myProfile?.id else { return }
            do {
                try await api.fetchTasks(patientProfileId: id)
            } catch {
                // Hata mesajı ortak API state üzerinden ele alınıyor
            }
        }
    }

    // MARK: - Hero Card
    private var medicationHeroCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("İlaç Takibi")
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                    Text(timeline?.statusTitle ?? "Doz ve zamanlama")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.85))
                }
                Spacer()
                Image(systemName: "pills.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(.white.opacity(0.9))
            }
            HStack(spacing: 8) {
                MetricPill(title: "Durum", value: timeline?.shortLabel ?? fallbackStatusLabel)
                MetricPill(title: "Bekleyen", value: "\(pendingTasks.count)")
                MetricPill(title: "Tamamlanan", value: "\(medicationTasks.filter(\.isCompleted).count)")
            }
        }
        .padding(AppSpacing.xLarge)
        .background(LinearGradient.medicationGradient)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.xLarge))
        .shadow(color: InonuPalette.medicationPurple.opacity(0.25), radius: 14, x: 0, y: 8)
    }

    // MARK: - e-Nabız Card
    private var enabizCard: some View {
        SurfaceCard {
            HStack(spacing: 14) {
                // e-Nabız logosu
                if let logoImg = UIImage(named: "e-nabiz-logo") {
                    Image(uiImage: logoImg)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 48, height: 48)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.18, green: 0.52, blue: 0.85),
                                        Color(red: 0.13, green: 0.38, blue: 0.72)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 48, height: 48)
                        Image(systemName: "cross.case.fill")
                            .font(.title3)
                            .foregroundStyle(.white)
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text("e-Nabız")
                            .font(.headline.bold())
                            .foregroundStyle(Color(red: 0.13, green: 0.38, blue: 0.72))
                        Text("Entegrasyonu")
                            .font(.headline)
                            .foregroundStyle(InonuPalette.deepNavy)
                    }
                    Text("Reçete edilen ilaçlarınızı görüntüleyin")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    enabizLoading = true
                    // Simüle: kısa bekleme ile yükleniyor animasyonu
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        enabizLoading = false
                        showEnabizSheet = true
                    }
                } label: {
                    if enabizLoading {
                        ProgressView()
                            .tint(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Color(red: 0.18, green: 0.52, blue: 0.85))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    } else {
                        Text("Getir")
                            .font(.subheadline.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Color(red: 0.18, green: 0.52, blue: 0.85))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Timeline Status
    private var timelineStatusCard: some View {
        SurfaceCard(accentColor: InonuPalette.medicationPurple) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(timeline?.statusTitle ?? "Ameliyat tarihi bekleniyor")
                        .font(.subheadline.bold())
                        .foregroundStyle(InonuPalette.deepNavy)
                    Text(dayFocusLine)
                        .font(AppTypography.helper)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button(showDetailedGuide ? "Gizle" : "Detay") {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        showDetailedGuide.toggle()
                    }
                }
                .font(.caption.bold())
                .foregroundStyle(InonuPalette.medicationPurple)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(InonuPalette.medicationPurple.opacity(0.1))
                .clipShape(Capsule())
            }
        }
    }

    // MARK: - Next Dose Card
    private var nextDoseCard: some View {
        SurfaceCard {
            SectionCardTitle(text: "Sıradaki İlaç", icon: "bell.badge.fill", color: InonuPalette.medicationPurple)
            
            if let nextTask = pendingTasks.first {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(InonuPalette.medicationPurple.opacity(0.12))
                            .frame(width: 50, height: 50)
                        Image(systemName: "pill.fill")
                            .font(.title2)
                            .foregroundStyle(InonuPalette.medicationPurple)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(nextTask.title)
                            .font(.headline)
                            .foregroundStyle(InonuPalette.deepNavy)
                        if let desc = nextTask.description {
                            Text(desc)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("Doz zamanı geldiğinde alınız.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                }
                .padding(.vertical, 4)
                
                if let patientId = api.myProfile?.id {
                    Button(action: {
                        Task {
                            do {
                                try await api.completeTask(taskId: nextTask.id, patientProfileId: patientId)
                            } catch {
                                localError = "Görev tamamlanamadı: \(error.localizedDescription)"
                            }
                        }
                    }) {
                        Text("İlacı Aldım")
                    }
                    .buttonStyle(CustomButtonStyle(tint: InonuPalette.medicationPurple))
                }
            } else {
                Text(medicationTasks.isEmpty ? "Aktif ilaç görevi bulunmuyor." : "Tüm ilaçlar alındı!")
                    .font(AppTypography.helper)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Task List Card
    private var taskCard: some View {
        SurfaceCard {
            HStack {
                SectionCardTitle(text: "Günlük İlaç Planı", icon: "checklist", color: InonuPalette.medicationPurple)
                Spacer()
                NavigationLink {
                    ARExperienceView(mode: .medication)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arkit")
                        Text("AR")
                    }
                    .font(.caption.bold())
                    .foregroundStyle(InonuPalette.medicationPurple)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(InonuPalette.medicationPurple.opacity(0.1))
                    .clipShape(Capsule())
                }
            }
            
            if medicationTasks.isEmpty {
                Text("Bu modül için görev tanımlı değil.")
                    .font(AppTypography.helper)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(medicationTasks.enumerated()), id: \.element.id) { index, task in
                        HStack(spacing: 12) {
                            // Timeline bar
                            VStack(spacing: 0) {
                                Circle()
                                    .fill(task.isCompleted ? InonuPalette.success : InonuPalette.medicationPurple.opacity(0.3))
                                    .frame(width: 12, height: 12)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: 2)
                                    )
                                if index != medicationTasks.count - 1 {
                                    Rectangle()
                                        .fill(InonuPalette.cardBorder)
                                        .frame(width: 2)
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(task.title)
                                    .font(.subheadline)
                                    .strikethrough(task.isCompleted)
                                    .foregroundStyle(task.isCompleted ? .secondary : InonuPalette.deepNavy)
                            }
                            .padding(.vertical, 10)
                            Spacer()
                            
                            if task.isCompleted {
                                Image(systemName: "checkmark")
                                    .font(.caption.bold())
                                    .foregroundStyle(InonuPalette.success)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Detailed Care Guide (Collapsible)
    private var detailedCareGuide: some View {
        VStack(spacing: 12) {
            careGuideSection("İlaç Güvenliği", icon: "exclamationmark.shield", items: [
                "İmmünosupresanlar (Takrolimus vb.) hayatidir, milimi milimine saatinde alınmalıdır.",
                "Doz unutulursa veya kusulursa ÇİFT DOZ ALMAYIN, hekime başvurun.",
                "Tremor, yüksek ateş veya bilinç değişikliğinde acile başvurun."
            ], tint: InonuPalette.danger)

            careGuideSection("İlaç Planı", icon: "list.bullet.rectangle", items: currentPlan.coreItems + currentPlan.prophylaxisItems)

            careGuideSection("Takip Edilecekler", icon: "stethoscope", items: currentPlan.monitoringItems)
        }
    }

    private func careGuideSection(_ title: String, icon: String, items: [String], tint: Color = InonuPalette.medicationPurple) -> some View {
        SurfaceCard(accentColor: tint) {
            DisclosureGroup {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(items, id: \.self) { item in
                        HStack(alignment: .top, spacing: 8) {
                            Circle()
                                .fill(tint.opacity(0.5))
                                .frame(width: 5, height: 5)
                                .padding(.top, 7)
                            Text(item)
                                .font(AppTypography.helper)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.top, 8)
            } label: {
                Label(title, systemImage: icon)
                    .font(.subheadline.bold())
                    .foregroundStyle(InonuPalette.deepNavy)
            }
            .tint(tint)
        }
    }

    // MARK: - Computed Properties
    private var dayFocusLine: String {
        switch selectedPhase {
        case .preOp: return "Pre-op: Kanama profilaksisi ve antikoagülan düzeni."
        case .day1: return "Post-op 1: IV analjezi, geniş spektrumlu antibiyotik."
        case .day2to3: return "Post-op 2-3: İmmünosupresan düzeyi izlemi."
        case .day4to7: return "Post-op 4-7: IV'den oral ilaç formatına geçiş."
        case .week1to4: return "Taburculuk: Saatlik ilaç uyumu ve kontrol."
        }
    }

    private var selectedPhase: PostOpPhase {
        PostOpPhase(dayOffset: timeline?.dayOffset, carePhaseHint: api.myProfile?.carePhase)
    }

    private var timeline: SurgeryTimeline? {
        SurgeryTimeline.parse(iso: api.myProfile?.transplantDate)
    }

    private var fallbackStatusLabel: String {
        api.myProfile?.carePhase == "post_op" ? "Post-op" : "Pre-op"
    }

    private var currentPlan: MedicationCarePlan {
        let plans = medicationPlans
        if let matched = plans.first(where: { $0.phase == selectedPhase }) {
            return matched
        }
        return plans.last!
    }

    private var medicationPlans: [MedicationCarePlan] {
        [
            MedicationCarePlan(phase: .preOp,
                               coreItems: ["Antikoagülanlar kesilir/düzenlenir."],
                               prophylaxisItems: ["Profilaktik antibiyotik başlanır."],
                               monitoringItems: ["Koagülasyon parametreleri izlenir."]),
            MedicationCarePlan(phase: .day1,
                               coreItems: ["IV Takrolimus/Siklosporin + kortikosteroid."],
                               prophylaxisItems: ["Geniş spektrum antibiyotik."],
                               monitoringItems: ["Saatlik vital ve idrar takibi."]),
            MedicationCarePlan(phase: .day2to3,
                               coreItems: ["İmmünosupresif doz ayarı (vadi düzeyine göre)."],
                               prophylaxisItems: ["Antifungal/antiviral koruyucu."],
                               monitoringItems: ["Böbrek fonksiyonları yakın izlenir."]),
            MedicationCarePlan(phase: .day4to7,
                               coreItems: ["Oral immünosupresanlara geçiş yapılır."],
                               prophylaxisItems: ["Profilaksi klinik duruma göre devam."],
                               monitoringItems: ["Tremor/hiperglisemi takibi."]),
            MedicationCarePlan(phase: .week1to4,
                               coreItems: ["İlaçlar SIFIR HATA ile saatinde alınmalı."],
                               prophylaxisItems: ["Aşı ve enfeksiyon önlemleri koordinasyonu."],
                               monitoringItems: ["Poliklinik kontrolleri ve kan düzeyi izlemi."])
        ]
    }
}

private struct MedicationCarePlan {
    let phase: PostOpPhase
    let coreItems: [String]
    let prophylaxisItems: [String]
    let monitoringItems: [String]
}

// MARK: - e-Nabız Data Model

struct EnabizMedication: Identifiable {
    let id = UUID()
    let name: String
    let dose: String
    let frequency: String
    let timeSlots: [String]
    let category: String
    let icon: String
    let color: Color
    var isTakenToday: Bool = false

    static func mockList(for patientName: String?) -> [EnabizMedication] {
        [
            EnabizMedication(
                name: "Takrolimus (Prograf)",
                dose: "2 mg",
                frequency: "Günde 2 kez",
                timeSlots: ["08:00", "20:00"],
                category: "İmmünosupresan",
                icon: "pill.fill",
                color: Color(red: 0.55, green: 0.25, blue: 0.85)
            ),
            EnabizMedication(
                name: "Mikofenolat Mofetil (CellCept)",
                dose: "1000 mg",
                frequency: "Günde 2 kez",
                timeSlots: ["08:00", "20:00"],
                category: "İmmünosupresan",
                icon: "capsule.fill",
                color: Color(red: 0.45, green: 0.20, blue: 0.75)
            ),
            EnabizMedication(
                name: "Prednizolon",
                dose: "5 mg",
                frequency: "Günde 1 kez",
                timeSlots: ["08:00"],
                category: "Kortikosteroid",
                icon: "pill.circle.fill",
                color: Color(red: 0.22, green: 0.52, blue: 0.85)
            ),
            EnabizMedication(
                name: "Valgansiklovir (Valcyte)",
                dose: "450 mg",
                frequency: "Günde 1 kez",
                timeSlots: ["12:00"],
                category: "Antiviral",
                icon: "shield.fill",
                color: Color(red: 0.18, green: 0.72, blue: 0.55)
            ),
            EnabizMedication(
                name: "Trimetoprim/Sulfametoksazol",
                dose: "160/800 mg",
                frequency: "Haftada 3 kez",
                timeSlots: ["10:00"],
                category: "Antibiyotik Profilaksi",
                icon: "cross.fill",
                color: Color(red: 0.92, green: 0.55, blue: 0.20)
            ),
            EnabizMedication(
                name: "Omeprazol",
                dose: "20 mg",
                frequency: "Günde 1 kez",
                timeSlots: ["07:30"],
                category: "Mide Koruyucu",
                icon: "heart.fill",
                color: Color(red: 0.85, green: 0.30, blue: 0.30)
            ),
        ]
    }
}

// MARK: - e-Nabız Sheet View

struct EnabizSheet: View {
    let medications: [EnabizMedication]
    @State private var takenStates: [UUID: Bool] = [:]
    @Environment(\.dismiss) private var dismiss

    private var nowHour: Int { Calendar.current.component(.hour, from: Date()) }
    private var todayString: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "tr_TR")
        f.dateFormat = "d MMMM yyyy, EEEE"
        return f.string(from: Date())
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.96, green: 0.97, blue: 1.0).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        // Üst banner
                        enabizHeader

                        // İlaç listesi
                        VStack(spacing: 12) {
                            ForEach(medications) { med in
                                medicationRow(med)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)

                        // Uyarı notu
                        warningNote
                            .padding(.horizontal, 16)
                            .padding(.top, 20)
                            .padding(.bottom, 32)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") { dismiss() }
                        .font(.subheadline.bold())
                        .foregroundStyle(Color(red: 0.18, green: 0.52, blue: 0.85))
                }
            }
        }
    }

    // MARK: - Header

    private var enabizHeader: some View {
        VStack(spacing: 0) {
            // e-Nabız mavi gradient üst kısım
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.18, green: 0.52, blue: 0.85),
                        Color(red: 0.10, green: 0.35, blue: 0.70)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                VStack(spacing: 10) {
                    HStack(spacing: 10) {
                        Image(systemName: "cross.case.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("e-Nabız")
                                .font(.title2.bold())
                                .foregroundStyle(.white)
                            Text("Reçeteli İlaç Listesi")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.85))
                        }
                        Spacer()
                        // Bağlantı durumu pill
                        HStack(spacing: 5) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 7, height: 7)
                            Text("Bağlı")
                                .font(.caption.bold())
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.white.opacity(0.2))
                        .clipShape(Capsule())
                    }

                    // Tarih satırı
                    HStack {
                        Image(systemName: "calendar")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.8))
                        Text(todayString)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.85))
                        Spacer()
                        Text("\(medications.count) ilaç")
                            .font(.caption.bold())
                            .foregroundStyle(.white.opacity(0.9))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Medication Row

    private func medicationRow(_ med: EnabizMedication) -> some View {
        let taken = takenStates[med.id] ?? false
        let nextDose = nextDoseTime(for: med)

        return VStack(spacing: 0) {
            HStack(spacing: 14) {
                // İkon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(med.color.opacity(taken ? 0.08 : 0.13))
                        .frame(width: 50, height: 50)
                    Image(systemName: med.icon)
                        .font(.title3)
                        .foregroundStyle(taken ? med.color.opacity(0.4) : med.color)
                }

                // Bilgi
                VStack(alignment: .leading, spacing: 3) {
                    Text(med.name)
                        .font(.subheadline.bold())
                        .foregroundStyle(taken ? .secondary : Color(red: 0.10, green: 0.15, blue: 0.30))
                        .strikethrough(taken)
                        .lineLimit(2)

                    HStack(spacing: 6) {
                        Text(med.dose)
                            .font(.caption.bold())
                            .foregroundStyle(med.color.opacity(taken ? 0.5 : 1.0))
                        Text("•")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(med.category)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    // Saat satırı
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.caption2)
                            .foregroundStyle(nextDose.isUrgent ? Color.orange : .secondary)
                        Text(nextDose.label)
                            .font(.caption)
                            .foregroundStyle(nextDose.isUrgent ? Color.orange : .secondary)
                    }
                }

                Spacer()

                // Alındı toggle
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        takenStates[med.id] = !taken
                    }
                    let g = UIImpactFeedbackGenerator(style: .medium)
                    g.impactOccurred()
                } label: {
                    ZStack {
                        Circle()
                            .fill(taken
                                ? Color(red: 0.18, green: 0.72, blue: 0.44)
                                : Color.gray.opacity(0.15)
                            )
                            .frame(width: 36, height: 36)
                        Image(systemName: taken ? "checkmark" : "circle")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(taken ? .white : .gray)
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(14)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(taken
                        ? Color(red: 0.18, green: 0.72, blue: 0.44).opacity(0.35)
                        : Color.clear,
                        lineWidth: 1.5
                    )
            )
        }
    }

    // MARK: - Warning Note

    private var warningNote: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Color.orange)
                .font(.subheadline)
                .padding(.top, 1)
            Text("İmmünosupresanlar (Takrolimus vb.) sıfır hata ile saatinde alınmalıdır. Doz unutulursa veya kusulursa ÇİFT DOZ ALMAYIN, hekiminize başvurun.")
                .font(.caption)
                .foregroundStyle(Color(red: 0.45, green: 0.30, blue: 0.0))
        }
        .padding(14)
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Helpers

    private struct DoseInfo {
        let label: String
        let isUrgent: Bool
    }

    private func nextDoseTime(for med: EnabizMedication) -> DoseInfo {
        let cal = Calendar.current
        let now = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"

        for slot in med.timeSlots {
            if let slotDate = formatter.date(from: slot) {
                var comps = cal.dateComponents([.hour, .minute], from: slotDate)
                comps.year = cal.component(.year, from: now)
                comps.month = cal.component(.month, from: now)
                comps.day = cal.component(.day, from: now)
                if let fullDate = cal.date(from: comps), fullDate > now {
                    let diff = fullDate.timeIntervalSince(now)
                    let mins = Int(diff / 60)
                    if mins < 60 {
                        return DoseInfo(label: "\(mins) dk sonra — \(slot)", isUrgent: true)
                    }
                    return DoseInfo(label: "Sıradaki: \(slot)", isUrgent: false)
                }
            }
        }
        // Tüm dozlar geçti
        return DoseInfo(label: "Bugünkü dozlar tamamlandı", isUrgent: false)
    }
}
