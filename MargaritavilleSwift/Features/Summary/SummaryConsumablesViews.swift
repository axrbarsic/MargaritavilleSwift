import SwiftUI

struct SummaryConsumablesTable: View {
    let report: SummaryConsumablesReport

    var body: some View {
        if !report.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
                SummaryConsumablesPanel(title: nil, systemImage: nil) {
                    ForEach(report.totals) { item in
                        SummaryConsumableTotalRow(item: item)
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 12)
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
    let title: String?
    let systemImage: String?
    let content: Content

    init(title: String?, systemImage: String?, @ViewBuilder content: () -> Content) {
        self.title = title
        self.systemImage = systemImage
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let title, let systemImage {
                Label(title, systemImage: systemImage)
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(MatrixConsumableStyle.green)
                    .textCase(.uppercase)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }

            VStack(spacing: 10) {
                content
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, title == nil ? 16 : 14)
        .background(MatrixConsumableStyle.panelFill, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(MatrixConsumableStyle.green.opacity(0.95), lineWidth: 1.4)
        }
        .shadow(color: MatrixConsumableStyle.green.opacity(0.10), radius: 10)
    }
}

private struct SummaryConsumableTotalRow: View {
    let item: SummaryConsumableLine

    var body: some View {
        HStack(spacing: 10) {
            Text(item.title)
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(MatrixConsumableStyle.green)
                .lineLimit(1)
                .minimumScaleFactor(0.62)

            Spacer(minLength: 8)

            Text("\(item.quantity)")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(MatrixConsumableStyle.green)
                .frame(minWidth: 68, minHeight: 60)
                .background(.black.opacity(0.20), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(MatrixConsumableStyle.green.opacity(0.95), lineWidth: 1.2)
                }
        }
        .padding(.horizontal, 2)
        .padding(.vertical, 4)
    }
}
