import SwiftUI

struct EmptyPrompt: View {
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(ScholarType.cardTitle)
                .tracking(0.8)
                .foregroundColor(Palette.primary)
            Text(detail)
                .font(ScholarType.body)
                .foregroundColor(Palette.primary.opacity(0.72))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.surface)
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Palette.accent.opacity(0.28), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
