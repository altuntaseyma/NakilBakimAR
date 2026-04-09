import SwiftUI

struct PatientDetail: View {
    @EnvironmentObject var api: APIService
    let patient: PatientProfile
    @State private var showAddTask = false
    @State private var showAddVital = false
    @State private var modulesLoading = false
    @State private var timelineLoading = false
    @State private var operationDate = Date()
    @State private var isPostOp = false
    @State private var opSaving = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(patient.fullName ?? "Isimsiz Hasta")
                    .font(.title2.bold())

                GroupBox("Hasta Bilgileri") {
                    VStack(alignment: .leading, spacing: 8) {
                        detailRow("Email", patient.email ?? "-")
                        detailRow("Tani", patient.diagnosis ?? "Belirtilmedi")
                        detailRow("Nakil", isPostOp ? "Post-op" : "Pre-op")
                        detailRow("Aktif", patient.isActive ? "Evet" : "Hayir")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                GroupBox("Operasyon Durumu") {
                    VStack(spacing: 10) {
                        Toggle("Post-op olarak isaretle", isOn: $isPostOp)
                        if isPostOp {
                            DatePicker("Operasyon Tarih/Saati", selection: $operationDate)
                        } else {
                            Text("Pre-op secildiginde operasyon tarihi temizlenir.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        Button(opSaving ? "Kaydediliyor..." : "Durumu Kaydet") {
                            Task { await saveOperationState() }
                        }
                        .disabled(opSaving)
                        .buttonStyle(CustomButtonStyle(tint: Color(hex: "#5C0A2A")))
                    }
                }

                GroupBox("Bakim Modulleri") {
                    if modulesLoading && api.patientModules.isEmpty {
                        ProgressView("Moduller yukleniyor...")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        VStack(spacing: 10) {
                            HStack(spacing: 8) {
                                Button("Pre-op Preset") {
                                    Task { await applyPreset(preOp: true) }
                                }
                                .buttonStyle(CustomButtonStyle(tint: Color(hex: "#5C0A2A")))

                                Button("Post-op Preset") {
                                    Task { await applyPreset(preOp: false) }
                                }
                                .buttonStyle(CustomButtonStyle(tint: Color(hex: "#8B1E3F")))
                            }

                            ForEach(api.patientModules.indices, id: \.self) { idx in
                                Toggle(moduleTitle(api.patientModules[idx].name), isOn: Binding(
                                    get: { api.patientModules[idx].isEnabled },
                                    set: { newValue in
                                        api.patientModules[idx].isEnabled = newValue
                                        Task {
                                            try? await api.updatePatientModules(
                                                patientProfileId: patient.id,
                                                modules: api.patientModules
                                            )
                                        }
                                    }
                                ))
                            }
                        }
                    }
                }

                HStack(spacing: 10) {
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        showAddTask = true
                    } label: {
                        Label("Gorev Ata", systemImage: "checklist")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(CustomButtonStyle())

                    Button {
                        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                        showAddVital = true
                    } label: {
                        Label("Vital Ekle", systemImage: "waveform.path.ecg")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(CustomButtonStyle(tint: Color(hex: "#B57C1D")))
                }

                GroupBox("Gorevler") {
                    if timelineLoading && api.tasks.isEmpty {
                        ProgressView("Gorevler yukleniyor...")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else if api.tasks.isEmpty {
                        Text("Bu hasta icin gorev yok.")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        VStack(spacing: 8) {
                            ForEach(api.tasks.prefix(5)) { task in
                                HStack {
                                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "clock")
                                        .foregroundStyle(task.isCompleted ? .green : .orange)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(task.title).font(.subheadline.bold())
                                        Text(task.type).font(.caption).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Button(role: .destructive) {
                                        Task {
                                            try? await api.deleteTask(taskId: task.id, patientProfileId: patient.id)
                                        }
                                    } label: {
                                        Image(systemName: "trash")
                                    }
                                }
                            }
                        }
                    }
                }

                GroupBox("Son Vital Kayitlari") {
                    if timelineLoading && api.vitals.isEmpty {
                        ProgressView("Vital kayitlari yukleniyor...")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else if api.vitals.isEmpty {
                        Text("Vital kaydi yok.")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        VStack(spacing: 8) {
                            ForEach(api.vitals.prefix(5)) { vital in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Ates \(vital.bodyTemperature ?? 0, specifier: "%.1f")°C, Nabiz \(vital.heartRate ?? 0)")
                                            .font(.subheadline.bold())
                                        Text(vital.recordedAt ?? "-")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Button(role: .destructive) {
                                        Task {
                                            try? await api.deleteVital(vitalId: vital.id, patientProfileId: patient.id)
                                        }
                                    } label: {
                                        Image(systemName: "trash")
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Hasta Detayi")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAddTask, onDismiss: {
            Task { try? await api.fetchTasks(patientProfileId: patient.id) }
        }) {
            AddTaskView(patient: patient).environmentObject(api)
        }
        .sheet(isPresented: $showAddVital, onDismiss: {
            Task { try? await api.fetchVitals(patientProfileId: patient.id) }
        }) {
            AddVitalView(patient: patient).environmentObject(api)
        }
        .task {
            isPostOp = patient.carePhase == "post_op" || !(patient.transplantDate ?? "").isEmpty
            if let transplantDate = patient.transplantDate,
               let parsed = ISO8601DateFormatter().date(from: transplantDate) {
                operationDate = parsed
            }
            modulesLoading = true
            defer { modulesLoading = false }
            try? await api.fetchPatientModules(patientProfileId: patient.id)
            timelineLoading = true
            defer { timelineLoading = false }
            async let t: Void = api.fetchTasks(patientProfileId: patient.id)
            async let v: Void = api.fetchVitals(patientProfileId: patient.id)
            _ = try? await (t, v)
        }
    }

    private func detailRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title).foregroundStyle(.secondary)
            Spacer()
            Text(value).multilineTextAlignment(.trailing)
        }
    }

    private func moduleTitle(_ raw: String) -> String {
        switch raw {
        case "mobilization": return "Mobilizasyon"
        case "nutrition": return "Beslenme"
        case "wound_care": return "Yara Bakimi"
        case "medication": return "Ilac Yonetimi"
        case "vital_signs": return "Vital Takibi"
        default: return raw
        }
    }

    private func saveOperationState() async {
        opSaving = true
        defer { opSaving = false }
        let iso = ISO8601DateFormatter().string(from: operationDate)
        try? await api.updatePatientOperation(
            patientId: patient.id,
            transplantDateISO: isPostOp ? iso : nil,
            setPreOp: !isPostOp
        )
    }

    private func applyPreset(preOp: Bool) async {
        var updated = api.patientModules
        for i in updated.indices {
            switch updated[i].name {
            case "mobilization", "nutrition":
                updated[i].isEnabled = true
            case "medication", "wound_care", "vital_signs":
                updated[i].isEnabled = !preOp
            default:
                break
            }
        }
        try? await api.updatePatientModules(patientProfileId: patient.id, modules: updated)
    }
}
