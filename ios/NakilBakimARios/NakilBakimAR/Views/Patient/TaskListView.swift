import SwiftUI

struct TaskListView: View {
    @EnvironmentObject var api: APIService
    let patientProfileId: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Gorevlerim", systemImage: "checklist")
                .font(.headline)
            if api.tasks.isEmpty {
                Text("Gorev bulunamadi.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(api.tasks.prefix(3)) { task in
                    HStack {
                        Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(task.isCompleted ? .green : .secondary)
                        Text(task.title)
                        Spacer()
                        Text(task.type).font(.caption).foregroundStyle(.secondary)
                        if !task.isCompleted, let patientProfileId {
                            Button("Tamamla") {
                                Task {
                                    try? await api.completeTask(taskId: task.id, patientProfileId: patientProfileId)
                                }
                            }
                            .font(.caption.bold())
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
