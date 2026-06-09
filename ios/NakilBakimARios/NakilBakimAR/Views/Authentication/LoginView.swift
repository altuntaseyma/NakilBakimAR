import SwiftUI
import UIKit

struct LoginView: View {

    enum GirisModu: String, CaseIterable, Identifiable {
        case hasta    = "Hasta"
        case personel = "Yetkili"
        var id: String { rawValue }
        var ikon: String { self == .hasta ? "heart.text.square.fill" : "cross.case.fill" }
    }

    @EnvironmentObject var api: APIService
    @Namespace private var modNS

    @State private var mod: GirisModu  = .hasta
    @State private var eposta          = ""
    @State private var sifre           = ""
    @State private var tcNo            = ""
    @State private var pin             = ""
    @State private var yukleniyor      = false
    @State private var hata            = ""
    @State private var gorundu         = false

    var body: some View {
        Group {
            if api.currentUser != nil {
                TabBarView()
            } else {
                zemin
                    .overlay(icerik)
            }
        }
    }

    // MARK: - Zemin
    private var zemin: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#0A2E3C"), Color(hex: "#0E6B5C")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Dekoratif daireler
            Circle()
                .fill(Color.white.opacity(0.04))
                .frame(width: 320)
                .blur(radius: 1)
                .offset(x: -100, y: -180)

            Circle()
                .fill(Color(hex: "#0D9B8A").opacity(0.15))
                .frame(width: 220)
                .blur(radius: 60)
                .offset(x: 130, y: 280)

