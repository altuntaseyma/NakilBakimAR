import SwiftUI

struct NutritionModuleView: View {
    @EnvironmentObject var api: APIService
    var isPushed: Bool = false
    @State private var localError = ""
    @State private var waterIntakeMl = 800
    @State private var showDetailedGuide = false
    
    private let dailyGoalMl = 2000
    
    private var nutritionTasks: [TaskItem] {
        api.tasks.filter { $0.type == "nutrition" }
    }
    
    private var pendingTasks: [TaskItem] {
        nutritionTasks.filter { !$0.isCompleted }
    }
    
    private var waterProgress: Double {
        min(Double(waterIntakeMl) / Double(dailyGoalMl), 1)
    }
    
    var body: some View {
        ZStack {
            AnimatedBackground(accentColor: InonuPalette.nutritionOrange)
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    nutritionHeroCard
                    timelineStatusCard
                    waterTrackingCard
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
        .navigationTitle("Beslenme")
        .toolbar(isPushed ? .hidden : .automatic, for: .tabBar)
        .task {
            guard let id = api.myProfile?.id else { return }
            do {
                try await api.fetchTasks(patientProfileId: id)
            } catch {
                // Hata mesajı ortak API state üzerinden ele alınıyor
            }
        }
    }
    
    // MARK: - Hero Card
    private var nutritionHeroCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Beslenme & Hidratasyon")
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                    Text(timeline?.statusTitle ?? "Diyet ve su takibi")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.85))
                }
                Spacer()
                Image(systemName: "fork.knife")
                    .font(.system(size: 34))
                    .foregroundStyle(.white.opacity(0.9))
            }
            HStack(spacing: 8) {
                MetricPill(title: "Durum", value: timeline?.shortLabel ?? fallbackStatusLabel)
                MetricPill(title: "Bekleyen", value: "\(pendingTasks.count)")
                MetricPill(title: "Su", value: "\(Int(waterProgress * 100))%")
            }
        }
        .padding(AppSpacing.xLarge)
        .background(LinearGradient.nutritionGradient)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.xLarge))
        .shadow(color: InonuPalette.nutritionOrange.opacity(0.25), radius: 14, x: 0, y: 8)
    }

    // MARK: - Timeline Status
    private var timelineStatusCard: some View {
        SurfaceCard(accentColor: preOpFastingColor) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(preOpFastingTitle ?? (timeline?.statusTitle ?? "Ameliyat tarihi bekleniyor"))
                        .font(.subheadline.bold())
                        .foregroundStyle(preOpFastingMessage != nil ? preOpFastingColor : InonuPalette.deepNavy)
                    Text(preOpFastingMessage ?? dayFocusLine)
                        .font(AppTypography.helper)
                        .foregroundStyle(preOpFastingMessage != nil ? preOpFastingColor.opacity(0.8) : .secondary)
                }
                Spacer()
                Button(showDetailedGuide ? "Gizle" : "Detay") {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        showDetailedGuide.toggle()
                    }
                }
                .font(.caption.bold())
                .foregroundStyle(preOpFastingColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(preOpFastingColor.opacity(0.1))
                .clipShape(Capsule())
            }
        }
    }

    // MARK: - Water Tracking
    private var waterTrackingCard: some View {
        SurfaceCard {
            SectionCardTitle(text: "Su Takibi", icon: "drop.fill", color: InonuPalette.nutritionOrange)
            
            HStack(spacing: 16) {
                // Su çemberi grafiği
                ZStack {
                    Circle()
                        .stroke(InonuPalette.nutritionOrange.opacity(0.15), lineWidth: 8)
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(waterProgress))
                        .stroke(InonuPalette.nutritionOrange, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: waterProgress)
                    
                    VStack(spacing: 0) {
                        Image(systemName: "drop.fill")
                            .font(.caption2)
                        Text("%\(Int(waterProgress * 100))")
                            .font(.subheadline.bold())
                    }
                    .foregroundStyle(InonuPalette.nutritionOrange)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Hedef: \(dailyGoalMl / 1000) Litre")
                        .font(.subheadline.bold())
                        .foregroundStyle(InonuPalette.deepNavy)
                    Text("İçilen: \(String(format: "%.1f", Double(waterIntakeMl) / 1000)) L")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            
            // Butonlar
            HStack(spacing: 10) {
                Button(action: {
                    withAnimation { waterIntakeMl = max(0, waterIntakeMl - 200) }
                }) {
                    Image(systemName: "minus")
                        .frame(width: 44, height: 44)
                        .background(InonuPalette.nutritionOrange.opacity(0.1))
                        .foregroundStyle(InonuPalette.nutritionOrange)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium))
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    withAnimation { waterIntakeMl = min(dailyGoalMl, waterIntakeMl + 200) }
                }) {
                    Text("+ 1 Bardak (200ml)")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(CustomButtonStyle(tint: InonuPalette.nutritionOrange, isSecondary: false))
            }
            .padding(.top, 4)
        }
    }

    // MARK: - Task Card
    private var taskCard: some View {
        SurfaceCard {
            SectionCardTitle(text: "Beslenme Planı", icon: "checklist", color: InonuPalette.nutritionOrange)
            
            if pendingTasks.isEmpty {
                Text(nutritionTasks.isEmpty ? "Aktif beslenme görevi yok." : "Tüm görevler tamamlandı!")
                    .font(AppTypography.helper)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(pendingTasks.prefix(4)) { task in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(InonuPalette.nutritionOrange.opacity(0.15))
                            .frame(width: 32, height: 32)
                            .overlay(Text("\(nutritionTasks.firstIndex(where: { $0.id == task.id })! + 1)").font(.caption.bold()).foregroundStyle(InonuPalette.nutritionOrange))
                            
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
                            .foregroundStyle(InonuPalette.nutritionOrange)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(InonuPalette.nutritionOrange.opacity(0.1))
                            .clipShape(Capsule())
                        }
                    }
                }
            }
        }
    }

    // MARK: - Detailed Care Guide (Collapsible)
    private var detailedCareGuide: some View {
        VStack(spacing: 12) {
            careGuideSection("Gıda Güvenliği & Yasaklar", icon: "exclamationmark.shield", items: [
                "İmmünosupresif etkileşim: Greyfurt ve nar KESİNLİKLE YASAK.",
                "Çiğ/iyi pişmemiş et ve şarküteri ürünlerinden kaçının.",
                "Alkol tüketimi yasaktır."
            ], tint: InonuPalette.danger)

            careGuideSection("Diyet Planı", icon: "list.bullet.rectangle", items: currentPlan.dietItems)

            careGuideSection("İzlem Parametreleri", icon: "stethoscope", items: currentPlan.monitoringItems)
        }
    }

    private func careGuideSection(_ title: String, icon: String, items: [String], tint: Color = InonuPalette.nutritionOrange) -> some View {
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
    private var preOpFastingTitle: String? {
        guard let tl = timeline, selectedPhase == .preOp else { return nil }
        let hours = tl.hoursUntilSurgery
        if hours <= 8 {
            return "Ameliyata \(hours) Saat Kaldı"
        }
        return nil
    }

    private var preOpFastingMessage: String? {
        guard let tl = timeline, selectedPhase == .preOp else { return nil }
        let hours = tl.hoursUntilSurgery
        if hours <= 2 {
            return "⚠️ KESİN NPO: Su dahil HİÇBİR ŞEY yiyip içmeyiniz. Ameliyat çok yakın!"
        } else if hours <= 8 {
            return "⚠️ AMELİYAT YAKLAŞIYOR: Katı gıdalar tamamen yasaktır. Sadece 2 saat kalaya kadar berrak su içebilirsiniz."
        }
        return nil
    }

    private var preOpFastingColor: Color {
        guard let tl = timeline, selectedPhase == .preOp else { return InonuPalette.nutritionOrange }
        let hours = tl.hoursUntilSurgery
        if hours <= 2 {
            return InonuPalette.danger
        } else if hours <= 8 {
            return InonuPalette.warning
        }
        return InonuPalette.nutritionOrange
    }
    private var dayFocusLine: String {
        switch selectedPhase {
        case .preOp: return "Pre-op: NPO hazırlığı ve yemek kesintisi."
        case .day1: return "Post-op 1: NPO, oral alım yasak."
        case .day2to3: return "Post-op 2-3: Su yudumlama ve berrak sivilara geçiş."
        case .day4to7: return "Post-op 4-7: Karaciğer koruyucu oral diyet."
        case .week1to4: return "Taburculuk: Düşük sodyum, dengeli protein diyet."
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

    private var currentPlan: NutritionCarePlan {
        let plans = nutritionPlans
        if let matched = plans.first(where: { $0.phase == selectedPhase }) {
            return matched
        }
        return plans.last!
    }

    private var nutritionPlans: [NutritionCarePlan] {
        [
            NutritionCarePlan(phase: .preOp,
                              dietItems: ["Katılar 6-8 saat önce, sıvılar 2-4 saat önce kesilir."],
                              fluidItems: ["Gerekirse bağırsak hazırlığı yapılır."],
                              monitoringItems: ["Ameliyat öncesi eğitim teyit edilir."]),
            NutritionCarePlan(phase: .day1,
                              dietItems: ["Kesin NPO (oral alım yok)."],
                              fluidItems: ["TPN ve IV sıvılar verilir.", "Saatlik sıvı takibi."],
                              monitoringItems: ["Bulantı/kusma izlenir."]),
            NutritionCarePlan(phase: .day2to3,
                              dietItems: ["Sadece su yudumlama ve berrak sıvı."],
                              fluidItems: ["Oral intoleransta IV destek."],
                              monitoringItems: ["Gaz/gaita çıkışı izlenir."]),
            NutritionCarePlan(phase: .day4to7,
                              dietItems: ["Karaciğer koruyucu, az tuzlu, kontrollü oral diyet."],
                              fluidItems: ["Ödem takibi için tartı izlemi."],
                              monitoringItems: ["Diyet toleransı sorgulanır."]),
            NutritionCarePlan(phase: .week1to4,
                              dietItems: ["Çiğ gıda yasak. Düzenli ve az tuzlu öğünler."],
                              fluidItems: ["Günlük sıvı tüketimi not edilir."],
                              monitoringItems: ["Ateş, bulantı, iştahsızlık takip edilir."])
        ]
    }
}

private struct NutritionCarePlan {
    let phase: PostOpPhase
    let dietItems: [String]
    let fluidItems: [String]
    let monitoringItems: [String]
}
