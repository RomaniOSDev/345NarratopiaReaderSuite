import SwiftUI

struct ChapterPanel: View {
    let chapter: String
    let title: String
    let blurb: String
    let metric: String
    let banner: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Image(banner)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 108)
                .clipped()

            Rectangle()
                .fill(Palette.accent)
                .frame(height: 1)

            VStack(alignment: .leading, spacing: 8) {
                Text(chapter)
                    .font(ScholarType.chapter)
                    .tracking(ScholarType.chapterTracking)
                    .foregroundColor(Palette.accent)
                Text(title)
                    .font(ScholarType.title)
                    .tracking(ScholarType.titleTracking)
                    .foregroundColor(Palette.primary)
                Text(blurb)
                    .font(ScholarType.body)
                    .foregroundColor(Palette.primary.opacity(0.74))
                    .fixedSize(horizontal: false, vertical: true)
                HStack {
                    Text(metric)
                        .font(ScholarType.caption)
                        .foregroundColor(Palette.accent)
                    Spacer()
                    Text("Open →")
                        .font(ScholarType.caption)
                        .foregroundColor(Palette.accent.opacity(0.85))
                }
                .padding(.top, 4)
            }
            .padding(16)
        }
        .background(Palette.surface)
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Palette.accent.opacity(0.35), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
