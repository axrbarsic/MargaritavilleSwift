import Foundation

struct BrooklynAnimationTimeline: Equatable {
    private(set) var elapsedTime: TimeInterval = 0
    private(set) var isActive = false
    private var lastTimestamp: TimeInterval?

    mutating func setActive(_ active: Bool, at timestamp: TimeInterval) {
        guard active != isActive else {
            if active, lastTimestamp == nil {
                lastTimestamp = timestamp
            }
            return
        }
        isActive = active
        lastTimestamp = active ? timestamp : nil
    }

    @discardableResult
    mutating func advance(to timestamp: TimeInterval) -> TimeInterval {
        guard isActive else { return elapsedTime }
        guard let lastTimestamp else {
            self.lastTimestamp = timestamp
            return elapsedTime
        }
        guard timestamp >= lastTimestamp else {
            self.lastTimestamp = timestamp
            return elapsedTime
        }
        elapsedTime += timestamp - lastTimestamp
        self.lastTimestamp = timestamp
        return elapsedTime
    }
}
