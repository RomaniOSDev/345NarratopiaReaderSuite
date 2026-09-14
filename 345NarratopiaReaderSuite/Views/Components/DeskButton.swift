import SwiftUI

struct DeskButton: View {
    let title: String
    var emphasized: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(ScholarType.cardTitle)
                .tracking(0.6)
                .foregroundColor(emphasized ? Palette.background : Palette.accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(emphasized ? Palette.accent : Palette.surface)
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Palette.accent, lineWidth: 1)
                }
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
        .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
