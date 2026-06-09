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
        ZStack {
            AnimatedBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.large) {
                    GlassTopBar(
                        title: "Gorev Ata",
                        subtitle: patient.fullName ?? "Hasta gorev planlamasi",
                        icon: "checklist"
                    )

                    SurfaceCard {
                        SectionCardTitle(text: "Gorev Bilgileri", icon: "checklist")
                        Picker("Tip", selection: $type) {
                            ForEach(taskTypes, id: \.self) { raw in
                                Text(displayType(raw)).tag(raw)
                            }
                        }
                        .pickerStyle(.segmented)

                        TextField("Baslik", text: $title)
                            .glassInputField()

                        TextField("Aciklama", text: $description, axis: .vertical)
                            .lineLimit(3...5)
                            .glassInputField()
                    }

                    SurfaceCard {
                        SectionCardTitle(text: "Zamanlama", icon: "calendar.badge.clock")
                        Toggle("Planli tarih ekle", isOn: $includeDate)
                        if includeDate {
                            DatePicker("Tarih", selection: $scheduledDate)
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
                            Task { await saveTask() }
                        }
                        .disabled(loading || isTitleInvalid)
                        .buttonStyle(CustomButtonStyle())
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Gorev Ata")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var isTitleInvalid: Bool {
        title.trimmingCharacters(in: .whitespacesAndNewlines).count < 3
    }

    private func displayType(_ raw: String) -> String {
        switch raw {
        case "exercise": return "Egzersiz"
        case "medication": return "Ilac"
        case "nutrition": return "Beslenme"
        case "wound_care": return "Yara Bakımı"
        default: return raw
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
