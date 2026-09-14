import SwiftUI

struct BannerHeader: View {
    let image: String
    let kicker: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Image(image)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 124)
                .clipped()

            Rectangle()
                .fill(Palette.accent)
                .frame(height: 1)

            VStack(alignment: .leading, spacing: 6) {
                Text(kicker)
                    .font(ScholarType.chapter)
                    .tracking(ScholarType.chapterTracking)
                    .foregroundColor(Palette.accent)
                Text(title)
                    .font(ScholarType.title)
                    .tracking(ScholarType.titleTracking)
                    .foregroundColor(Palette.primary)
                Text(subtitle)
                    .font(ScholarType.body)
                    .foregroundColor(Palette.primary.opacity(0.74))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.surface)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Palette.accent.opacity(0.28), lineWidth: 1)
        }
    }
}
