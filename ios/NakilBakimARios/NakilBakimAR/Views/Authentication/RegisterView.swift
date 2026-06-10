import SwiftUI

struct RegisterView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var api: APIService

    @State private var fullName = ""
    @State private var tcNo = ""
    @State private var pin = ""
    @State private var includeOperationDate = false
    @State private var operationDate = Date()
    @State private var loading = false
    @State private var infoText = ""
    @State private var errorText = ""

    var body: some View {
        ZStack {
            AnimatedBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.large) {
                    GlassTopBar(
                        title: "Yeni Hasta Kaydı",
                        subtitle: "Hasta kullanıcısı oluşturma",
                        icon: "person.badge.plus"
                    )

                    SurfaceCard {
                        SectionCardTitle(text: "Hasta Bilgileri", icon: "person.text.rectangle")

                        TextField("Ad Soyad", text: $fullName)
                            .textInputAutocapitalization(.words)
                            .glassInputField()

                        TextField("T.C. Kimlik Numarası", text: tcNoBinding)
                            .keyboardType(.numberPad)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                            .glassInputField()

                        SecureField("4 Haneli PIN", text: pinBinding)
                            .keyboardType(.numberPad)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                            .glassInputField()

                        Toggle("Ameliyat tarihi gir", isOn: $includeOperationDate)
                        if includeOperationDate {
                            DatePicker("Ameliyat Tarihi/Saati", selection: $operationDate)
                        }
                    }

                    if !infoText.isEmpty {
                        SurfaceCard {
                            Label(infoText, systemImage: "checkmark.seal.fill")
                                .font(AppTypography.helper)
                                .foregroundStyle(InonuPalette.success)
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
                        Button("Vazgeç") { dismiss() }
                            .buttonStyle(CustomButtonStyle(tint: InonuPalette.deepNavy, isSecondary: true))

                        Button(loading ? "Oluşturuluyor..." : "Hasta Oluştur") {
                            Task { await createPatientUser() }
                        }
                        .disabled(loading || !isFormValid)
                        .buttonStyle(CustomButtonStyle())
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Hasta Kaydı")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var isFormValid: Bool {
        fullName.trimmingCharacters(in: .whitespacesAndNewlines).count >= 3 &&
        isValidTcNo(tcNo) &&
        pin.count == 4
    }

    private func createPatientUser() async {
        loading = true
        infoText = ""
        errorText = ""
        defer { loading = false }

        do {
            try await api.registerPatientByNurse(
                fullName: fullName.trimmingCharacters(in: .whitespacesAndNewlines),
                tcNo: tcNo,
                pin: pin,
                transplantDateISO: includeOperationDate ? ISO8601DateFormatter().string(from: operationDate) : nil
            )
            infoText = "Hasta kullanıcısı başarıyla oluşturuldu."
            fullName = ""
            tcNo = ""
            pin = ""
            includeOperationDate = false
            operationDate = Date()
        } catch {
            errorText = "Kayıt sırasında hata: \(error.localizedDescription)"
        }
    }

    private var tcNoBinding: Binding<String> {
        Binding(
            get: { tcNo },
            set: { tcNo = String($0.filter(\.isNumber).prefix(11)) }
        )
    }

    private var pinBinding: Binding<String> {
        Binding(
            get: { pin },
            set: { pin = String($0.filter(\.isNumber).prefix(4)) }
        )
    }

    // isValidTcNo — bkz. Utils/TcValidator.swift
}