            Circle()
                .fill(Color.white.opacity(0.03))
                .frame(width: 260)
                .blur(radius: 2)
                .offset(x: 80, y: -300)
        }
    }

    // MARK: - İçerik
    private var icerik: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // Üst logo alanı
                VStack(spacing: 12) {
                    logoAlani
                }
                .padding(.top, 64)
                .padding(.bottom, 36)

                // Beyaz kart
                kart
                    .padding(.horizontal, 24)
                    .offset(y: gorundu ? 0 : 40)
                    .opacity(gorundu ? 1 : 0)

                // Alt not
                altNot
                    .padding(.top, 28)
                    .padding(.bottom, 40)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.85)) {
                gorundu = true
            }
        }
    }

    // MARK: - Logo Alanı
    private var logoAlani: some View {
        VStack(spacing: 10) {
            if let img = UIImage(named: "logo-img") {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 110)
            } else {
                Image(systemName: "cross.circle.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(.white.opacity(0.9))

                Text("Turgut Özal Tıp Merkezi")
                    .font(.title3.bold())
                    .foregroundStyle(.white)

                Text("Karaciğer Nakli Enstitüsü")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
    }

    // MARK: - Ana Kart
    private var kart: some View {
        VStack(alignment: .leading, spacing: 24) {

            // Kart Başlığı
            VStack(alignment: .leading, spacing: 4) {
                Text("Giriş Yapın")
                    .font(.title2.bold())
                    .foregroundStyle(InonuPalette.deepNavy)
                Text("Sisteme devam etmek için rolünüzü seçin.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Mod Seçici
            modSecici

            // Giriş Alanları
            VStack(spacing: 12) {
                alanlar
            }

            // Giriş Butonu
            girisButonu

            // Hata
            if !hata.isEmpty {
                hataGorunu
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(28)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.2), radius: 30, x: 0, y: 16)
    }

    // MARK: - Mod Seçici
    private var modSecici: some View {
        HStack(spacing: 6) {
            ForEach(GirisModu.allCases) { item in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        mod = item
                        hata = ""
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: item.ikon)
                            .font(.subheadline)
                        Text(item.rawValue)
                            .font(.subheadline.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .foregroundStyle(mod == item ? .white : InonuPalette.deepNavy.opacity(0.5))
                    .background {
                        if mod == item {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(LinearGradient(
                                    colors: [Color(hex: "#0D9B8A"), Color(hex: "#0A2E3C")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .shadow(color: Color(hex: "#0D9B8A").opacity(0.3), radius: 6, y: 3)
                                .matchedGeometryEffect(id: "mod", in: modNS)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(5)
        .background(Color(hex: "#F0F7F5"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Giriş Alanları
    @ViewBuilder
    private var alanlar: some View {
        if mod == .hasta {
            // TC Alanı
            girisAlani(
                ikon: "person.text.rectangle",
                etiket: "T.C. Kimlik No",
                icerik: {
                    SayisalGirisAlani(metin: $tcNo, yerTutucu: "T.C. Kimlik Numaranız", maxUzunluk: 11, gizli: false)
                        .frame(height: 22)
                }
            )

            // PIN Alanı
            VStack(alignment: .leading, spacing: 8) {
                girisAlani(
                    ikon: "lock.fill",
                    etiket: "PIN",
                    icerik: {
                        SayisalGirisAlani(metin: $pin, yerTutucu: "PIN Kodunuz", maxUzunluk: 4, gizli: true)
                            .frame(height: 22)
                    }
                )

                // PIN noktacıkları
                HStack(spacing: 12) {
                    Spacer()
                    ForEach(0..<4, id: \.self) { i in
                        Circle()
                            .fill(i < pin.count ? InonuPalette.primary : Color(hex: "#E2EBE8"))
                            .frame(width: 10, height: 10)
                            .scaleEffect(i < pin.count ? 1.1 : 1.0)
                            .animation(.spring(response: 0.2), value: pin.count)
                    }
                    Spacer()
                }
            }
        } else {
            // E-posta
            girisAlani(
                ikon: "envelope",
                etiket: "E-posta",
                icerik: {
                    TextField("ornek@hastane.edu.tr", text: $eposta)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .font(.subheadline)
                }
            )

            // Şifre
            girisAlani(
                ikon: "lock",
                etiket: "Şifre",
                icerik: {
                    SecureField("••••••••", text: $sifre)
                        .font(.subheadline)
                }
            )
        }
    }

    // MARK: - Alan Sarmalayıcı
    private func girisAlani<I: View>(
        ikon: String,
        etiket: String,
        @ViewBuilder icerik: () -> I
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(etiket)
                .font(.caption.bold())
                .foregroundStyle(InonuPalette.navySoft)
                .textCase(.uppercase)
                .tracking(0.6)

            HStack(spacing: 10) {
                Image(systemName: ikon)
                    .font(.subheadline)
                    .foregroundStyle(InonuPalette.primary.opacity(0.8))
                    .frame(width: 20)

                icerik()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(Color(hex: "#F8FBFA"))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(hex: "#E2EBE8"), lineWidth: 1)
            )
        }
    }

    // MARK: - Giriş Butonu
    private var girisButonu: some View {
        Button {
            Task { await girisYap() }
        } label: {
            ZStack {
                if yukleniyor {
                    ProgressView().tint(.white)
                } else {
                    HStack(spacing: 8) {
                        Text("Giriş Yap")
                            .font(.headline)
                        Image(systemName: "arrow.right")
                            .font(.subheadline.bold())
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                girisGecerliMi
                ? LinearGradient(
                    colors: [Color(hex: "#0D9B8A"), Color(hex: "#0A2E3C")],
                    startPoint: .leading,
                    endPoint: .trailing
                  )
                : LinearGradient(
                    colors: [Color(hex: "#C8D8D6"), Color(hex: "#C8D8D6")],
                    startPoint: .leading,
                    endPoint: .trailing
                  )
            )
            .foregroundStyle(girisGecerliMi ? .white : Color(hex: "#8AADAA"))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(
                color: girisGecerliMi ? Color(hex: "#0D9B8A").opacity(0.4) : .clear,
                radius: 10, y: 5
            )
        }
        .disabled(!girisGecerliMi || yukleniyor)
        .animation(.easeInOut(duration: 0.2), value: girisGecerliMi)
    }

    // MARK: - Hata Görünümü
    private var hataGorunu: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(InonuPalette.danger)
                .font(.footnote)
            Text(hata)
                .font(.footnote)
                .foregroundStyle(InonuPalette.danger)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .background(InonuPalette.danger.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(InonuPalette.danger.opacity(0.15), lineWidth: 1)
        )
    }

    // MARK: - Alt Not
    private var altNot: some View {
        VStack(spacing: 4) {
            Text("İnönü Üniversitesi · Karaciğer Nakli Enstitüsü")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.5))
            Text("© 2026 Malatya, Türkiye")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.35))
        }
        .multilineTextAlignment(.center)
    }

    // MARK: - Doğrulama
    private var girisGecerliMi: Bool {
        if mod == .hasta {
            return isValidTcNo(tcNo.filter(\.isNumber)) && pin.filter(\.isNumber).count == 4
        }
        return !eposta.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               !sifre.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Giriş İşlemi
    private func girisYap() async {
        yukleniyor = true
        hata       = ""
        defer { yukleniyor = false }
        do {
            if mod == .hasta {
                let temizTc  = tcNo.filter(\.isNumber)
                let temizPin = pin.filter(\.isNumber)
                guard isValidTcNo(temizTc), temizPin.count == 4 else {
                    hata = "Geçerli bir T.C. kimlik numarası ve 4 haneli PIN giriniz."
                    return
                }
                try await api.loginPatient(tcNo: temizTc, pin: temizPin)
            } else {
                try await api.login(
                    email: eposta.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
                    password: sifre
                )
            }
        } catch {
            withAnimation {
                if let e = error as? URLError,
                   [.notConnectedToInternet, .cannotConnectToHost, .timedOut].contains(e.code) {
                    hata = "Sunucuya bağlanılamadı. Lütfen bağlantınızı kontrol edin."
                } else {
                    hata = "Giriş başarısız: \(error.localizedDescription)"
                }
            }
        }
    }
}

// MARK: - Sayısal Giriş Alanı
private struct SayisalGirisAlani: UIViewRepresentable {
    @Binding var metin: String
    let yerTutucu: String
    let maxUzunluk: Int
    let gizli: Bool

    func makeUIView(context: Context) -> UITextField {
        let alan = UITextField()
        alan.placeholder       = yerTutucu
        alan.keyboardType      = .numberPad
        alan.textContentType   = .oneTimeCode
        alan.isSecureTextEntry = gizli
        alan.font              = .systemFont(ofSize: 15)
        alan.delegate          = context.coordinator
        alan.addTarget(context.coordinator, action: #selector(Coordinator.degisti(_:)), for: .editingChanged)
        return alan
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        if uiView.text != metin               { uiView.text = metin }
        if uiView.isSecureTextEntry != gizli  { uiView.isSecureTextEntry = gizli }
    }

    func makeCoordinator() -> Coordinator { Coordinator(metin: $metin, max: maxUzunluk) }

    final class Coordinator: NSObject, UITextFieldDelegate {
        @Binding var metin: String
        let max: Int
        init(metin: Binding<String>, max: Int) { self._metin = metin; self.max = max }

        @objc func degisti(_ tf: UITextField) {
            let s = String((tf.text ?? "").filter(\.isNumber).prefix(max))
            if tf.text != s { tf.text = s }
            metin = s
        }

        func textField(_ tf: UITextField, shouldChangeCharactersIn r: NSRange, replacementString str: String) -> Bool {
            guard let cur = tf.text, let rng = Range(r, in: cur) else { return false }
            let candidate = String(cur.replacingCharacters(in: rng, with: str).filter(\.isNumber).prefix(max))
            if cur.replacingCharacters(in: rng, with: str) != candidate {
                tf.text = candidate; metin = candidate; return false
            }
            return true
        }
    }
}
