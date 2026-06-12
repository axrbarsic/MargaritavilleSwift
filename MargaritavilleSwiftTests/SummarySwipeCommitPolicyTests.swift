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
