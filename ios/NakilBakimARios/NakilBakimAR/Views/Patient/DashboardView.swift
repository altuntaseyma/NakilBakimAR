import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var api: APIService

    var body: some View {
        ZStack {
            AnimatedBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Bugun senin icin...")
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)
                    Text("Kisisel bakim planin, gorevlerin ve paylasilan vital sonuclarin burada.")
                        .foregroundStyle(.white.opacity(0.86))
                    phaseBanner
                    adherenceCard
                    reminderCard

                    if api.patientModules.filter(\.isEnabled).isEmpty {
                        Text("Henuz aktif modul atanmamis. Hemsiren aktif modul tanimladiginda bu alan otomatik dolacak.")
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.92))
                            .padding(12)
                            .background(.white.opacity(0.18))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    } else {
                        ForEach(api.patientModules.filter(\.isEnabled)) { module in
                            if module.name == "mobilization" || module.name == "medication" {
                                NavigationLink {
                                    ARExperienceView()
                                } label: {
                                    ModuleCard(
                                        title: moduleTitle(module.name),
                                        subtitle: moduleSubtitle(module.name),
                                        icon: moduleIcon(module.name)
                                    )
                                }
                                .buttonStyle(.plain)
                            } else {
                                ModuleCard(
                                    title: moduleTitle(module.name),
                                    subtitle: moduleSubtitle(module.name),
                                    icon: moduleIcon(module.name)
                                )
                            }
                        }
                    }
                    TaskListView(patientProfileId: api.myProfile?.id)
                    VitalsHistoryView()
                }
                .padding()
            }
        }
        .navigationTitle("Hasta Paneli")
        .task {
            do {
                try await api.fetchMyProfile()
                if let id = api.myProfile?.id {
                    async let t: Void = api.fetchTasks(patientProfileId: id)
                    async let v: Void = api.fetchVitals(patientProfileId: id)
                    async let m: Void = api.fetchMyModules()
                    async let s: Void = api.fetchScenarioSummary(patientProfileId: id)
                    _ = try await (t, v, m, s)
                }
            } catch {
                print("patient dashboard fetch error: \(error.localizedDescription)")
            }
        }
    }

    private func moduleTitle(_ raw: String) -> String {
        switch raw {
        case "mobilization": return "Mobilizasyon"
        case "nutrition": return "Beslenme"
        case "wound_care": return "Yara Bakimi"
        case "medication": return "Ilaclarim"
        case "vital_signs": return "Vital Bulgularim"
        default: return raw
        }
    }

    private func moduleSubtitle(_ raw: String) -> String {
        switch raw {
        case "mobilization": return "Yuruyus ve egzersiz planin"
        case "nutrition": return "Gunluk oneriler ve notlar"
        case "wound_care": return "Bakim adimlari ve kontrol noktasi"
        case "medication": return "Doz ve zamanlama takibi"
        case "vital_signs": return "Paylasilan olcumlerin"
        default: return "Kisisel modul"
        }
    }

    private func moduleIcon(_ raw: String) -> String {
        switch raw {
        case "mobilization": return "figure.walk"
        case "nutrition": return "fork.knife"
        case "wound_care": return "bandage.fill"
        case "medication": return "pills.fill"
        case "vital_signs": return "heart.text.square"
        default: return "square.grid.2x2"
        }
    }

    private var phaseBanner: some View {
        let postOp = api.myProfile?.carePhase == "post_op"
        return HStack {
            Image(systemName: postOp ? "cross.case.fill" : "stethoscope")
            Text(postOp ? "Post-op Takip Modu" : "Pre-op Hazirlik Modu")
                .font(.subheadline.bold())
            Spacer()
        }
        .padding(10)
        .foregroundStyle(.white)
        .background(postOp ? Color(hex: "#8B1E3F") : Color(hex: "#5C0A2A"))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var adherenceCard: some View {
        let summary = api.scenarioSummary
        return VStack(alignment: .leading, spacing: 6) {
            Label("Karar Uyum Analizi", systemImage: "chart.bar.xaxis")
                .font(.headline)
                .foregroundStyle(.white)
            HStack {
                metric("Basari", "\(summary?.successRate ?? 0)%")
                metric("Dogru", "\(summary?.correctDecisions ?? 0)")
                metric("Ortalama", "\(summary?.avgDurationSec ?? 0) sn")
            }
        }
        .padding(12)
        .background(.white.opacity(0.16))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var reminderCard: some View {
        let nutritionCount = api.tasks.filter { $0.type == "nutrition" && !$0.isCompleted }.count
        let medCount = api.tasks.filter { $0.type == "medication" && !$0.isCompleted }.count
        return VStack(alignment: .leading, spacing: 6) {
            Label("Bugunku Hatirlatmalar", systemImage: "bell.badge")
                .font(.headline)
                .foregroundStyle(.white)
            Text("Beslenme gorevi: \(nutritionCount) | Ilac gorevi: \(medCount)")
                .foregroundStyle(.white.opacity(0.95))
            Text("Su tuketimi ve ilac saatlerini aksatma.")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.85))
        }
        .padding(12)
        .background(Color(hex: "#8B1E3F").opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func metric(_ title: String, _ value: String) -> some View {
        VStack {
            Text(value).font(.headline).foregroundStyle(.white)
            Text(title).font(.caption).foregroundStyle(.white.opacity(0.85))
        }
        .frame(maxWidth: .infinity)
    }
}
