import SwiftUI

struct LoginView: View {
    @EnvironmentObject var api: APIService
    @State private var email = ""
    @State private var password = ""
    @State private var loading = false
    @State private var errorText = ""

    var body: some View {
        ZStack {
            AnimatedBackground()
            VStack(spacing: 20) {
                Image(systemName: "cross.case.fill")
                    .font(.system(size: 58))
                    .foregroundStyle(Color(hex: "#F5E6C8"))
                    .symbolEffect(.pulse)

                Text("NakilBakimAR")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)

                VStack(spacing: 12) {
                    TextField("Email", text: $email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                    SecureField("Sifre", text: $password)
                }
                .padding()
                .background(.white.opacity(0.9))
                .clipShape(RoundedRectangle(cornerRadius: 16))

                Button {
                    Task {
                        loading = true
                        defer { loading = false }
                        do { try await api.login(email: email, password: password) }
                        catch { errorText = "Giris basarisiz. Bilgileri kontrol et." }
                    }
                } label: {
                    Text(loading ? "Giris yapiliyor..." : "Giris Yap")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(hex: "#8B1E3F"))

                if !errorText.isEmpty {
                    Text(errorText).foregroundStyle(.red).font(.footnote)
                }

                if let user = api.currentUser {
                    if user.role == "nurse" {
                        PatientList()
                    } else {
                        DashboardView()
                    }
                }
            }
            .padding()
        }
    }
}
