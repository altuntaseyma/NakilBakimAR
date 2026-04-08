import SwiftUI

struct DashboardView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Bugun senin icin...")
                .font(.title3.bold())
            ModuleCard(title: "Mobilizasyon", icon: "figure.walk")
            ModuleCard(title: "Ilaclarim", icon: "pills.fill")
        }
        .padding()
        .background(.white.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
