import SwiftUI

struct TabBarView: View {
    @EnvironmentObject var api: APIService

    var body: some View {
        TabView {
            if api.currentUser?.role == "nurse" {
                NavigationStack { PatientList() }
                    .tabItem { Label("Hastalar", systemImage: "person.3.fill") }
            } else {
                NavigationStack { DashboardView() }
                    .tabItem { Label("Panel", systemImage: "house.fill") }
            }

            NavigationStack { ARExperienceView() }
                .tabItem { Label("AR", systemImage: "arkit") }
        }
    }
}
