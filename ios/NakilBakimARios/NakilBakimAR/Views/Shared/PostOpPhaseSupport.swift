import SwiftUI

enum PostOpPhase: String, CaseIterable {
    case preOp
    case day1
    case day2to3
    case day4to7
    case week1to4

    init(dayOffset: Int?, carePhaseHint: String?) {
        if let dayOffset {
            if dayOffset < 0 {
                self = .preOp
                return
            }
            let postOpDay = dayOffset + 1
            switch postOpDay {
            case 1: self = .day1
            case 2...3: self = .day2to3
            case 4...7: self = .day4to7
            default: self = .week1to4
            }
            return
        }

        if carePhaseHint == "post_op" {
            self = .day1
        } else {
            self = .preOp
        }
    }
}

struct SurgeryTimeline {
    let surgeryDate: Date
    let dayOffset: Int

    var postOpDay: Int {
        max(dayOffset + 1, 1)
    }

    var preOpDaysLeft: Int {
        abs(dayOffset)
    }

    var hoursUntilSurgery: Int {
        let diff = Calendar.current.dateComponents([.hour], from: Date(), to: surgeryDate).hour ?? 0
        return max(diff, 0)
    }

    var statusTitle: String {
        if dayOffset < 0 {
            return "Ameliyata \(preOpDaysLeft) gün kaldı"
        }
        return "Ameliyat sonrası \(postOpDay). gündesin"
    }

    var shortLabel: String {
        if dayOffset < 0 {
            return "Pre-op - \(preOpDaysLeft) gün"
        }
        return "Post-op - Gün \(postOpDay)"
    }

    static func parse(iso: String?) -> SurgeryTimeline? {
        guard let iso, !iso.isEmpty else { return nil }
        if let date = ISO8601DateFormatter().date(from: iso) {
            return build(date: date)
        }

        let fallback = ISO8601DateFormatter()
        fallback.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = fallback.date(from: iso) else { return nil }
        return build(date: date)
    }

    private static func build(date: Date) -> SurgeryTimeline {
        let calendar = Calendar.current
        let surgeryStart = calendar.startOfDay(for: date)
        let todayStart = calendar.startOfDay(for: Date())
        let offset = calendar.dateComponents([.day], from: surgeryStart, to: todayStart).day ?? 0
        return SurgeryTimeline(surgeryDate: date, dayOffset: offset)
    }
}

struct CareTimelineCard: View {
    let statusTitle: String
    let subtitle: String
    let tint: Color

    var body: some View {
        SurfaceCard {
            Label(statusTitle, systemImage: "calendar.badge.clock")
                .font(.subheadline.bold())
                .foregroundStyle(InonuPalette.deepNavy)

            Text(subtitle)
                .font(AppTypography.helper)
                .foregroundStyle(.secondary)

            RoundedRectangle(cornerRadius: 10)
                .fill(tint.opacity(0.12))
                .frame(height: 8)
        }
    }
}
