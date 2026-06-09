import SwiftUI

struct ModuleCard: View {
    let title: String
    let subtitle: String
    let icon: String
    var accentColor: Color = InonuPalette.primary
    var lightBg: Color = InonuPalette.cream
    var isInteractive: Bool = true
    @State private var isPressed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(accentColor.opacity(0.14))
                        .frame(width: 46, height: 46)
                    Image(systemName: icon)
                        .font(.title3.bold())
                        .foregroundStyle(accentColor)
                }
                Spacer()
                if isInteractive {
                    Image(systemName: "arrow.right")
                        .font(.caption.bold())
                        .foregroundStyle(accentColor.opacity(0.6))
                        .padding(8)
                        .background(Color.white.opacity(0.9))
                        .clipShape(Circle())
                }
            }
            Spacer(minLength: 2)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(InonuPalette.deepNavy)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            // Alt kenar accent çizgisi
            RoundedRectangle(cornerRadius: 2)
                .fill(accentColor.opacity(0.5))
                .frame(height: 3)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 150, alignment: .topLeading)
        .background(
            LinearGradient(
                colors: [Color.white, lightBg.opacity(0.5)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.large))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.large)
                .stroke(accentColor.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: accentColor.opacity(0.12), radius: 10, x: 0, y: 5)
    }
}
