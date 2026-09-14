import SwiftUI

extension View {
    func readingCanvas() -> some View {
        self
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                Color("AppBackground").overlay {
                    Image("BgLibrary")
                        .resizable()
                        .scaledToFill()
                        .opacity(0.32)
                }
                .clipped()
                .ignoresSafeArea()
            }
            .scrollDismissesKeyboard(.interactively)
    }
}
