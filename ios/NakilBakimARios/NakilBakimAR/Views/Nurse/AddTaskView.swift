import SwiftUI

struct AddTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var api: APIService

    let patient: PatientProfile

    @State private var type = "exercise"
    @State private var title = ""
    @State private var description = ""
    @State private var includeDate = false
    @State private var scheduledDate = Date()
    @State private var loading = false
    @State private var errorText = ""

    private let taskTypes = ["exercise", "medication", "nutrition", "wound_care"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Gorev Bilgileri") {
                    Picker("Tip", selection: $type) {
                        ForEach(taskTypes, id: \.self) { Text($0) }
                    }
                    TextField("Baslik", text: $title)
                    TextField("Aciklama", text: $description, axis: .vertical)
                        .lineLimit(3...5)
                }

                Section("Zamanlama") {
                    Toggle("Planli tarih ekle", isOn: $includeDate)
                    if includeDate {
                        DatePicker("Tarih", selection: $scheduledDate)
                    }
                }

                if !errorText.isEmpty {
                    Section {
                        Text(errorText).foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Gorev Ata")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Iptal") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(loading ? "Kaydediliyor..." : "Kaydet") {
                        Task { await saveTask() }
                    }
                    .disabled(loading || title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func saveTask() async {
        loading = true
        defer { loading = false }
        do {
            let iso = includeDate ? ISO8601DateFormatter().string(from: scheduledDate) : nil
            try await api.createTask(
                patientProfileId: patient.id,
                type: type,
                title: title,
                description: description,
                scheduledAtISO: iso
            )
            dismiss()
        } catch {
            errorText = "Gorev kaydedilemedi: \(error.localizedDescription)"
        }
    }
}
