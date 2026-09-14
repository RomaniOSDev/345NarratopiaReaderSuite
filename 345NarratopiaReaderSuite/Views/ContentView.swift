import SwiftUI

struct ContentView: View {
    @StateObject private var store = DeskStore()

    var body: some View {
        NavigationStack {
            HomeHubView()
        }
        .id(store.deskEpoch)
        .environmentObject(store)
        .tint(Palette.accent)
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("dataReset"))) { _ in
            store.objectWillChange.send()
        }
    }
}
