import CoreGraphics

enum SummarySwipeCommitPolicy {
    static func roomActionMenuThreshold(cellWidth: CGFloat) -> CGFloat {
        let width = max(cellWidth, 280)
        let targetToLastTask = width - 66
        return min(max(targetToLastTask, 258), 320)
    }

    static func roomActionMenuProgress(translation: CGFloat, cellWidth: CGFloat) -> CGFloat {
        let threshold = roomActionMenuThreshold(cellWidth: cellWidth)
        return min(max(translation / threshold, 0), 1)
    }

    static func roomActionMenuArmed(translation: CGFloat, predictedTranslation: CGFloat, cellWidth: CGFloat) -> Bool {
        let committedTranslation = max(translation, predictedTranslation * 0.86)
        return committedTranslation >= roomActionMenuThreshold(cellWidth: cellWidth)
    }
}
