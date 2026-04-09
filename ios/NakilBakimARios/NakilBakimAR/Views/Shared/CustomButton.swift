import SwiftUI

struct CustomButtonStyle: ButtonStyle {
    var tint: Color = Color(hex: "#8B1E3F")

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity)
            .background(tint.opacity(configuration.isPressed ? 0.75 : 1))
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
