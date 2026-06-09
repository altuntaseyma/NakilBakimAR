import SwiftUI

struct AddVitalView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var api: APIService

    let patient: PatientProfile

    @State private var temperature = ""
    @State private var systolic = ""
    @State private var diastolic = ""
    @State private var heartRate = ""
    @State private var oxygen = ""
    @State private var notes = ""
    @State private var sharedWithPatient = true
    @State private var customRecordTime = false
    @State private var recordDate = Date()
    @State private var loading = false
    @State private var errorText = ""

    var body: some View {
        ZStack {
            AnimatedBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.large) {
                    GlassTopBar(
                        title: "Vital Ekle",
                        subtitle: patient.fullName ?? "Hasta vital girisi",
                        icon: "waveform.path.ecg"
                    )

                    SurfaceCard {
                        SectionCardTitle(text: "Vital Bulgular", icon: "waveform.path.ecg")
                        TextField("Ates (36.7)", text: $temperature)
                            .keyboardType(.decimalPad)
                            .glassInputField()
                        HStack(spacing: AppSpacing.small) {
                            TextField("Sistolik", text: $systolic)
                                .keyboardType(.numberPad)
                                .glassInputField()
                            TextField("Diastolik", text: $diastolic)
                                .keyboardType(.numberPad)
                                .glassInputField()
                        }
                        HStack(spacing: AppSpacing.small) {
                            TextField("Nabız", text: $heartRate)
                                .keyboardType(.numberPad)
                                .glassInputField()
                            TextField("SpO2", text: $oxygen)
                                .keyboardType(.numberPad)
                                .glassInputField()
                        }
                    }

                    SurfaceCard {
                        SectionCardTitle(text: "Notlar", icon: "note.text")
                        TextField("Klinik not", text: $notes, axis: .vertical)
                            .lineLimit(3...5)
                            .glassInputField()
                        Toggle("Hastayla paylas", isOn: $sharedWithPatient)
                    }

                    SurfaceCard {
                        SectionCardTitle(text: "Kayit Zamani", icon: "clock.badge.checkmark")
                        Toggle("Tarih/Saat sec", isOn: $customRecordTime)
                        if customRecordTime {
                            DatePicker("Kayit zamani", selection: $recordDate)
                        }
                    }

                    if !errorText.isEmpty {
                        SurfaceCard {
                            Label(errorText, systemImage: "exclamationmark.triangle.fill")
                                .font(AppTypography.helper)
                                .foregroundStyle(InonuPalette.danger)
                        }
                    }

                    HStack(spacing: AppSpacing.medium) {
                        Button("Iptal") { dismiss() }
                            .buttonStyle(CustomButtonStyle(tint: InonuPalette.deepNavy, isSecondary: true))
                        Button(loading ? "Kaydediliyor..." : "Kaydet") {
                            Task { await saveVital() }
                        }
                        .disabled(loading || areAllInputsEmpty)
                        .buttonStyle(CustomButtonStyle())
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Vital Ekle")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var areAllInputsEmpty: Bool {
        [temperature, systolic, diastolic, heartRate, oxygen]
            .allSatisfy { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    private func saveVital() async {
        loading = true
        defer { loading = false }
        do {
            let recordedAtISO = customRecordTime ? ISO8601DateFormatter().string(from: recordDate) : nil
            try await api.createVital(
                patientProfileId: patient.id,
                bodyTemperature: Double(temperature),
                systolic: Int(systolic),
                diastolic: Int(diastolic),
                heartRate: Int(heartRate),
                oxygen: Int(oxygen),
                notes: notes,
                sharedWithPatient: sharedWithPatient,
                recordedAtISO: recordedAtISO
            )
            dismiss()
        } catch {
            errorText = "Vital kaydi olusturulamadi: \(error.localizedDescription)"
        }
    }
}
