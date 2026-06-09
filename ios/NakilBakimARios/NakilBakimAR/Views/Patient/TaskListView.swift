import SwiftUI

struct TaskListView: View {
    @EnvironmentObject var api: APIService
    let patientProfileId: UUID?
    @State private var localError = ""

    var body: some View {
        SurfaceCard {
            SectionCardTitle(text: "Gorevlerim", icon: "checklist")
            if api.tasksLoading && api.tasks.isEmpty {
                ProgressView("Görevler yükleniyor...")
            } else if api.tasks.isEmpty {
                Text("Gorev bulunamadi.")
                    .font(AppTypography.helper)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(api.tasks.prefix(3)) { task in
                    HStack {
                        Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(task.isCompleted ? InonuPalette.success : InonuPalette.secondary)
                        VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                            Text(task.title).font(.subheadline)
                            if let scheduled = task.scheduledTime, !scheduled.isEmpty {
                                Text("Planli: \(scheduled)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        Text(task.type.uppercased())
                            .font(.caption2.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(InonuPalette.cream)
                            .clipShape(Capsule())
                        if !task.isCompleted, let patientProfileId {
                            Button("Tamamla") {
                                Task {
                                    do {
                                        try await api.completeTask(taskId: task.id, patientProfileId: patientProfileId)
                                    } catch {
                                        localError = "Gorev tamamlanamadi: \(error.localizedDescription)"
                                    }
                                }
                            }
                            .font(.caption.bold())
                            .foregroundStyle(InonuPalette.navySoft)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
            if !localError.isEmpty {
                Text(localError)
                    .font(AppTypography.helper)
                    .foregroundStyle(InonuPalette.danger)
            }
        }
    }
}
