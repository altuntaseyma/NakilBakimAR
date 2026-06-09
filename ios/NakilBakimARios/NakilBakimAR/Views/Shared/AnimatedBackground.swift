import SwiftUI

struct AnimatedBackground: View {
    var accentColor: Color = InonuPalette.primary
    @State private var canlandir = false
    @State private var nabiz = false

    var body: some View {
        ZStack {
            // Zemin gradyanı
            LinearGradient(
                colors: [
                    InonuPalette.pageTop.opacity(0.6),
                    InonuPalette.pageBottom,
                    accentColor.opacity(0.04)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Yüzen daire 1 — yavaş hareket
            Circle()
                .fill(accentColor.opacity(0.08))
                .frame(width: 240, height: 240)
                .blur(radius: 50)
                .offset(
                    x: canlandir ? -110 : -170,
                    y: canlandir ? 280 : 200
                )
                .scaleEffect(nabiz ? 1.05 : 0.95)

            // Yüzen daire 2
            Circle()
                .fill(InonuPalette.navySoft.opacity(0.06))
                .frame(width: 300, height: 300)
                .blur(radius: 60)
                .offset(
                    x: canlandir ? 150 : 190,
                    y: canlandir ? 380 : 290
                )

            // Yüzen daire 3 — dekoratif
            Circle()
                .fill(accentColor.opacity(0.05))
                .frame(width: 180, height: 180)
                .blur(radius: 35)
                .offset(
                    x: canlandir ? 50 : -30,
                    y: canlandir ? 540 : 590
                )
                .scaleEffect(nabiz ? 0.95 : 1.05)

            // Küçük parlak nokta
            Circle()
                .fill(Color.white.opacity(0.12))
                .frame(width: 80, height: 80)
                .blur(radius: 20)
                .offset(
                    x: canlandir ? 120 : 80,
                    y: canlandir ? -30 : 20
                )
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: 9)
                .repeatForever(autoreverses: true)
            ) {
                canlandir = true
            }
            withAnimation(
                .easeInOut(duration: 4)
                .repeatForever(autoreverses: true)
            ) {
                nabiz = true
            }
        }
    }
}
