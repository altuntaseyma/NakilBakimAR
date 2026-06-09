import SwiftUI
import UIKit

struct BrandHeaderView: View {
    var compact: Bool = false

    var body: some View {
        VStack(spacing: compact ? 6 : 10) {
            logoView
                .frame(width: compact ? 230 : 300, height: compact ? 74 : 100)
                .padding(.top, compact ? 0 : 2)

            Text("Turgut Özal Tıp Merkezi")
                .font(compact ? .headline : .title3.bold())
                .foregroundStyle(InonuPalette.deepNavy)
            Text("Karaciğer Nakli Enstitüsü")
                .font(compact ? .caption : .subheadline)
                .foregroundStyle(InonuPalette.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, compact ? AppSpacing.small : AppSpacing.medium)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.xLarge)
                .fill(Color.white.opacity(0.95))
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.xLarge)
                        .stroke(InonuPalette.cardBorder, lineWidth: 1)
                )
                .shadow(color: AppShadow.card, radius: 8, x: 0, y: 4)
        )
    }

    @ViewBuilder
    private var logoView: some View {
        if let uiImage = UIImage(named: "logo-img") {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
        } else if let path = Bundle.main.path(forResource: "logo-img", ofType: "png"),
                  let fileImage = UIImage(contentsOfFile: path) {
            Image(uiImage: fileImage)
                .resizable()
                .scaledToFit()
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(InonuPalette.cream)
                Text("Logo Yuklenemedi")
                    .font(.caption2.bold())
                    .foregroundStyle(InonuPalette.deepNavy)
            }
        }
    }
}

// MARK: - Surface Card
struct SurfaceCard<Content: View>: View {
    var accentColor: Color? = nil
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            content
        }
        .padding(AppSpacing.large)
        .background(Color.white.opacity(0.97))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.large))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.large)
                .stroke(InonuPalette.cardBorder, lineWidth: 1)
        )
        .overlay(alignment: .topLeading) {
            if let accent = accentColor {
                RoundedRectangle(cornerRadius: AppRadius.large)
                    .fill(accent)
                    .frame(width: 4)
                    .padding(.vertical, 12)
            }
        }
        .shadow(color: AppShadow.card, radius: 10, x: 0, y: 4)
    }
}

// MARK: - Glass Top Bar
struct GlassTopBar: View {
    let title: String
    let subtitle: String
    var icon: String = "cross.case.fill"
    var accentColor: Color = InonuPalette.primary

    var body: some View {
        HStack(spacing: AppSpacing.medium) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(accentColor.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .foregroundStyle(accentColor)
                    .font(.subheadline.bold())
            }
            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                Text(title)
                    .font(AppTypography.sectionTitle)
                    .foregroundStyle(InonuPalette.deepNavy)
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(AppTypography.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding(.horizontal, AppSpacing.medium)
        .padding(.vertical, AppSpacing.small + 2)
        .background(Color.white.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.large))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.large)
                .stroke(InonuPalette.cardBorder, lineWidth: 1)
        )
        .shadow(color: AppShadow.card, radius: 6, x: 0, y: 2)
    }
}

// MARK: - Status Pill
struct StatusPill: View {
    let text: String
    var color: Color = InonuPalette.primary

    var body: some View {
        Text(text)
            .font(.caption2.bold())
            .foregroundStyle(color)
            .padding(.horizontal, AppSpacing.small + 2)
            .padding(.vertical, AppSpacing.xSmall + 1)
            .background(color.opacity(0.1))
            .clipShape(Capsule())
    }
}

// MARK: - Empty State Card
struct EmptyStateCard: View {
    let title: String
    let subtitle: String

    var body: some View {
        SurfaceCard {
            VStack(spacing: 8) {
                Image(systemName: "tray")
                    .font(.title2)
                    .foregroundStyle(InonuPalette.secondary.opacity(0.6))
                Text(title)
                    .font(AppTypography.sectionTitle)
                    .foregroundStyle(InonuPalette.deepNavy)
                Text(subtitle)
                    .font(AppTypography.helper)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Loading State Card
struct LoadingStateCard: View {
    let text: String

    var body: some View {
        SurfaceCard {
            HStack(spacing: 12) {
                ProgressView()
                Text(text)
                    .font(AppTypography.helper)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Section Card Title
struct SectionCardTitle: View {
    let text: String
    let icon: String
    var color: Color = InonuPalette.deepNavy

    var body: some View {
        Label(text, systemImage: icon)
            .font(AppTypography.sectionTitle)
            .foregroundStyle(color)
    }
}

// MARK: - Metric Pill
struct MetricPill: View {
    let title: String
    let value: String
    var tint: Color = InonuPalette.primary

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.8))
            Text(value)
                .font(.subheadline.bold())
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.18))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Info Metric (for light backgrounds)
struct InfoMetric: View {
    let title: String
    let value: String
    var tint: Color = InonuPalette.primary

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.bold())
                .foregroundStyle(InonuPalette.deepNavy)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(tint.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
