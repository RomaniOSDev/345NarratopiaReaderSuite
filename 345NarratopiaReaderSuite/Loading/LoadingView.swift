import SwiftUI

struct LoadingAmbientField: View {
    @State private var drift = false

    var body: some View {
        ZStack {
            Color.appBackground

            Image("BgLibrary")
                .resizable()
                .scaledToFill()
                .opacity(0.28)
                .allowsHitTesting(false)

            LinearGradient(
                colors: [
                    Color.appBackground.opacity(0.55),
                    Color.appSurface.opacity(0.35),
                    Color.appBackground.opacity(0.75)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            RadialGradient(
                colors: [
                    Color.appPrimary.opacity(0.22),
                    Color.appAccent.opacity(0.08),
                    .clear
                ],
                center: UnitPoint(x: 0.5, y: 0.28),
                startRadius: 12,
                endRadius: 340
            )

            Ellipse()
                .fill(Color.appPrimary.opacity(0.14))
                .frame(width: 280, height: 180)
                .blur(radius: 70)
                .offset(x: drift ? 28 : -22, y: drift ? -150 : -110)

            Ellipse()
                .fill(Color.appSurface.opacity(0.55))
                .frame(width: 260, height: 220)
                .blur(radius: 64)
                .offset(x: drift ? -40 : 36, y: drift ? 220 : 180)

            ForEach(0..<7, id: \.self) { index in
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(Color.appAccent.opacity(0.12 + Double(index % 3) * 0.05), lineWidth: 1)
                    .frame(width: CGFloat(54 + index * 8), height: CGFloat(36 + index * 4))
                    .rotationEffect(.degrees(Double(index) * 11 - 18))
                    .offset(
                        x: cardX(index) + (drift ? 6 : -6),
                        y: cardY(index) + (drift ? -8 : 8)
                    )
                    .blur(radius: index % 2 == 0 ? 0.2 : 0.8)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.easeInOut(duration: 5.2).repeatForever(autoreverses: true)) {
                drift = true
            }
        }
    }

    private func cardX(_ index: Int) -> CGFloat {
        let values: [CGFloat] = [-130, 120, -90, 150, -40, 70, -160]
        return values[index % values.count]
    }

    private func cardY(_ index: Int) -> CGFloat {
        let values: [CGFloat] = [-220, -160, 40, 120, 200, -80, 160]
        return values[index % values.count]
    }
}

struct LoadingDeskMark: View {
    @State private var pulse = false
    @State private var orbit = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    AngularGradient(
                        colors: [
                            Color.appPrimary.opacity(0.05),
                            Color.appPrimary,
                            Color.appAccent,
                            Color.appPrimary.opacity(0.15)
                        ],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 2.2, lineCap: .round, dash: [5, 9])
                )
                .frame(width: 188, height: 188)
                .rotationEffect(.degrees(orbit ? 360 : 0))

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.appPrimary.opacity(0.28),
                            Color.appSurface,
                            Color.appBackground.opacity(0.95)
                        ],
                        center: .center,
                        startRadius: 6,
                        endRadius: 90
                    )
                )
                .frame(width: 156, height: 156)
                .overlay(
                    Circle()
                        .stroke(Color.appAccent.opacity(0.45), lineWidth: 1.2)
                )
                .shadow(color: Color.appPrimary.opacity(pulse ? 0.45 : 0.2), radius: pulse ? 22 : 12)

            VStack(spacing: 10) {
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.appPrimary, Color.appAccent],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .scaleEffect(pulse ? 1.05 : 0.96)

                Text("DESK")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(3.2)
                    .foregroundStyle(Color.appPrimary)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                pulse = true
            }
            withAnimation(.linear(duration: 14).repeatForever(autoreverses: false)) {
                orbit = true
            }
        }
    }
}

struct LoadingHeroPlate: View {
    @State private var glow = false

    var body: some View {
        VStack(spacing: 22) {
            Text("NARRATOPIA")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .tracking(4)
                .foregroundStyle(Color.appAccent)

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.appSurface.opacity(0.96))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.appPrimary.opacity(0.7),
                                        Color.appAccent.opacity(0.35),
                                        Color.appPrimary.opacity(0.15)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.2
                            )
                    )
                    .shadow(color: Color.appPrimary.opacity(glow ? 0.35 : 0.16), radius: glow ? 28 : 14, y: 10)

                HStack(spacing: 0) {
                    Rectangle()
                        .fill(Color.appAccent)
                        .frame(width: 4)

                    Spacer(minLength: 0)

                    LoadingDeskMark()
                        .padding(.vertical, 28)

                    Spacer(minLength: 0)
                }
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .frame(width: 280, height: 260)

            VStack(spacing: 8) {
                Text("READING DESK")
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .tracking(2.4)
                    .foregroundStyle(Color.appPrimary)

                Text("Volumes, passages, and a quiet atlas.")
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundStyle(Color.appPrimary.opacity(0.72))
                    .multilineTextAlignment(.center)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                glow = true
            }
        }
    }
}

struct LoadingProgressBar: View {
    @State private var phase: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.appSurface.opacity(0.9))
                    .overlay(
                        Capsule()
                            .stroke(Color.appAccent.opacity(0.28), lineWidth: 1)
                    )

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.appPrimary, Color.appAccent, Color.appPrimary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(width * 0.36, 34))
                    .offset(x: phase * (width * 0.64))
                    .shadow(color: Color.appPrimary.opacity(0.55), radius: 8, y: 0)
            }
        }
        .frame(height: 6)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.3).repeatForever(autoreverses: true)) {
                phase = 1
            }
        }
    }
}

struct LoadingStatusLine: View {
    @State private var step = 0

    private let lines = [
        "Opening the reading desk",
        "Gathering quiet spines",
        "Threading the atlas"
    ]

    var body: some View {
        Text(lines[step % lines.count])
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .tracking(0.6)
            .foregroundStyle(Color.appPrimary.opacity(0.8))
            .multilineTextAlignment(.center)
            .id(step)
            .transition(.opacity.combined(with: .move(edge: .bottom)))
            .task {
                while !Task.isCancelled {
                    try? await Task.sleep(nanoseconds: 1_700_000_000)
                    guard !Task.isCancelled else { return }
                    withAnimation(.easeInOut(duration: 0.32)) {
                        step = (step + 1) % lines.count
                    }
                }
            }
    }
}

struct LoadingView: View {
    @State private var appeared = false

    var body: some View {
        ZStack {
            LoadingAmbientField()

            VStack(spacing: 0) {
                Spacer(minLength: 0)

                LoadingHeroPlate()
                    .opacity(appeared ? 1 : 0)
                    .scaleEffect(appeared ? 1 : 0.92)
                    .offset(y: appeared ? 0 : 18)

                VStack(spacing: 14) {
                    LoadingProgressBar()
                        .frame(width: 168)
                        .opacity(appeared ? 1 : 0)

                    LoadingStatusLine()
                        .opacity(appeared ? 1 : 0)
                }
                .padding(.top, 28)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 28)
        }
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation(.spring(response: 0.72, dampingFraction: 0.82)) {
                appeared = true
            }
        }
    }
}

#Preview {
    LoadingView()
}
