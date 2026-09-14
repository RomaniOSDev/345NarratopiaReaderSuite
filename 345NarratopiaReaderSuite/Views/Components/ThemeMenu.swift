import SwiftUI

struct ThemeMenu: View {
    @EnvironmentObject private var store: DeskStore
    @Binding var themeId: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("MOTIF")
                .font(ScholarType.caption)
                .tracking(1.4)
                .foregroundColor(Palette.accent)
            Menu {
                Button("None") {
                    themeId = nil
                }
                ForEach(store.themes) { theme in
                    Button(theme.name) {
                        themeId = theme.id
                    }
                }
            } label: {
                HStack {
                    Text(currentName)
                        .font(ScholarType.body)
                        .foregroundColor(Palette.primary)
                    Spacer()
                    Text("Choose")
                        .font(ScholarType.caption)
                        .foregroundColor(Palette.accent)
                }
                .padding(12)
                .background(Palette.background.opacity(0.55))
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Palette.accent.opacity(0.24), lineWidth: 1)
                }
            }
        }
    }

    private var currentName: String {
        store.theme(id: themeId)?.name ?? "Unassigned"
    }
}

struct StatusMenu: View {
    @Binding var status: ReadingStatus

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("READING")
                .font(ScholarType.caption)
                .tracking(1.4)
                .foregroundColor(Palette.accent)
            Menu {
                ForEach(ReadingStatus.allCases) { item in
                    Button(item.label) {
                        status = item
                    }
                }
            } label: {
                HStack {
                    Text(status.label)
                        .font(ScholarType.body)
                        .foregroundColor(Palette.primary)
                    Spacer()
                    Text("Set")
                        .font(ScholarType.caption)
                        .foregroundColor(Palette.accent)
                }
                .padding(12)
                .background(Palette.background.opacity(0.55))
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Palette.accent.opacity(0.24), lineWidth: 1)
                }
            }
        }
    }
}
