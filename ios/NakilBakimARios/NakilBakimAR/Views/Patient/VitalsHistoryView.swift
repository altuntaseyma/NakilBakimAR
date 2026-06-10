import SwiftUI

struct VitalsHistoryView: View {
    @EnvironmentObject var api: APIService

    var body: some View {
        SurfaceCard {
            SectionCardTitle(text: "Paylaşılan Vital Bulgular", icon: "heart.text.square")
            if api.vitalsLoading && api.vitals.isEmpty {
                ProgressView("Vital kayıtları yükleniyor...")
            } else if api.vitals.isEmpty {
                Text("Paylaşılan vital kaydı bulunamadı.")
                    .font(AppTypography.helper)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(api.vitals.prefix(3)) { vital in
                    VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                        HStack {
                            Text("Ateş: \(vital.bodyTemperature ?? 0, specifier: "%.1f")")
                            Spacer()
                            Text("Nabız: \(vital.heartRate ?? 0)")
                        }
                        HStack {
                            Text("TA: \(vital.bloodPressureSystolic ?? 0)/\(vital.bloodPressureDiastolic ?? 0)")
                            Spacer()
                            Text("SpO2: \(vital.oxygenSaturation ?? 0)%")
                        }
                        if let recordedAt = vital.recordedAt, !recordedAt.isEmpty {
                            Text(recordedAt.formatIsoDate())
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }
}
