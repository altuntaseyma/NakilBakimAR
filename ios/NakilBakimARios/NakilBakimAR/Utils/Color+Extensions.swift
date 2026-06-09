import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Ana Palet
enum InonuPalette {
    // Ana marka renkleri — belirgin kontrast
    static let primary     = Color(hex: "#0D9B8A")   // koyu teal — ana aksiyonlar
    static let secondary   = Color(hex: "#5BB5A9")   // açık teal — ikincil öğeler
    static let deepNavy    = Color(hex: "#0A2E3C")   // gerçek lacivert — başlıklar
    static let navySoft    = Color(hex: "#1A4B5C")   // yumuşak lacivert — alt başlıklar

    // Sayfa arka planları
    static let cream       = Color(hex: "#F0F7F5")
    static let card        = Color(hex: "#FFFFFF")
    static let pageTop     = Color(hex: "#E8F4F1")
    static let pageBottom  = Color(hex: "#F8FBFA")
    static let cardBorder  = Color(hex: "#E2EBE8")

    // Durum renkleri
    static let success     = Color(hex: "#2E7D32")
    static let danger      = Color(hex: "#C62828")
    static let warning     = Color(hex: "#E65100")
    static let info        = Color(hex: "#0277BD")

    // Modül-özel renkler — her modül ayırt edilebilir
    static let exerciseBlue    = Color(hex: "#1976D2")   // Egzersiz & Mobilizasyon
    static let exerciseLight   = Color(hex: "#E3F2FD")
    static let nutritionOrange = Color(hex: "#E67E22")   // Beslenme
    static let nutritionLight  = Color(hex: "#FFF3E0")
    static let medicationPurple = Color(hex: "#7B1FA2")  // İlaç
    static let medicationLight  = Color(hex: "#F3E5F5")
    static let woundCoral      = Color(hex: "#D84315")   // Yara Bakımı
    static let woundLight      = Color(hex: "#FBE9E7")
    static let vitalRose       = Color(hex: "#C2185B")   // Vital Bulgular
    static let vitalLight      = Color(hex: "#FCE4EC")
}

// MARK: - Spacing
enum AppSpacing {
    static let xSmall: CGFloat  = 4
    static let small: CGFloat   = 8
    static let medium: CGFloat  = 12
    static let large: CGFloat   = 16
    static let xLarge: CGFloat  = 24
    static let xxLarge: CGFloat = 32
}

// MARK: - Corner Radius
enum AppRadius {
    static let small: CGFloat  = 10
    static let medium: CGFloat = 14
    static let large: CGFloat  = 18
    static let xLarge: CGFloat = 24
}

// MARK: - Typography
enum AppTypography {
    static let pageTitle    = Font.title3.bold()
    static let sectionTitle = Font.headline
    static let body         = Font.subheadline
    static let caption      = Font.caption
    static let helper       = Font.footnote
    static let heroTitle    = Font.title.bold()
    static let heroBigStat  = Font.system(size: 48, weight: .bold, design: .rounded)
}

// MARK: - Shadow
enum AppShadow {
    static let card   = Color.black.opacity(0.06)
    static let button = InonuPalette.primary.opacity(0.20)
    static let hero   = Color.black.opacity(0.15)
}

// MARK: - Gradient Presetleri
extension LinearGradient {
    static var primaryAction: LinearGradient {
        LinearGradient(
            colors: [InonuPalette.primary, InonuPalette.navySoft],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var exerciseGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "#1565C0"), Color(hex: "#42A5F5")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var nutritionGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "#E65100"), Color(hex: "#FFA726")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var medicationGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "#6A1B9A"), Color(hex: "#AB47BC")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var woundGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "#BF360C"), Color(hex: "#FF7043")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var vitalGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "#AD1457"), Color(hex: "#F06292")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var dashboardGradient: LinearGradient {
        LinearGradient(
            colors: [InonuPalette.deepNavy, InonuPalette.primary],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var nurseGradient: LinearGradient {
        LinearGradient(
            colors: [InonuPalette.deepNavy, InonuPalette.navySoft],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Glass Input Modifier
struct GlassInputModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, AppSpacing.medium)
            .padding(.vertical, 13)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.medium)
                    .fill(Color.white.opacity(0.92))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.medium)
                    .stroke(InonuPalette.cardBorder, lineWidth: 1)
            )
    }
}

extension View {
    func glassInputField() -> some View {
        modifier(GlassInputModifier())
    }
}
