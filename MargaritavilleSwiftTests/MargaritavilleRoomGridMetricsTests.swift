import CoreGraphics
import Testing
@testable import MargaritavilleSwift

@Test
func canonicalRoomRowsUniformlyScaleTheirCompleteDesignSurface() {
    let containerWidth: CGFloat = 430
    let tileHeight: CGFloat = 98
    let four = MargaritavilleRoomRowMetrics.resolve(
        containerWidth: containerWidth,
        columnCount: .four,
        baselineTileHeight: tileHeight
    )
    let three = MargaritavilleRoomRowMetrics.resolve(
        containerWidth: containerWidth,
        columnCount: .three,
        baselineTileHeight: tileHeight
    )

    #expect(abs(four.rowScale - 1) < 0.000_001)
    #expect(abs((four.rowDesignWidth * four.rowScale) - containerWidth) < 0.000_001)
    #expect(abs((three.rowDesignWidth * three.rowScale) - containerWidth) < 0.000_001)
    #expect(abs(three.baselineTileWidth - four.baselineTileWidth) < 0.000_001)
    #expect(abs((three.scaledRowHeight / tileHeight) - three.rowScale) < 0.000_001)
    #expect(abs(
        (three.scaledVerticalGap / MargaritavilleRoomGridLayout.verticalGap)
            - three.rowScale
    ) < 0.000_001)
    #expect(abs(
        ((MargaritavilleRoomGridLayout.horizontalGap * three.rowScale)
            / (three.baselineTileWidth * three.rowScale))
            - (MargaritavilleRoomGridLayout.horizontalGap / three.baselineTileWidth)
    ) < 0.000_001)
    #expect(abs(
        ((MargaritavilleRoomGridLayout.horizontalInset * three.rowScale)
            / (three.baselineTileWidth * three.rowScale))
            - (MargaritavilleRoomGridLayout.horizontalInset / three.baselineTileWidth)
    ) < 0.000_001)
}
