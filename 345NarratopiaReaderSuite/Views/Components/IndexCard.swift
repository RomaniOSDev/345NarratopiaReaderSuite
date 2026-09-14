import SwiftUI

struct IndexCard<Accessory: View>: View {
    let title: String
    let detail: String
    let motif: String?
    let emphasized: Bool
    let accessory: Accessory

    init(
        title: String,
        detail: String,
        motif: String? = nil,
        emphasized: Bool = false,
        @ViewBuilder accessory: () -> Accessory
    ) {
        self.title = title
        self.detail = detail
        self.motif = motif
        self.emphasized = emphasized
        self.accessory = accessory()
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Rectangle()
                .fill(Palette.accent)
                .frame(width: 3)

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(ScholarType.cardTitle)
                    .foregroundColor(Palette.primary)
                    .fixedSize(horizontal: false, vertical: true)
                if detail.isEmpty == false {
                    Text(detail)
                        .font(ScholarType.body)
                        .foregroundColor(Palette.primary.opacity(0.72))
                        .lineLimit(3)
                }
                if let motif, motif.isEmpty == false {
                    Text(motif)
                        .font(ScholarType.caption)
                        .tracking(1.2)
                        .foregroundColor(Palette.accent)
                }
            }

            Spacer(minLength: 8)
            accessory
        }
        .padding(14)
        .background(Palette.surface)
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(emphasized ? Palette.accent : Palette.accent.opacity(0.22), lineWidth: emphasized ? 1.4 : 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

extension IndexCard where Accessory == EmptyView {
    init(title: String, detail: String, motif: String? = nil, emphasized: Bool = false) {
        self.init(title: title, detail: detail, motif: motif, emphasized: emphasized) {
            EmptyView()
        }
    }
}
