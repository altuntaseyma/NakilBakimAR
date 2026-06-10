import SwiftUI

struct ExerciseModuleView: View {
    @EnvironmentObject var api: APIService
    var isPushed: Bool = false
    @State private var localError = ""
    @State private var animateBreath = false
    @State private var completedBreathRepetitions = 0
    @State private var completedBreathSessions = 0
    @State private var showDetailedGuide = false

    private var pendingExerciseTasks: [TaskItem] {
        api.tasks.filter { $0.type == "exercise" && !$0.isCompleted }
    }

    private var completedExerciseCount: Int {
        api.tasks.filter { $0.type == "exercise" && $0.isCompleted }.count
    }

    var body: some View {
        ZStack {
            AnimatedBackground(accentColor: InonuPalette.exerciseBlue)
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    exerciseHeroCard
                    timelineStatusCard
                    breathingCard
                    exerciseStepsCard
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
        .navigationTitle("Egzersiz")
        .toolbar(isPushed ? .hidden : .automatic, for: .tabBar)
        .onAppear {
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                animateBreath = true
            }
        }
        .task {
            guard let id = api.myProfile?.id else { return }
            do {
                try await api.fetchTasks(patientProfileId: id)
            } catch {
                // Hata ortak API state uzerinden gosteriliyor.
            }
        }
    }

