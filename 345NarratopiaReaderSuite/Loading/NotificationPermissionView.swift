import SwiftUI

struct NotificationPermissionView: View {
    var onAccept: () -> Void
    var onDecline: () -> Void

    var body: some View {
        GeometryReader { geometry in
            let isPortrait = geometry.size.height >= geometry.size.width
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()

                Image("BgLibrary")
                    .resizable()
                    .scaledToFill()
                    .opacity(0.22)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)

                LinearGradient(
                    colors: [
                        Color.appBackground.opacity(0.7),
                        Color.appSurface.opacity(0.4),
                        Color.appBackground.opacity(0.85)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        if isPortrait {
                            Spacer(minLength: geometry.size.height * 0.28)
                        } else {
                            Spacer(minLength: 20)
                        }
                        iconSection
                        Spacer(minLength: 22)
                        textSection
                        Spacer(minLength: 28)
                        buttonsSection
                        Spacer(minLength: isPortrait ? 20 : 24)
                    }
                    .padding(.horizontal, 24)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: geometry.size.height)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var iconSection: some View {
        ZStack {
            Circle()
                .fill(Color.appSurface.opacity(0.95))
                .frame(width: 112, height: 112)
                .overlay(
                    Circle()
                        .stroke(Color.appAccent.opacity(0.4), lineWidth: 1.2)
                )

            Image(systemName: "bell.badge.fill")
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.appPrimary, Color.appAccent],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
    }

    private var textSection: some View {
        VStack(spacing: 12) {
            Text("Enable Notifications")
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundColor(.appPrimary)
                .multilineTextAlignment(.center)
            Text("Stay updated with important news and bonus. You can change this later in Settings.")
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundColor(.appPrimary.opacity(0.72))
                .multilineTextAlignment(.center)
        }
    }

    private var buttonsSection: some View {
        VStack(spacing: 14) {
            Button(action: onAccept) {
                Text("Enable")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.appBackground)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.appPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)

            Button(action: onDecline) {
                Text("Not Now")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.appPrimary.opacity(0.8))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.appSurface.opacity(0.9))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.appAccent.opacity(0.3), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview {
    NotificationPermissionView(onAccept: {}, onDecline: {})
}
