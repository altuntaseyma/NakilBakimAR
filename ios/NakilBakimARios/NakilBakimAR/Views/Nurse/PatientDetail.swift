import SwiftUI

struct PatientDetail: View {
    @EnvironmentObject var api: APIService
    let patient: PatientProfile
    @State private var showAddTask = false
    @State private var showAddVital = false
    @State private var modulesLoading = false
    @State private var timelineLoading = false
    @State private var operationDate = Date()
    @State private var hasOperationDate = false
    @State private var opSaving = false
    @State private var screenError = ""

    var body: some View {
        ZStack {
            AnimatedBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    nurseDetailHero
                    
                    // Pre-op / Post-op Switcher & Date
                    operationStatusCard
                    
                    // Modül Kontrolleri Grid
                    moduleSwitchersCard
                    
                    // Son Aktiviteler (Timeline)
                    recentActivitiesCard

                    if !screenError.isEmpty {
                        SurfaceCard {
                            Label(screenError, systemImage: "exclamationmark.triangle.fill")
                                .font(AppTypography.helper)
                                .foregroundStyle(InonuPalette.danger)
                        }
                    }
                    
                    Spacer(minLength: 40) // Bottom padding for FABs
                }
                .padding()
            }
        }
        .navigationTitle("Hasta Detayı")
        .navigationBarTitleDisplayMode(.inline)
        .overlay(alignment: .bottom) {
            floatingActionButtons
        }
        .sheet(isPresented: $showAddTask, onDismiss: refreshTimeline) {
            AddTaskView(patient: patient).environmentObject(api)
        }
        .sheet(isPresented: $showAddVital, onDismiss: refreshTimeline) {
            AddVitalView(patient: patient).environmentObject(api)
        }
        .task {
            if let transplantDate = patient.transplantDate,
               let parsed = ISO8601DateFormatter().date(from: transplantDate) {
                operationDate = parsed
                hasOperationDate = true
            } else {
                hasOperationDate = false
            }
            modulesLoading = true
            do { try await api.fetchPatientModules(patientProfileId: patient.id) } catch {}
            modulesLoading = false
            
            await refreshTimeline()
        }
    }

    // MARK: - Initial Loading Actions
    private func refreshTimeline() {
        Task {
            timelineLoading = true
            defer { timelineLoading = false }
            do {
                async let t: Void = api.fetchTasks(patientProfileId: patient.id)
                async let v: Void = api.fetchVitals(patientProfileId: patient.id)
                _ = try await (t, v)
            } catch {
                screenError = "Takvim verileri yüklenemedi: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Hero
    private var nurseDetailHero: some View {
        let isPostOp = patient.carePhase == "post_op"
        return HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.8))
                    .frame(width: 60, height: 60)
                if let unwrapName = patient.fullName, let first = unwrapName.first {
                    Text(String(first))
                        .font(.title2.bold())
                        .foregroundStyle(InonuPalette.deepNavy)
                } else {
                    Image(systemName: "person.fill")
                        .foregroundStyle(InonuPalette.secondary)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(patient.fullName ?? "İsimsiz Hasta")
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                Text("ID: \(String(patient.id.uuidString.suffix(6)))")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
            }
            
            Spacer()
            
            VStack {
                Text(currentPhaseLabel.uppercased())
                    .font(.caption2.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(isPostOp ? InonuPalette.primary : InonuPalette.info)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
        }
        .padding(16)
        .background(LinearGradient.nurseGradient)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.large))
        .shadow(color: InonuPalette.deepNavy.opacity(0.2), radius: 10, x: 0, y: 5)
    }

    // MARK: - Operation Status
    private var operationStatusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("DURUM YÖNETİMİ")
                .font(.caption.bold())
                .tracking(1.0)
                .foregroundStyle(.secondary)
            
            SurfaceCard {
                HStack(spacing: 0) {
                    Button(action: { Task { await applyPreset(preOp: true) } }) {
                        Text("PRE-OP")
                            .font(.caption.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(!hasOperationDate || operationDate > Date() ? Color.white : Color.clear)
                            .foregroundStyle(!hasOperationDate || operationDate > Date() ? InonuPalette.deepNavy : .secondary)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .shadow(color: !hasOperationDate || operationDate > Date() ? AppShadow.card : .clear, radius: 2, x: 0, y: 1)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: { Task { await applyPreset(preOp: false) } }) {
                        Text("POST-OP")
                            .font(.caption.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(hasOperationDate && operationDate <= Date() ? Color.white : Color.clear)
                            .foregroundStyle(hasOperationDate && operationDate <= Date() ? InonuPalette.primary : .secondary)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .shadow(color: hasOperationDate && operationDate <= Date() ? AppShadow.card : .clear, radius: 2, x: 0, y: 1)
                    }
                    .buttonStyle(.plain)
                }
                .padding(4)
                .background(InonuPalette.cream)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("AMELİYAT TARİHİ VE SAATİ")
                        .font(.caption.bold())
                        .foregroundStyle(InonuPalette.deepNavy)
                    
                    Toggle("Tarih Girildi", isOn: $hasOperationDate)
                        .font(.subheadline)
                    
                    if hasOperationDate {
                        DatePicker("", selection: $operationDate)
                            .labelsHidden()
                            .datePickerStyle(.compact)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    Button(opSaving ? "Kaydediliyor..." : "Durumu Kaydet") {
                        Task { await saveOperationState() }
                    }
                    .disabled(opSaving)
                    .font(.caption.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(InonuPalette.cream)
                    .foregroundStyle(InonuPalette.deepNavy)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .padding(.top, 8)
            }
        }
    }

    // MARK: - Module Switchers Grid
    private var moduleSwitchersCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("MODÜL KONTROLLERİ")
                .font(.caption.bold())
                .tracking(1.0)
                .foregroundStyle(.secondary)
            
            if modulesLoading {
                ProgressView()
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(api.patientModules.indices, id: \.self) { idx in
                        let mod = api.patientModules[idx]
                        let style = ModuleStyleMap.style(for: mod.name)
                        
                        // Toggle Card
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                ZStack {
                                    Circle()
                                        .fill(style.lightBg)
                                        .frame(width: 36, height: 36)
                                    Image(systemName: style.icon)
                                        .foregroundStyle(style.accent)
                                }
                                Spacer()
                                Toggle("", isOn: Binding(
                                    get: { api.patientModules[idx].isEnabled },
                                    set: { newValue in
                                        api.patientModules[idx].isEnabled = newValue
                                        Task {
                                            do {
                                                try await api.updatePatientModules(
                                                    patientProfileId: patient.id,
                                                    modules: api.patientModules
                                                )
                                            } catch {
                                                screenError = "Modüller güncellenemedi: \(error.localizedDescription)"
                                            }
                                        }
                                    }
                                ))
                                .labelsHidden()
                                .tint(InonuPalette.primary)
                            }
                            Text(style.title)
                                .font(.subheadline.bold())
                                .foregroundStyle(mod.isEnabled ? InonuPalette.deepNavy : .secondary)
                        }
                        .padding(14)
                        .background(Color.white.opacity(0.95))
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium))
                        .overlay(RoundedRectangle(cornerRadius: AppRadius.medium).stroke(InonuPalette.cardBorder, lineWidth: 1))
                        .shadow(color: AppShadow.card, radius: 4, x: 0, y: 2)
                        .opacity(mod.isEnabled ? 1.0 : 0.6)
                    }
                }
            }
        }
    }

    // MARK: - Son Aktiviteler (Timeline)
    private var recentActivitiesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SON AKTİVİTELER")
                .font(.caption.bold())
                .tracking(1.0)
                .foregroundStyle(.secondary)
            
            if timelineLoading {
                ProgressView()
            } else if api.tasks.isEmpty && api.vitals.isEmpty {
                Text("Kayıtlı aktivite bulunmuyor.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 0) {
                    // Combine Tasks and Vitals and take first 5
                    let combinedItems = buildTimelineItems()
                    ForEach(Array(combinedItems.enumerated()), id: \.offset) { index, item in
                        timelineRow(item: item, isLast: index == combinedItems.count - 1)
                    }
                }
            }
        }
    }

    // MARK: - Floating Action Buttons
    private var floatingActionButtons: some View {
        HStack(spacing: 12) {
            Button {
                showAddTask = true
            } label: {
                HStack {
                    Image(systemName: "checklist.badge.badge.plus")
                    Text("Görev Ekle")
                }
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(Color.white)
                .foregroundStyle(InonuPalette.deepNavy)
                .clipShape(Capsule())
                .shadow(color: AppShadow.card, radius: 10, x: 0, y: 4)
            }
            
            Button {
                showAddVital = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Vital Ekle")
                }
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(InonuPalette.primary)
                .foregroundStyle(.white)
                .clipShape(Capsule())
                .shadow(color: InonuPalette.primary.opacity(0.3), radius: 10, x: 0, y: 4)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }

    // MARK: - Timeline Helpers
    struct TimelineItem: Identifiable {
        let id = UUID()
        let type: ItemType
        let title: String
        let desc: String
        let timeLabel: String
        let color: Color
        
        enum ItemType {
            case vital
            case taskPending
            case taskDone
        }
    }

    private func buildTimelineItems() -> [TimelineItem] {
        var items: [TimelineItem] = []
        
        // Vitals
        for v in api.vitals.prefix(3) {
            let bp = "\(v.bloodPressureSystolic ?? 0)/\(v.bloodPressureDiastolic ?? 0)"
            let hr = "\(v.heartRate ?? 0)"
            items.append(TimelineItem(
                type: .vital,
                title: "Vital Veri Karşılandı",
                desc: "TA: \(bp) mmHg, Nabız: \(hr) bpm",
                timeLabel: v.recordedAt ?? "",
                color: InonuPalette.vitalRose
            ))
        }
        
        // Tasks
        for t in api.tasks.prefix(3) {
            items.append(TimelineItem(
                type: t.isCompleted ? .taskDone : .taskPending,
                title: t.isCompleted ? "Görev Tamamlandı" : "Bekleyen Görev",
                desc: t.title,
                timeLabel: t.completedAt ?? t.scheduledTime ?? "",
                color: t.isCompleted ? InonuPalette.success : InonuPalette.navySoft
            ))
        }
        
        // Return 5 max
        return Array(items.prefix(5))
    }

    private func timelineRow(item: TimelineItem, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            // Line & Dot
            VStack(spacing: 0) {
                Circle()
                    .fill(item.color)
                    .frame(width: 12, height: 12)
                    .padding(.top, 4)
                
                if !isLast {
                    Rectangle()
                        .fill(InonuPalette.cardBorder)
                        .frame(width: 2)
                        .padding(.top, 4)
                }
            }
            .frame(width: 20)
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .top) {
                    Text(item.title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(item.color)
                    Spacer()
                    Text(item.timeLabel)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Text(item.desc)
                    .font(.subheadline)
                    .foregroundStyle(InonuPalette.deepNavy)
                
                if !isLast { Spacer().frame(height: 16) }
            }
        }
        .padding(.horizontal, 8)
        .background(Color.white.opacity(0.01)) // tap target if needed
    }

    // MARK: - Actions
    private func saveOperationState() async {
        opSaving = true
        defer { opSaving = false }
        let iso = hasOperationDate ? ISO8601DateFormatter().string(from: operationDate) : nil
        do {
            try await api.updatePatientOperation(patientId: patient.id, transplantDateISO: iso)
        } catch {
            screenError = "Operasyon durumu güncellenemedi: \(error.localizedDescription)"
        }
    }

    private func applyPreset(preOp: Bool) async {
        hasOperationDate = !preOp // basit mantık: post op seçilince tarih atarız
        if !preOp && operationDate > Date() {
            operationDate = Date()
        }
        await saveOperationState()
        
        var updated = api.patientModules
        for i in updated.indices {
            switch updated[i].name {
            case "mobilization", "nutrition":
                updated[i].isEnabled = true
            case "medication", "wound_care", "vital_signs":
                updated[i].isEnabled = !preOp
            default:
                break
            }
        }
        do {
            try await api.updatePatientModules(patientProfileId: patient.id, modules: updated)
        } catch {
            screenError = "Preset uygulanamadı: \(error.localizedDescription)"
        }
    }
    
    private var currentPhaseLabel: String {
        guard hasOperationDate else { return "Pre-op" }
        return operationDate <= Date() ? "Post-op" : "Pre-op"
    }
}
