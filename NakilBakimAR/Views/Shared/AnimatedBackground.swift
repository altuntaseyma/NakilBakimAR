import SwiftUI

struct AnimatedBackground: View {
    @State private var pulse = false

    var body: some View {
        LinearGradient(
            colors: [Color(hex: "#5C0A2A"), Color(hex: "#8B1E3F"), Color(hex: "#F5E6C8")],
            startPoint: pulse ? .topLeading : .bottomTrailing,
            endPoint: pulse ? .bottomTrailing : .topLeading
        )
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: pulse)
        .onAppear { pulse = true }
    }
}
