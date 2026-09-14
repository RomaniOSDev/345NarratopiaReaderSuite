import Charts
import SwiftUI

struct LedgerView: View {
    @EnvironmentObject private var store: DeskStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                BannerHeader(
                    image: "BannerDesk",
                    kicker: "LEDGER",
                    title: "The Record",
                    subtitle: "How the desk has been used: cards, motifs, and the atlas."
                )

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    metricTile(title: "Volumes", value: "\(store.books.count)")
                    metricTile(title: "Cards", value: "\(store.notes.count)")
                    metricTile(title: "Nodes", value: "\(store.concepts.count)")
                    metricTile(title: "Streak", value: streakLabel)
                }

                if store.notes.isEmpty && store.concepts.isEmpty {
                    EmptyPrompt(
                        title: "The ledger is blank",
                        detail: "Write cards and place atlas nodes; charts will fill as the desk is used."
                    )
                } else {
                    if volumeTallies.isEmpty == false {
                        chartPanel(title: "CARDS BY VOLUME", caption: "Index cards kept on each spine.") {
                            Chart(volumeTallies) { row in
                                BarMark(
                                    x: .value("Volume", row.shortTitle),
                                    y: .value("Cards", row.cards)
                                )
                                .foregroundStyle(Palette.accent)
                                .cornerRadius(4)
                            }
                            .chartYAxis { deskAxis() }
                            .chartXAxis { deskAxis() }
                        }
                    }

                    chartPanel(title: "CARDS, LAST 14 DAYS", caption: "When passages were written.") {
                        Chart(dayTallies) { row in
                            AreaMark(
                                x: .value("Day", row.day),
                                y: .value("Cards", row.count)
                            )
                            .foregroundStyle(Palette.accent.opacity(0.22))
                            .interpolationMethod(.catmullRom)
                            LineMark(
                                x: .value("Day", row.day),
                                y: .value("Cards", row.count)
                            )
                            .foregroundStyle(Palette.accent)
                            .interpolationMethod(.catmullRom)
                            PointMark(
                                x: .value("Day", row.day),
                                y: .value("Cards", row.count)
                            )
                            .foregroundStyle(Palette.accent)
                        }
                        .chartYAxis { deskAxis() }
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .day, count: 3)) { _ in
                                AxisGridLine()
                                    .foregroundStyle(Palette.accent.opacity(0.18))
                                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                                    .foregroundStyle(Palette.primary.opacity(0.82))
                            }
                        }
                    }

                    if motifTallies.isEmpty == false {
                        chartPanel(title: "MOTIFS", caption: "How themes gather across cards and nodes.") {
                            Chart(motifTallies) { row in
                                BarMark(
                                    x: .value("Count", row.count),
                                    y: .value("Motif", row.name)
                                )
                                .foregroundStyle(Palette.accent)
                                .cornerRadius(4)
                            }
                            .chartXAxis { deskAxis() }
                            .chartYAxis { deskAxis() }
                        }
                    }

                    if volumeTallies.contains(where: { row in row.nodes > 0 || row.cards > 0 }) {
                        chartPanel(title: "CARDS AND NODES", caption: "Journal against atlas, volume by volume.") {
                            Chart {
                                ForEach(volumeTallies) { row in
                                    BarMark(
                                        x: .value("Volume", row.shortTitle),
                                        y: .value("Count", row.cards)
                                    )
                                    .foregroundStyle(Palette.accent)
                                    .position(by: .value("Kind", "Cards"))
                                    BarMark(
                                        x: .value("Volume", row.shortTitle),
                                        y: .value("Count", row.nodes)
                                    )
                                    .foregroundStyle(Palette.primary.opacity(0.55))
                                    .position(by: .value("Kind", "Nodes"))
                                }
                            }
                            .chartYAxis { deskAxis() }
                            .chartXAxis { deskAxis() }
                            .chartLegend(position: .bottom, alignment: .leading)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .readingCanvas()
        .navigationTitle("Ledger")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func metricTile(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(ScholarType.caption)
                .tracking(1.3)
                .foregroundColor(Palette.accent)
            Text(value)
                .font(ScholarType.title)
                .foregroundColor(Palette.primary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.surface)
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Palette.accent.opacity(0.28), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func chartPanel<Content: View>(title: String, caption: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(ScholarType.caption)
                .tracking(1.4)
                .foregroundColor(Palette.accent)
            Text(caption)
                .font(ScholarType.body)
                .foregroundColor(Palette.primary.opacity(0.72))
            content()
                .frame(height: 220)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.surface)
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Palette.accent.opacity(0.28), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func deskAxis() -> some AxisContent {
        AxisMarks { _ in
            AxisGridLine()
                .foregroundStyle(Palette.accent.opacity(0.18))
            AxisValueLabel()
                .foregroundStyle(Palette.primary.opacity(0.82))
        }
    }

    private var streakLabel: String {
        let days = writingStreak
        if days == 0 { return "—" }
        if days == 1 { return "1 day" }
        return "\(days) days"
    }

    private var writingStreak: Int {
        let calendar = Calendar.current
        let marked = Set(store.notes.map { note in calendar.startOfDay(for: note.createdAt) })
        var cursor = calendar.startOfDay(for: Date())
        if marked.contains(cursor) == false {
            cursor = calendar.date(byAdding: .day, value: -1, to: cursor) ?? cursor
        }
        var streak = 0
        while marked.contains(cursor) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return streak
    }

    private var volumeTallies: [VolumeTally] {
        store.books.map { book in
            VolumeTally(
                title: book.title,
                cards: store.notes(for: book.id).count,
                nodes: store.concepts(for: book.id).count
            )
        }
    }

    private var dayTallies: [DayTally] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let counts = Dictionary(grouping: store.notes) { note in
            calendar.startOfDay(for: note.createdAt)
        }
        return (0..<14).reversed().compactMap { offset -> DayTally? in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            return DayTally(day: day, count: counts[day]?.count ?? 0)
        }
    }

    private var motifTallies: [MotifTally] {
        var buckets: [String: Int] = [:]
        for note in store.notes {
            let name = store.theme(id: note.themeId)?.name ?? "Unassigned"
            buckets[name, default: 0] += 1
        }
        for concept in store.concepts {
            let name = store.theme(id: concept.themeId)?.name ?? "Unassigned"
            buckets[name, default: 0] += 1
        }
        return buckets
            .map { MotifTally(name: $0.key, count: $0.value) }
            .sorted { lhs, rhs in lhs.count > rhs.count }
    }
}

private struct VolumeTally: Identifiable {
    var id: String { title }
    let title: String
    let cards: Int
    let nodes: Int

    var shortTitle: String {
        if title.count <= 12 { return title }
        return String(title.prefix(11)) + "…"
    }
}

private struct DayTally: Identifiable {
    var id: Date { day }
    let day: Date
    let count: Int
}

private struct MotifTally: Identifiable {
    var id: String { name }
    let name: String
    let count: Int
}