    // MARK: - Hero Card
    private var exerciseHeroCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Hareket & Solunum")
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                    Text(timeline?.statusTitle ?? "Rehabilitasyon planı")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.85))
                }
                Spacer()
                Image(systemName: "figure.walk")
                    .font(.system(size: 34))
                    .foregroundStyle(.white.opacity(0.9))
            }
            HStack(spacing: 8) {
                MetricPill(title: "Durum", value: timeline?.shortLabel ?? fallbackStatusLabel)
                MetricPill(title: "Bekleyen", value: "\(pendingExerciseTasks.count)")
                MetricPill(title: "Bitti", value: "\(completedExerciseCount)")
            }
        }
        .padding(AppSpacing.xLarge)
        .background(LinearGradient.exerciseGradient)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.xLarge))
        .shadow(color: InonuPalette.exerciseBlue.opacity(0.25), radius: 14, x: 0, y: 8)
    }

    // MARK: - Timeline Status
    private var timelineStatusCard: some View {
        SurfaceCard(accentColor: InonuPalette.exerciseBlue) {
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
                .foregroundStyle(InonuPalette.exerciseBlue)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(InonuPalette.exerciseBlue.opacity(0.1))
                .clipShape(Capsule())
            }
        }
    }

    // MARK: - Breathing Exercise
    private var breathingCard: some View {
        SurfaceCard {
            SectionCardTitle(text: "Nefes Egzersizi", icon: "wind", color: InonuPalette.exerciseBlue)

            HStack(spacing: 16) {
                // Animasyonlu nefes dairesi
                ZStack {
                    Circle()
                        .fill(InonuPalette.exerciseBlue.opacity(0.1))
                        .frame(width: 80, height: 80)
                        .scaleEffect(animateBreath ? 1.15 : 0.85)

                    Circle()
                        .stroke(InonuPalette.exerciseBlue.opacity(0.4), lineWidth: 2.5)
                        .frame(width: 80, height: 80)
                        .scaleEffect(animateBreath ? 1.25 : 0.75)

                    TimelineView(.periodic(from: .now, by: 4)) { context in
                        let cycle = Int(context.date.timeIntervalSinceReferenceDate / 4) % 2
                        VStack(spacing: 2) {
                            Image(systemName: cycle == 0 ? "arrow.down" : "arrow.up")
                                .font(.caption2)
                            Text(cycle == 0 ? "Al" : "Ver")
                                .font(.caption2.bold())
                        }
                        .foregroundStyle(InonuPalette.exerciseBlue)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(breathingSessionTarget)
                        .font(.subheadline.bold())
                        .foregroundStyle(InonuPalette.deepNavy)
                    Text("3-4 sn al, 2 sn tut, 4-6 sn ver")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            // Sayaçlar
            HStack(spacing: 10) {
                InfoMetric(title: "Tekrar", value: "\(completedBreathRepetitions)", tint: InonuPalette.exerciseBlue)
                InfoMetric(title: "Seans", value: "\(completedBreathSessions)", tint: InonuPalette.exerciseBlue)
                Spacer()
            }

            // Butonlar
            HStack(spacing: 10) {
                Button("+1 Tekrar") {
                    completedBreathRepetitions += 1
                }
                .buttonStyle(CustomButtonStyle(tint: InonuPalette.exerciseBlue, isSecondary: true))

                Button("Seansı Bitir") {
                    completedBreathSessions += 1
                }
                .buttonStyle(CustomButtonStyle(tint: InonuPalette.exerciseBlue))
            }
        }
    }

    // MARK: - Numbered Exercise Steps (Mockup Style)
    private var exerciseStepsCard: some View {
        SurfaceCard {
            SectionCardTitle(text: "Hareket Planı", icon: "list.number", color: InonuPalette.exerciseBlue)

            VStack(spacing: 0) {
                exerciseStep(number: 1, title: "Derin Nefes Egzersizi",
                             desc: "Sırt üstü uzanarak karnınızı şişirerek burundan nefes alın, ağızdan yavaşça verin.")
                exerciseStep(number: 2, title: "Ayak Bileği Pompası",
                             desc: "Dolaşımı artırmak için ayak bileklerinizi ritmik olarak hareket ettirin.")
                exerciseStep(number: 3, title: "Diz Bastırma",
                             desc: "Dizinizin arkasını yatağa bastırarak üst bacak kaslarınızı sıkın.")
            }

            if let plan = currentPlan.mobilization.first, !plan.isEmpty {
                Text("Güncel öneri: \(plan)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }
        }
    }

    private func exerciseStep(number: Int, title: String, desc: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(InonuPalette.exerciseBlue.opacity(0.12))
                    .frame(width: 36, height: 36)
                Text("\(number)")
                    .font(.subheadline.bold())
                    .foregroundStyle(InonuPalette.exerciseBlue)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundStyle(InonuPalette.deepNavy)
                Text(desc)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 10)
    }

    // MARK: - Task Card
    private var taskCard: some View {
        SurfaceCard {
            HStack {
                SectionCardTitle(text: "Egzersiz Görevleri", icon: "checklist", color: InonuPalette.exerciseBlue)
                Spacer()
                NavigationLink {
                    ARExperienceView(mode: .mobilization)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arkit")
                        Text("AR")
                    }
                    .font(.caption.bold())
                    .foregroundStyle(InonuPalette.exerciseBlue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(InonuPalette.exerciseBlue.opacity(0.1))
                    .clipShape(Capsule())
                }
            }

            if pendingExerciseTasks.isEmpty {
                Text("Aktif egzersiz görevi yok.")
                    .font(AppTypography.helper)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(pendingExerciseTasks.prefix(4)) { task in
                    HStack(spacing: 10) {
                        Image(systemName: "circle")
                            .foregroundStyle(InonuPalette.exerciseBlue)
                            .frame(width: 20)
                        Text(task.title)
                            .font(.subheadline)
                        Spacer()
                        if let patientId = api.myProfile?.id {
                            Button("Tamamla") {
                                Task {
                                    do {
                                        try await api.completeTask(taskId: task.id, patientProfileId: patientId)
                                    } catch {
                                        localError = "Görev tamamlanamadı: \(error.localizedDescription)"
                                    }
                                }
                            }
                            .font(.caption.bold())
                            .foregroundStyle(InonuPalette.exerciseBlue)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Detailed Care Guide (Collapsible)
    private var detailedCareGuide: some View {
        VStack(spacing: 12) {
            careGuideSection("Preoperatif Hazırlık", icon: "clipboard", items: [
                "NPO: Katılar 6-8 saat, berrak sıvılar 2-4 saat önce kesilir.",
                "Solunum egzersizi tekniği ameliyat öncesi öğretilir.",
                "Enfeksiyon odakları taranır."
            ])

            careGuideSection("Post-op Bakım Planı", icon: "list.bullet.rectangle", items: currentPlan.mobilization + currentPlan.woundCare.prefix(2))

            careGuideSection("Kırmızı Bayraklar", icon: "exclamationmark.triangle.fill", items: [
                "38°C üzeri ateş, halsizlik, sarılık",
                "Yara yerinde kızarıklık/kötü koku",
                "Nefes darlığı veya şiddetli ağrı"
            ], tint: InonuPalette.danger)
        }
    }

    private func careGuideSection(_ title: String, icon: String, items: [String], tint: Color = InonuPalette.exerciseBlue) -> some View {
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
        case .preOp:
            return "Pre-op: Ameliyat öncesi eğitim ve nefes pratiği."
        case .day1:
            return "Kritik faz: Saatlik monitörizasyon, yatak içi hareket."
        case .day2to3:
            return "Erken toparlanma: Yardımla oturma/yürüme."
        case .day4to7:
            return "Servis fazı: Koridor yürüyüşleri, drenlerin azalması."
        case .week1to4:
            return "Taburculuk: Evde güvenli aktivite ve yürüyüş planı."
        }
    }

    private var breathingSessionTarget: String {
        switch selectedPhase {
        case .preOp:      return "Günde 3 deneme seansı"
        case .day1, .day2to3: return "Saatlik 10 tekrar"
        case .day4to7:    return "Günlük 8-10 seans"
        case .week1to4:   return "Günde 80+ nefes"
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

    private var currentPlan: PostOpCarePlan {
        postOpPlans.first(where: { $0.phase == selectedPhase }) ?? postOpPlans.last!
    }

    private var postOpPlans: [PostOpCarePlan] {
        [
            PostOpCarePlan(phase: .preOp,
                mobilization: ["Solunum egzersizi tekniği öğretilir.", "Yatak içi güvenli hareket eğitimi verilir."],
                woundCare: ["Cilt hazırlığı ve giriş bölgeleri bilgilendirilir.", "Enfeksiyon taraması tamamlanır."]),
            PostOpCarePlan(phase: .day1,
                mobilization: ["Yatak içi pasif ROM egzersizleri.", "Yatak başı 30-45 derece tutulur."],
                woundCare: ["Pansuman açılmaz; dış sızıntı kontrolü yapılır.", "Dren miktarı saatlik kaydedilir."]),
            PostOpCarePlan(phase: .day2to3,
                mobilization: ["Yardımla yatak kenarına oturma.", "Hemşire eşliğinde oda içi yürüyüş."],
                woundCare: ["İlk steril pansuman değişimi yapılabilir.", "Yara değerlendirmesi yapılır."]),
            PostOpCarePlan(phase: .day4to7,
                mobilization: ["Günde 3-4 kez koridor yürüyüşü.", "SpO2 izlenerek süre artırılır."],
                woundCare: ["Dren çıkışı azaldıkça çekim planlanır.", "Yara kuru ve temiz tutulur."]),
            PostOpCarePlan(phase: .week1to4,
                mobilization: ["Ağır kaldırma yok; yürüyüş süresi artırılır.", "Nefes darlığı/ağrıda dur ve bildir."],
                woundCare: ["Yara yeri günlük kontrol edilir.", "Poliklinik kontrolleri aksatılmaz."])
        ]
    }
}

private struct PostOpCarePlan {
    let phase: PostOpPhase
    let mobilization: [String]
    let woundCare: [String]
}
