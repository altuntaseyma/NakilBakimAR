import SwiftUI

struct CustomButtonStyle: ButtonStyle {
    var tint: Color = InonuPalette.primary
    var isSecondary: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .padding(.vertical, 14)
            .padding(.horizontal, AppSpacing.large)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 48)
            .background(
                Group {
                    if isSecondary {
                        RoundedRectangle(cornerRadius: AppRadius.medium)
                            .fill(tint.opacity(0.08))
                    } else {
                        LinearGradient(
                            colors: [
                                tint.opacity(configuration.isPressed ? 0.78 : 1.0),
                                tint.opacity(configuration.isPressed ? 0.62 : 0.82)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    }
                }
            )
            .foregroundStyle(isSecondary ? tint : .white)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.medium)
                    .stroke(
                        isSecondary ? tint.opacity(0.25) : Color.white.opacity(0.2),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: isSecondary ? .clear : tint.opacity(configuration.isPressed ? 0.08 : 0.25),
                radius: configuration.isPressed ? 4 : 12,
                x: 0,
                y: configuration.isPressed ? 2 : 6
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
