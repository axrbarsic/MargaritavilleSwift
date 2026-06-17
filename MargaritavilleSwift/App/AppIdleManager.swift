import Foundation
import Observation

@Observable
@MainActor
final class AppIdleManager {
    private(set) var idleSeconds = 0
    var isIdle = false

    private var timer: Timer?
    private var timeoutSeconds: Int = 30

    init() {}

    func startTracking(timeout: Int) {
        self.timeoutSeconds = timeout
        self.idleSeconds = 0
        self.isIdle = false

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.tick()
            }
        }
    }

    func updateTimeout(_ timeout: Int) {
        self.timeoutSeconds = timeout
        if idleSeconds >= timeout {
            isIdle = true
        } else {
            isIdle = false
        }
    }

    func stopTracking() {
        timer?.invalidate()
        timer = nil
        isIdle = false
        idleSeconds = 0
    }

    func resetActivity() {
        idleSeconds = 0
        if isIdle {
            isIdle = false
        }
    }

    private func tick() {
        idleSeconds += 1
        if idleSeconds >= timeoutSeconds && !isIdle {
            isIdle = true
        }
    }
}
