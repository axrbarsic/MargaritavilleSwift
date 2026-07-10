import Testing
@testable import MargaritavilleSwift

@Test
func roomSwipeThresholdTargetsLastTaskZoneWithoutRequiringThePhysicalEdge() {
    #expect(SummarySwipeCommitPolicy.roomActionMenuThreshold(cellWidth: 361) == 295)
    #expect(SummarySwipeCommitPolicy.roomActionMenuThreshold(cellWidth: 393) == 320)
}

@Test
func roomSwipeThresholdStaysDeliberateOnNarrowCells() {
    #expect(SummarySwipeCommitPolicy.roomActionMenuThreshold(cellWidth: 280) == 258)
}

@Test
func roomSwipeArmsAtThresholdOrWithAConfidentPredictedFinish() {
    #expect(SummarySwipeCommitPolicy.roomActionMenuArmed(
        translation: 295,
        predictedTranslation: 295,
        cellWidth: 361
    ))
    #expect(SummarySwipeCommitPolicy.roomActionMenuArmed(
        translation: 250,
        predictedTranslation: 350,
        cellWidth: 361
    ))
    #expect(!SummarySwipeCommitPolicy.roomActionMenuArmed(
        translation: 230,
        predictedTranslation: 260,
        cellWidth: 361
    ))
}

@Test
func compactRoomSwipeThresholdFitsFourColumnMargaritavilleTiles() {
    #expect(abs(SummarySwipeCommitPolicy.compactRoomActionMenuThreshold(cellWidth: 82) - 59.04) < 0.001)
    #expect(abs(SummarySwipeCommitPolicy.compactRoomActionMenuThreshold(cellWidth: 98) - 70.56) < 0.001)
    #expect(SummarySwipeCommitPolicy.compactRoomActionMenuThreshold(cellWidth: 140) == 84)
}

@Test
func compactRoomSwipeArmsWithRightwardPredictedFinish() {
    #expect(SummarySwipeCommitPolicy.compactRoomActionMenuArmed(
        translation: 64,
        predictedTranslation: 64,
        cellWidth: 88
    ))
    #expect(SummarySwipeCommitPolicy.compactRoomActionMenuArmed(
        translation: 48,
        predictedTranslation: 84,
        cellWidth: 88
    ))
    #expect(!SummarySwipeCommitPolicy.compactRoomActionMenuArmed(
        translation: 42,
        predictedTranslation: 48,
        cellWidth: 88
    ))
}
