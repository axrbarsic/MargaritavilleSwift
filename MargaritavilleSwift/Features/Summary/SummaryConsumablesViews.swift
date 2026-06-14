import SwiftUI

struct SummaryConsumablesTable: View {
    let report: SummaryConsumablesReport
    let onQuantityChange: ([CartSection.ID], CartConsumableItem.ID, String, Int) -> Void
    @Environment(\.interactionFeedback) private var feedback

    var body: some View {
        if !report.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Label("Расходники на склад", systemImage: "shippingbox.and.arrow.backward.fill")
                    .font(.system(size: 25, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                SummaryConsumablesPanel(title: "Всего взять", systemImage: "sum") {
                    ForEach(report.totals) { item in
                        SummaryConsumableTotalRow(item: item)
                    }
                }

                SummaryConsumablesPanel(title: "По уборщицам", systemImage: "list.bullet.rectangle.fill") {
                    ForEach(report.housekeepers) { housekeeper in
                        SummaryConsumableHousekeeperRow(
                            housekeeper: housekeeper,
                            onQuantityChange: { item, quantity in
                                feedback.confirm()
                                onQuantityChange(item.sourceCartIDs, item.id, item.title, quantity)
                            }
                        )
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 14)
            .background(.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(OceanKeyTheme.pending.opacity(0.26), lineWidth: 1)
            }
            .accessibilityElement(children: .contain)
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
    let systemImage: String
    let content: Content

    init(title: String, systemImage: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.systemImage = systemImage
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: systemImage)
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(OceanKeyTheme.secondaryText)
                .textCase(.uppercase)
                .lineLimit(1)

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
    let onQuantityChange: (SummaryConsumableLine, Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
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

            ForEach(housekeeper.items) { item in
                SummaryConsumableNeedRow(
                    item: item,
                    onQuantityChange: { quantity in onQuantityChange(item, quantity) }
                )
            }
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

private struct SummaryConsumableNeedRow: View {
    let item: SummaryConsumableLine
    let onQuantityChange: (Int) -> Void
    @State private var previewQuantity: Int?

    private var visibleQuantity: Int {
        previewQuantity ?? item.quantity
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(item.title)
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.66)

                Spacer(minLength: 8)

                Text("\(visibleQuantity)")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(OceanKeyTheme.accent)
                    .frame(minWidth: 34, alignment: .trailing)
            }

            CartConsumableQuantitySlider(
                quantity: item.quantity,
                onQuantityPreview: { previewQuantity = $0 },
                onQuantityChange: onQuantityChange
            )
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(.black.opacity(0.24), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .onChange(of: item.quantity) { _, _ in previewQuantity = nil }
    }
}
