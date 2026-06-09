import SwiftUI

@main
struct NakilBakimARApp: App {
    @StateObject private var api = APIService()

    var body: some Scene {
        WindowGroup {
            LoginView()
                .environmentObject(api)
                .preferredColorScheme(.light)
        }
    }
}
