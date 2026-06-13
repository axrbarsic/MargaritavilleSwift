import SwiftUI

struct SummaryConsumablesTable: View {
    let report: SummaryConsumablesReport

    var body: some View {
        if !report.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
                Text("Расходники")
                    .font(.system(size: 25, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                SummaryConsumablesPanel(title: "Всего на тележки") {
                    ForEach(report.totals) { item in
                        SummaryConsumableTotalRow(item: item)
                    }
                }

                SummaryConsumablesPanel(title: "По уборщицам") {
                    ForEach(report.housekeepers) { housekeeper in
                        SummaryConsumableHousekeeperRow(housekeeper: housekeeper)
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 10)
        }
    }
}

struct SummaryConsumableTicker: View {
    let text: String
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isAnimating = false

    var body: some View {
        GeometryReader { proxy in
            let availableWidth = max(proxy.size.width, 1)
            let estimatedTextWidth = max(CGFloat(text.count) * 11, availableWidth)
            let travel = availableWidth + estimatedTextWidth

            HStack(spacing: 18) {
                tickerText
                if !reduceMotion {
                    tickerText
                }
            }
            .offset(x: reduceMotion ? 8 : (isAnimating ? -estimatedTextWidth : availableWidth))
            .animation(
                reduceMotion ? nil : .linear(duration: max(Double(travel) / 34.0, 4.0))
                    .repeatForever(autoreverses: false),
                value: isAnimating
            )
            .onAppear {
                isAnimating = !reduceMotion
            }
            .onChange(of: text) { _, _ in
                guard !reduceMotion else {
                    isAnimating = false
                    return
                }
                isAnimating = false
                Task { @MainActor in
                    isAnimating = true
                }
            }
        }
        .frame(height: 30)
        .clipShape(Capsule())
        .background(.black.opacity(0.24), in: Capsule())
        .overlay {
            Capsule()
                .stroke(OceanKeyTheme.pending.opacity(0.34), lineWidth: 1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Нужны расходники: \(text)")
    }

    private var tickerText: some View {
        HStack(spacing: 6) {
            Image(systemName: "shippingbox.fill")
                .font(.system(size: 12, weight: .black))
            Text(text)
                .font(.system(size: 14, weight: .black, design: .rounded))
                .lineLimit(1)
        }
        .foregroundStyle(OceanKeyTheme.pending)
        .shadow(color: .black.opacity(0.8), radius: 1.2, x: 0, y: 1)
    }
}

private struct SummaryConsumablesPanel<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(OceanKeyTheme.secondaryText)

            VStack(spacing: 7) {
                content
            }
        }
        .padding(12)
        .background(.black.opacity(0.34), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(OceanKeyTheme.accent.opacity(0.24), lineWidth: 1)
        }
    }
}

private struct SummaryConsumableTotalRow: View {
    let item: SummaryConsumableLine

    var body: some View {
        HStack(spacing: 10) {
            Text(item.title)
                .font(.system(size: 17, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            Spacer(minLength: 8)

            Text("\(item.quantity)")
                .font(.system(size: 24, weight: .black, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.black)
                .frame(minWidth: 50, minHeight: 34)
                .background(OceanKeyTheme.pending, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 8)
        .background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct SummaryConsumableHousekeeperRow: View {
    let housekeeper: SummaryHousekeeperConsumables

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 8) {
                Text(housekeeper.displayName)
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(palette)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Spacer(minLength: 8)

                Text(housekeeper.locationLabel)
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.62)
            }

            FlexibleConsumableTags(items: housekeeper.items)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 9)
        .background(palette.opacity(0.10), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(palette.opacity(0.28), lineWidth: 1)
        }
    }

    private var palette: Color {
        housekeeper.palette?.color ?? OceanKeyTheme.accent
    }
}

private struct FlexibleConsumableTags: View {
    let items: [SummaryConsumableLine]

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 6) {
                ForEach(items) { item in
                    SummaryConsumableTag(item: item)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                ForEach(items) { item in
                    SummaryConsumableTag(item: item)
                }
            }
        }
    }
}

private struct SummaryConsumableTag: View {
    let item: SummaryConsumableLine

    var body: some View {
        HStack(spacing: 5) {
            Text(item.title)
                .lineLimit(1)
                .minimumScaleFactor(0.76)
            Text("\(item.quantity)")
                .monospacedDigit()
                .foregroundStyle(.black)
                .padding(.horizontal, 7)
                .padding(.vertical, 2)
                .background(OceanKeyTheme.pending, in: Capsule())
        }
        .font(.system(size: 13, weight: .black, design: .rounded))
        .foregroundStyle(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(.black.opacity(0.32), in: Capsule())
    }
}
