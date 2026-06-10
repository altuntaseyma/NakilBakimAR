import SwiftUI

// MARK: - Bildirim Modeli
struct AppNotification: Identifiable {
    let id = UUID()
    let title: String
    let body: String
    let icon: String
    let color: Color
    let time: Date
    var isRead: Bool = false
    let category: NotificationCategory

    enum NotificationCategory: String {
        case vital        = "vital"
        case task         = "task"
        case medication   = "medication"
        case warning      = "warning"
        case info         = "info"
    }
}

// MARK: - NotificationsView
struct NotificationsView: View {
    @EnvironmentObject var api: APIService
    @State private var notifications: [AppNotification] = []
    @State private var showLogoutAlert = false

    private var isNurse: Bool { api.currentUser?.role == "nurse" }

    var body: some View {
        ZStack {
            AnimatedBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.large) {

                    // Profil Kartı
                    profileCard

                    // Bildirim Özeti
                    if !notifications.isEmpty {
                        notificationSummaryRow
                    }

                    // Bildirimler Listesi
                    notificationsSection

                    // Çıkış Yap Butonu
                    logoutSection
                }
                .padding()
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Bildirimler")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if notifications.contains(where: { !$0.isRead }) {
                    Button("Tümünü Okundu İşaretle") {
                        withAnimation {
                            for i in notifications.indices { notifications[i].isRead = true }
                        }
                    }
                    .font(.caption.bold())
                    .foregroundStyle(InonuPalette.primary)
                }
            }
        }
        .alert("Çıkış Yapılsın mı?", isPresented: $showLogoutAlert) {
            Button("Çıkış Yap", role: .destructive) { api.logout() }
            Button("İptal", role: .cancel) { }
        } message: {
            Text("Oturumunuz kapatılacak. Tekrar giriş yapmanız gerekecek.")
        }
        .task {
            await buildNotifications()
        }
        .refreshable {
            await refreshAndBuild()
        }
    }

    // MARK: - Profil Kartı
    private var profileCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(isNurse ? InonuPalette.primary.opacity(0.12) : InonuPalette.exerciseBlue.opacity(0.12))
                    .frame(width: 60, height: 60)
                Image(systemName: isNurse ? "stethoscope" : "person.crop.circle.fill")
                    .font(.title2)
                    .foregroundStyle(isNurse ? InonuPalette.primary : InonuPalette.exerciseBlue)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(api.currentUser?.email ?? "—")
                    .font(.headline.bold())
                    .foregroundStyle(InonuPalette.deepNavy)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    StatusPill(
                        text: isNurse ? "Hemşire" : "Hasta",
                        color: isNurse ? InonuPalette.primary : InonuPalette.exerciseBlue
                    )
                    if let name = api.myProfile?.fullName, !isNurse {
                        Text(name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            // Okunmamış rozeti
            let unread = notifications.filter { !$0.isRead }.count
            if unread > 0 {
                ZStack {
                    Circle()
                        .fill(InonuPalette.danger)
                        .frame(width: 28, height: 28)
                    Text("\(min(unread, 99))")
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                }
            }
        }
        .padding(AppSpacing.large)
        .background(Color.white.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.large))
        .overlay(RoundedRectangle(cornerRadius: AppRadius.large).stroke(InonuPalette.cardBorder, lineWidth: 1))
        .shadow(color: AppShadow.card, radius: 10, x: 0, y: 4)
    }

    // MARK: - Özet Satırı
    private var notificationSummaryRow: some View {
        let unread = notifications.filter { !$0.isRead }.count
        let warnings = notifications.filter { $0.category == .warning }.count

        return HStack(spacing: 10) {
            summaryPill(icon: "bell.fill", label: "Toplam", value: "\(notifications.count)", color: InonuPalette.info)
            summaryPill(icon: "exclamationmark.circle.fill", label: "Uyarı", value: "\(warnings)", color: InonuPalette.warning)
            summaryPill(icon: "envelope.badge.fill", label: "Okunmadı", value: "\(unread)", color: InonuPalette.danger)
        }
    }

    private func summaryPill(icon: String, label: String, value: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(color)
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(InonuPalette.deepNavy)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(color.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium))
        .overlay(RoundedRectangle(cornerRadius: AppRadius.medium).stroke(color.opacity(0.15), lineWidth: 1))
    }

    // MARK: - Bildirimler Listesi
    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("BİLDİRİMLER")
                    .font(.caption.bold())
                    .tracking(1.0)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(Date().formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if notifications.isEmpty {
                EmptyStateCard(
                    title: "Bildirim bulunmuyor",
                    subtitle: "Şu an için dikkat gerektiren bir durum yok."
                )
            } else {
                VStack(spacing: 8) {
                    ForEach(notifications.indices, id: \.self) { idx in
                        notificationRow(notifications[idx], index: idx)
                    }
                }
            }
        }
    }

    private func notificationRow(_ notif: AppNotification, index: Int) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(notif.color.opacity(0.12))
                    .frame(width: 38, height: 38)
                Image(systemName: notif.icon)
                    .font(.subheadline.bold())
                    .foregroundStyle(notif.color)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(notif.title)
                        .font(.subheadline.bold())
                        .foregroundStyle(notif.isRead ? .secondary : InonuPalette.deepNavy)
                    Spacer()
                    if !notif.isRead {
                        Circle()
                            .fill(notif.color)
                            .frame(width: 8, height: 8)
                    }
                }
                Text(notif.body)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                Text(relativeTime(notif.time))
                    .font(.caption2)
                    .foregroundStyle(notif.color.opacity(0.8))
            }
        }
        .padding(12)
        .background(notif.isRead ? Color.white.opacity(0.8) : Color.white.opacity(0.97))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium))
        .overlay(RoundedRectangle(cornerRadius: AppRadius.medium)
            .stroke(notif.isRead ? InonuPalette.cardBorder : notif.color.opacity(0.25), lineWidth: notif.isRead ? 1 : 1.5))
        .shadow(color: notif.isRead ? .clear : notif.color.opacity(0.08), radius: 6, x: 0, y: 3)
        .onTapGesture {
            withAnimation { notifications[index].isRead = true }
        }
    }

    // MARK: - Çıkış Bölümü
    private var logoutSection: some View {
        VStack(spacing: 12) {
            Divider()

            Button {
                showLogoutAlert = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("Oturumu Kapat")
                }
                .font(.subheadline.bold())
                .foregroundStyle(InonuPalette.danger)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(InonuPalette.danger.opacity(0.07))
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium))
                .overlay(RoundedRectangle(cornerRadius: AppRadius.medium)
                    .stroke(InonuPalette.danger.opacity(0.2), lineWidth: 1))
            }
            .buttonStyle(.plain)

            Text("NakilBakımAR • Turgut Özal Tıp Merkezi")
                .font(.caption2)
                .foregroundStyle(.secondary.opacity(0.6))
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    // MARK: - Bildirim Üretme Mantığı
    private func buildNotifications() async {
        var result: [AppNotification] = []

        if isNurse {
            // Hemşire: Son 12 saatte vital girilmemiş hastalar için uyarı
            for patient in api.nursePatients {
                if !patient.isActive { continue }
                let hasRecentVital: Bool = {
                    guard let lastStr = patient.lastVitalRecordedAt,
                          let lastDate = lastStr.parseIsoDate() else { return false }
                    return Date().timeIntervalSince(lastDate) <= 12 * 3600
                }()

                if !hasRecentVital {
                    result.append(AppNotification(
                        title: "Vital Girilmedi: \(patient.fullName ?? "Hasta")",
                        body: "Son 12 saattir vital bilgisi kaydedilmemiş. Lütfen kontrol edin.",
                        icon: "exclamationmark.heart.fill",
                        color: InonuPalette.warning,
                        time: Date().addingTimeInterval(-Double.random(in: 3600...43200)),
                        category: .warning
                    ))
                }
            }

            // Hemşire: Tamamlanmamış görev sayısı bildirimi (toplam)
            let pendingTasks = api.tasks.filter { !$0.isCompleted }
            if !pendingTasks.isEmpty {
                result.append(AppNotification(
                    title: "\(pendingTasks.count) Tamamlanmamış Görev",
                    body: "Aktif hastalara atanmış tamamlanmamış görevler var. Durumları takip edin.",
                    icon: "checklist",
                    color: InonuPalette.info,
                    time: Calendar.current.startOfDay(for: Date()),
                    category: .task
                ))
            }

            // Hemşire: İlaç görevleri varsa ayrı uyarı
            let medicationPending = api.tasks.filter { $0.type == "medication" && !$0.isCompleted }
            if !medicationPending.isEmpty {
                result.append(AppNotification(
                    title: "\(medicationPending.count) İlaç Görevi Bekliyor",
                    body: "Hastalarınızın ilaç uygulama görevleri tamamlanmayı bekliyor.",
                    icon: "pills.fill",
                    color: InonuPalette.medicationPurple,
                    time: Date().addingTimeInterval(-1800),
                    category: .medication
                ))
            }

            // Bilgilendirme: Sistem mesajı
            result.append(AppNotification(
                title: "Vardiya Özeti",
                body: "Bugün \(api.nursePatients.count) aktif hastanız bulunuyor. İyi vardiyalar.",
                icon: "calendar.badge.checkmark",
                color: InonuPalette.primary,
                time: Calendar.current.startOfDay(for: Date()),
                isRead: true,
                category: .info
            ))

        } else {
            // Hasta: Bugün tamamlanmamış görevler
            let todayTasks = api.tasks.filter { task in
                guard !task.isCompleted else { return false }
                if let scheduled = task.scheduledTime, let date = scheduled.parseIsoDate() {
                    return Calendar.current.isDateInToday(date)
                }
                return true // Tarihsiz görevler bugün gösterilir
            }

            for task in todayTasks.prefix(5) {
                let (icon, color) = taskIconAndColor(type: task.type)
                result.append(AppNotification(
                    title: task.title,
                    body: taskReminderBody(type: task.type),
                    icon: icon,
                    color: color,
                    time: Date().addingTimeInterval(-Double.random(in: 300...7200)),
                    category: task.type == "medication" ? .medication : .task
                ))
            }

            // Hasta: Yeni vital paylaşıldıysa
            if let latest = api.vitals.first,
               let recordedAt = latest.recordedAt,
               let date = recordedAt.parseIsoDate(),
               Date().timeIntervalSince(date) < 24 * 3600 {
                result.append(AppNotification(
                    title: "Yeni Vital Bilgisi Paylaşıldı",
                    body: "Hemşireniz yeni ölçüm değerlerinizi sisteme ekledi. Vital Bulgular sekmesinden görüntüleyebilirsiniz.",
                    icon: "heart.text.square.fill",
                    color: InonuPalette.vitalRose,
                    time: date,
                    category: .vital
                ))
            }

            // Hasta: Genel sağlık bildirimi
            result.append(AppNotification(
                title: "Günlük Bakım Özeti",
                body: "Bugün \(api.tasks.filter { !$0.isCompleted }.count) göreviniz tamamlanmayı bekliyor. Sağlıklı günler dileriz.",
                icon: "heart.fill",
                color: InonuPalette.primary,
                time: Calendar.current.startOfDay(for: Date()),
                isRead: true,
                category: .info
            ))
        }

        // Tarihe göre sırala (en yeni üste)
        result.sort { $0.time > $1.time }
        await MainActor.run { notifications = result }
    }

    private func refreshAndBuild() async {
        if isNurse {
            try? await api.fetchNursePatients()
        } else if let id = api.myProfile?.id {
            try? await api.fetchTasks(patientProfileId: id)
            try? await api.fetchVitals(patientProfileId: id)
        }
        await buildNotifications()
    }

    // MARK: - Yardımcılar
    private func taskIconAndColor(type: String?) -> (String, Color) {
        switch type {
        case "medication":  return ("pills.fill", InonuPalette.medicationPurple)
        case "exercise":    return ("figure.walk", InonuPalette.exerciseBlue)
        case "nutrition":   return ("fork.knife", InonuPalette.nutritionOrange)
        case "wound_care":  return ("bandage.fill", InonuPalette.woundCoral)
        default:            return ("checklist", InonuPalette.info)
        }
    }

    private func taskReminderBody(type: String?) -> String {
        switch type {
        case "medication":  return "İlaç saatiniz yaklaşıyor. Dozunuzu almayı unutmayın."
        case "exercise":    return "Bugünkü egzersiz görevinizi tamamlamayı unutmayın."
        case "nutrition":   return "Beslenme takibinizi güncelleyin."
        case "wound_care":  return "Yara bakımı kontrol zamanı geldi."
        default:            return "Bu görev tamamlanmayı bekliyor."
        }
    }

    private func relativeTime(_ date: Date) -> String {
        let diff = Date().timeIntervalSince(date)
        if diff < 60 { return "Az önce" }
        if diff < 3600 { return "\(Int(diff / 60)) dakika önce" }
        if diff < 86400 { return "\(Int(diff / 3600)) saat önce" }
        return "\(Int(diff / 86400)) gün önce"
    }
}
