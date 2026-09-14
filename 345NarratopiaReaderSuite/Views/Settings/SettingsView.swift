import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: DeskStore
    @State private var confirmReset = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                BannerHeader(
                    image: "BannerDesk",
                    kicker: "DESK",
                    title: "Preferences",
                    subtitle: "Review, read the policies, or clear this study."
                )

                settingsRow(title: "Rate Us", detail: "Leave a quiet mark if the desk helps.") {
                    AppLinks.requestReview()
                }
                settingsRow(title: "Privacy", detail: "How this study keeps its pages.") {
                    AppLinks.open(AppLinks.privacy)
                }
                settingsRow(title: "Terms", detail: "The agreement for using this desk.") {
                    AppLinks.open(AppLinks.terms)
                }

                DeskButton(title: "Reset All Data", emphasized: false) {
                    confirmReset = true
                }
            }
            .padding(20)
        }
        .readingCanvas()
        .navigationTitle("Desk")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Erase every volume, card, and thread?", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("Reset All Data", role: .destructive) {
                store.resetAllData()
            }
            Button("Keep", role: .cancel) {}
        }
    }

    private func settingsRow(title: String, detail: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            IndexCard(title: title, detail: detail) {
                Text("Open")
                    .font(ScholarType.caption)
                    .foregroundColor(Palette.accent)
            }
        }
        .buttonStyle(.plain)
    }
}
