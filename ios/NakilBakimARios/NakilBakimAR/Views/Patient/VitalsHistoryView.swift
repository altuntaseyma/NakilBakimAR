import SwiftUI

struct VitalsHistoryView: View {
    @EnvironmentObject var api: APIService

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Paylasilan Vital Bulgular", systemImage: "heart.text.square")
                .font(.headline)
            if api.vitals.isEmpty {
                Text("Paylasilan vital kaydi bulunamadi.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(api.vitals.prefix(3)) { vital in
                    HStack {
                        Text("Ates: \(vital.bodyTemperature ?? 0, specifier: "%.1f")")
                        Spacer()
                        Text("Nabiz: \(vital.heartRate ?? 0)")
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
