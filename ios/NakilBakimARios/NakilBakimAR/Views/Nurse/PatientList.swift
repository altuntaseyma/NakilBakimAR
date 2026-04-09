import SwiftUI

struct PatientList: View {
    @EnvironmentObject var api: APIService

    var body: some View {
        ZStack {
            AnimatedBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Hemsire Paneli")
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)
                    Text("Hasta durumlarini yonet, gorev ve vital planlamasini hizli yap.")
                        .foregroundStyle(.white.opacity(0.88))

                    if api.nursePatients.isEmpty {
                        Text("Hasta listesi yukleniyor ya da bos.")
                            .foregroundStyle(.white.opacity(0.9))
                    } else {
                        ForEach(api.nursePatients) { patient in
                            NavigationLink {
                                PatientDetail(patient: patient)
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(patient.fullName ?? "Isimsiz Hasta")
                                        .font(.headline)
                                    Text(patient.diagnosis ?? "Tani girilmemis")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    HStack(spacing: 8) {
                                        statusPill(text: patient.carePhase == "post_op" ? "Post-op" : "Pre-op")
                                        statusPill(text: patient.isActive ? "Aktif" : "Pasif")
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(10)
                                .background(.white.opacity(0.92))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(.white.opacity(0.18))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding()
            }
        }
        .navigationTitle("Hastalar")
        .task {
            do { try await api.fetchNursePatients() }
            catch { print("fetchNursePatients error: \(error.localizedDescription)") }
        }
    }

    private func statusPill(text: String) -> some View {
        Text(text)
            .font(.caption.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(hex: "#F5E6C8"))
            .clipShape(Capsule())
    }
}
