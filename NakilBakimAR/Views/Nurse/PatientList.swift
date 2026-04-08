import SwiftUI

struct PatientList: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Hemsire Paneli")
                .font(.title3.bold())
                .foregroundStyle(.white)
            Text("Hasta listesi ve son vital ozeti bu ekranda olacak.")
                .foregroundStyle(.white.opacity(0.85))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.white.opacity(0.18))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
