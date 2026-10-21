import SwiftUI

enum MargaritavilleGridColumnCount: Int, CaseIterable, Codable, Identifiable, Sendable {
    case three = 3
    case four = 4

    var id: Int { rawValue }
    var title: String { "\(rawValue)" }
}

enum MargaritavilleRoomGridLayout {
    static let horizontalInset: CGFloat = 16
    static let horizontalGap: CGFloat = 8
    static let verticalGap: CGFloat = 8
    static let fallbackContainerWidth: CGFloat = 408
}

struct MargaritavilleRoomRowMetrics: Equatable, Sendable {
    let availableWidth: CGFloat
    let baselineTileWidth: CGFloat
    let baselineTileHeight: CGFloat
    let rowDesignWidth: CGFloat
    let rowScale: CGFloat

    var scaledRowHeight: CGFloat {
        baselineTileHeight * rowScale
    }

    var scaledVerticalGap: CGFloat {
        MargaritavilleRoomGridLayout.verticalGap * rowScale
    }

    static func resolve(
        containerWidth: CGFloat,
        columnCount: MargaritavilleGridColumnCount,
        baselineTileHeight: CGFloat
    ) -> MargaritavilleRoomRowMetrics {
        let availableWidth = containerWidth > 0
            ? containerWidth
            : MargaritavilleRoomGridLayout.fallbackContainerWidth
        let inset = MargaritavilleRoomGridLayout.horizontalInset
        let horizontalGap = MargaritavilleRoomGridLayout.horizontalGap
        let baselineTileWidth = max(
            0,
            availableWidth - (2 * inset) - (3 * horizontalGap)
        ) / 4
        let rowDesignWidth = (2 * inset)
            + (CGFloat(columnCount.rawValue) * baselineTileWidth)
            + (CGFloat(columnCount.rawValue - 1) * horizontalGap)
        let rowScale = rowDesignWidth > 0 ? availableWidth / rowDesignWidth : 1
        return MargaritavilleRoomRowMetrics(
            availableWidth: availableWidth,
            baselineTileWidth: baselineTileWidth,
            baselineTileHeight: baselineTileHeight,
            rowDesignWidth: rowDesignWidth,
            rowScale: rowScale
        )
    }
}

private struct MargaritavilleRoomBaselineTileWidthKey: EnvironmentKey {
    static let defaultValue: CGFloat = 88
}

extension EnvironmentValues {
    var margaritavilleRoomBaselineTileWidth: CGFloat {
        get { self[MargaritavilleRoomBaselineTileWidthKey.self] }
        set { self[MargaritavilleRoomBaselineTileWidthKey.self] = newValue }
    }
}

struct MargaritavilleRoomGrid<Item: Identifiable, Tile: View>: View where Item.ID: Hashable {
    let items: [Item]
    let geometry: RoomCellGeometry
    let columnCount: MargaritavilleGridColumnCount
    let tile: (Item) -> Tile
    @State private var containerWidth: CGFloat = 0

    init<Data: RandomAccessCollection>(
        _ items: Data,
        geometry: RoomCellGeometry,
        columnCount: MargaritavilleGridColumnCount,
        @ViewBuilder tile: @escaping (Item) -> Tile
    ) where Data.Element == Item {
        self.items = Array(items)
        self.geometry = geometry
        self.columnCount = columnCount
        self.tile = tile
    }

    var body: some View {
        LazyVStack(alignment: .leading, spacing: metrics.scaledVerticalGap) {
            ForEach(rows.indices, id: \.self) { rowIndex in
                canonicalRow(items: rows[rowIndex])
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            GeometryReader { proxy in
                Color.clear
                    .onAppear { containerWidth = proxy.size.width }
                    .onChange(of: proxy.size.width) { _, width in containerWidth = width }
            }
        }
    }

    private func canonicalRow(items rowItems: [Item]) -> some View {
        HStack(alignment: .top, spacing: MargaritavilleRoomGridLayout.horizontalGap) {
            ForEach(rowItems) { item in
                tile(item)
                    .environment(
                        \.margaritavilleRoomBaselineTileWidth,
                        metrics.baselineTileWidth
                    )
                    .frame(
                        width: metrics.baselineTileWidth,
                        height: metrics.baselineTileHeight,
                        alignment: .topLeading
                    )
            }
        }
        .padding(.horizontal, MargaritavilleRoomGridLayout.horizontalInset)
        .frame(
            width: metrics.rowDesignWidth,
            height: metrics.baselineTileHeight,
            alignment: .topLeading
        )
        .scaleEffect(metrics.rowScale, anchor: .topLeading)
        .frame(
            width: metrics.availableWidth,
            height: metrics.scaledRowHeight,
            alignment: .topLeading
        )
    }

    private var rows: [[Item]] {
        stride(from: 0, to: items.count, by: columnCount.rawValue).map { start in
            Array(items[start..<min(start + columnCount.rawValue, items.count)])
        }
    }

    private var metrics: MargaritavilleRoomRowMetrics {
        MargaritavilleRoomRowMetrics.resolve(
            containerWidth: containerWidth,
            columnCount: columnCount,
            baselineTileHeight: geometry.margaritavilleTileHeight
        )
    }
}
