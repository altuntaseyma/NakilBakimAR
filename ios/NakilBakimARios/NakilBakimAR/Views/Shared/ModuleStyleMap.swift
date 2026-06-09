import SwiftUI

struct ModuleStyle {
    let title: String
    let subtitle: String
    let icon: String
    let accent: Color
    let lightBg: Color
    let gradient: LinearGradient
}

enum ModuleStyleMap {
    static func style(for key: String) -> ModuleStyle {
        switch key {
        case "mobilization":
            return ModuleStyle(
                title: "Egzersiz & Hareket",
                subtitle: "Yuruyus ve solunum plani",
                icon: "figure.walk",
                accent: InonuPalette.exerciseBlue,
                lightBg: InonuPalette.exerciseLight,
                gradient: .exerciseGradient
            )
        case "nutrition":
            return ModuleStyle(
                title: "Beslenme",
                subtitle: "Diyet ve hidratasyon",
                icon: "fork.knife",
                accent: InonuPalette.nutritionOrange,
                lightBg: InonuPalette.nutritionLight,
                gradient: .nutritionGradient
            )
        case "wound_care":
            return ModuleStyle(
                title: "Yara Bakimi",
                subtitle: "Pansuman ve kontrol",
                icon: "bandage.fill",
                accent: InonuPalette.woundCoral,
                lightBg: InonuPalette.woundLight,
                gradient: .woundGradient
            )
        case "medication":
            return ModuleStyle(
                title: "Ilaclarim",
                subtitle: "Doz ve zamanlama",
                icon: "pills.fill",
                accent: InonuPalette.medicationPurple,
                lightBg: InonuPalette.medicationLight,
                gradient: .medicationGradient
            )
        case "vital_signs":
            return ModuleStyle(
                title: "Vital Bulgular",
                subtitle: "Nabiz, tansiyon, ates",
                icon: "heart.text.square",
                accent: InonuPalette.vitalRose,
                lightBg: InonuPalette.vitalLight,
                gradient: .vitalGradient
            )
        default:
            return ModuleStyle(
                title: key,
                subtitle: "Kisisel modul",
                icon: "square.grid.2x2",
                accent: InonuPalette.primary,
                lightBg: InonuPalette.cream,
                gradient: .primaryAction
            )
        }
    }
}
