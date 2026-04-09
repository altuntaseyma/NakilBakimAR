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
        NavigationStack {
            Form {
                Section("Vital Bulgular") {
                    TextField("Ates (36.7)", text: $temperature)
                        .keyboardType(.decimalPad)
                    TextField("Sistolik", text: $systolic)
                        .keyboardType(.numberPad)
                    TextField("Diastolik", text: $diastolic)
                        .keyboardType(.numberPad)
                    TextField("Nabiz", text: $heartRate)
                        .keyboardType(.numberPad)
                    TextField("Oksijen Saturasyonu", text: $oxygen)
                        .keyboardType(.numberPad)
                }

                Section("Notlar") {
                    TextField("Klinik not", text: $notes, axis: .vertical)
                        .lineLimit(3...5)
                    Toggle("Hastayla paylas", isOn: $sharedWithPatient)
                }

                Section("Kayit Zamani") {
                    Toggle("Tarih/Saat sec", isOn: $customRecordTime)
                    if customRecordTime {
                        DatePicker("Kayit zamani", selection: $recordDate)
                    }
                }

                if !errorText.isEmpty {
                    Section {
                        Text(errorText).foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Vital Ekle")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Iptal") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(loading ? "Kaydediliyor..." : "Kaydet") {
                        Task { await saveVital() }
                    }
                    .disabled(loading)
                }
            }
        }
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
