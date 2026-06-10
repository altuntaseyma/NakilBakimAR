import SwiftUI

struct TabBarView: View {
    @EnvironmentObject var api: APIService
    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.96)
        appearance.shadowColor = UIColor.black.withAlphaComponent(0.06)
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(InonuPalette.primary)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(InonuPalette.primary),
            .font: UIFont.systemFont(ofSize: 10, weight: .semibold)
        ]
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.secondaryLabel
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.secondaryLabel,
            .font: UIFont.systemFont(ofSize: 10, weight: .medium)
        ]
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        TabView(selection: $api.selectedPatientTab) {
            if api.currentUser?.role == "nurse" {
                NavigationStack { PatientList() }
                    .tabItem { Label("Hastalar", systemImage: "person.3.fill") }
                    .tag(0)

                NavigationStack { NotificationsView() }
                    .tabItem { Label("Bildirimler", systemImage: "bell.badge.fill") }
                    .tag(1)
            } else {
                // Hasta tarafı
                NavigationStack { DashboardView() }
                    .tabItem { Label("Ana Sayfa", systemImage: "house.fill") }
                    .tag(0)

                NavigationStack { MedicationModuleView() }
                    .tabItem { Label("İlaç", systemImage: "pills.fill") }
                    .tag(1)

                NavigationStack { ExerciseModuleView() }
                    .tabItem { Label("Egzersiz", systemImage: "figure.walk") }
                    .tag(2)

                NavigationStack { NutritionModuleView() }
                    .tabItem { Label("Beslenme", systemImage: "fork.knife") }
                    .tag(3)

                NavigationStack { NotificationsView() }
                    .tabItem { Label("Bildirimler", systemImage: "bell.badge.fill") }
                    .tag(4)
            }
        }
        .tint(InonuPalette.primary)
        .task {
            guard api.currentUser?.role == "patient" else { return }
            do {
                try await api.fetchMyProfile()
                if let id = api.myProfile?.id {
                    async let m: Void = api.fetchMyModules()
                    async let t: Void = api.fetchTasks(patientProfileId: id)
                    async let v: Void = api.fetchVitals(patientProfileId: id)
                    _ = try await (m, t, v)
                }
            } catch {
                // Ekranlar ortak hata state'ini kendi kartlarinda gosteriyor.
            }
        }
    }
}
