import SwiftUI

struct InlineField: View {
    let caption: String
    let placeholder: String
    @Binding var text: String
    var warning: String?
    var tall: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(caption)
                .font(ScholarType.caption)
                .tracking(1.4)
                .foregroundColor(Palette.accent)
            Group {
                if tall {
                    TextEditor(text: $text)
                        .font(ScholarType.body)
                        .foregroundColor(Palette.primary)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 120)
                } else {
                    TextField(placeholder, text: $text)
                        .font(ScholarType.body)
                        .foregroundColor(Palette.primary)
                }
            }
            .padding(12)
            .background(Palette.background.opacity(0.55))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(warning == nil ? Palette.accent.opacity(0.24) : Palette.accent, lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            if let warning {
                Text(warning)
                    .font(ScholarType.caption)
                    .foregroundColor(Palette.accent)
            }
        }
    }
}
