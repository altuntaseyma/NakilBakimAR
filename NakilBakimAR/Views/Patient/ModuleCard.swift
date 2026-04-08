import SwiftUI

struct ModuleCard: View {
    let title: String
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon).font(.title2)
            Text(title).font(.headline)
            Spacer()
            Image(systemName: "chevron.right")
        }
        .padding()
        .background(Color(hex: "#F5E6C8"))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
