import SwiftUI

enum HoldActionTiming {
    static let holdStartDelay: Duration = .milliseconds(140)
    static let holdWarningDelay: Duration = .milliseconds(330)
    static let minimumPressDuration: Double = 0.46
    static let maximumPressMovement: Double = 8
}

enum HoldActionPhaseFeedback: Equatable, Sendable {
    case silent
    case hapticOnly
    case full
}

struct HoldActionFeedbackProfile: Equatable, Sendable {
    var holdStart: HoldActionPhaseFeedback
    var holdWarning: HoldActionPhaseFeedback
    var holdCommit: HoldActionPhaseFeedback

    init(
        holdStart: HoldActionPhaseFeedback,
        holdWarning: HoldActionPhaseFeedback,
        holdCommit: HoldActionPhaseFeedback
    ) {
        self.holdStart = holdStart
        self.holdWarning = holdWarning
        self.holdCommit = holdCommit
    }

    init(uniform mode: HoldActionPhaseFeedback) {
        self.init(holdStart: mode, holdWarning: mode, holdCommit: mode)
    }

    static let full = HoldActionFeedbackProfile(uniform: .full)
    static let hapticOnly = HoldActionFeedbackProfile(uniform: .hapticOnly)
    static let roomCell = HoldActionFeedbackProfile(
        holdStart: .silent,
        holdWarning: .silent,
        holdCommit: .hapticOnly
    )
}

struct HoldActionTarget<Content: View>: View {
    let enabled: Bool
    let useLongPress: Bool
    let feedbackProfile: HoldActionFeedbackProfile
    let semanticLabel: String
    let onActivate: () -> Void
    @ViewBuilder let content: Content

    @Environment(\.interactionFeedback) private var feedback
    @State private var startTask: Task<Void, Never>?
    @State private var warningTask: Task<Void, Never>?
    @State private var commitTask: Task<Void, Never>?
    @State private var isPressing = false
    @State private var didCommit = false

    init(
        enabled: Bool,
        useLongPress: Bool,
        feedbackProfile: HoldActionFeedbackProfile = .full,
        semanticLabel: String,
        onActivate: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.enabled = enabled
        self.useLongPress = useLongPress
        self.feedbackProfile = feedbackProfile
        self.semanticLabel = semanticLabel
        self.onActivate = onActivate
        self.content = content()
    }

    var body: some View {
        content
            .contentShape(Rectangle())
            .accessibilityAddTraits(.isButton)
            .accessibilityLabel(semanticLabel)
            .modifier(
                HoldActionGestureModifier(
                    useLongPress: useLongPress,
                    onTap: activateTap,
                    onLongPressPressing: handlePressing,
                    onLongPress: activateLongPress
                )
            )
    }

    private func activateTap() {
        guard enabled, !useLongPress else {
            if !enabled {
                feedback.invalid()
            }
            return
        }
        feedback.tap()
        onActivate()
    }

    private func handlePressing(_ pressing: Bool) {
        guard enabled, useLongPress else { return }
        if pressing {
            guard !isPressing else { return }
            isPressing = true
            didCommit = false
            startTask?.cancel()
            warningTask?.cancel()
            commitTask?.cancel()
            startTask = Task { @MainActor in
                try? await Task.sleep(for: HoldActionTiming.holdStartDelay)
                if !Task.isCancelled {
                    holdStartFeedback()
                }
            }
            warningTask = Task { @MainActor in
                try? await Task.sleep(for: HoldActionTiming.holdWarningDelay)
                if !Task.isCancelled {
                    holdWarningFeedback()
                }
            }
            commitTask = Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(Int(HoldActionTiming.minimumPressDuration * 1000)))
                if !Task.isCancelled {
                    activateLongPress()
                }
            }
        } else {
            isPressing = false
            startTask?.cancel()
            startTask = nil
            warningTask?.cancel()
            warningTask = nil
            commitTask?.cancel()
            commitTask = nil
        }
    }

    private func activateLongPress() {
        guard enabled, useLongPress, !didCommit else { return }
        didCommit = true
        isPressing = false
        startTask?.cancel()
        startTask = nil
        warningTask?.cancel()
        warningTask = nil
        commitTask?.cancel()
        commitTask = nil
        holdCommitFeedback()
        onActivate()
    }

    private func holdStartFeedback() {
        switch feedbackProfile.holdStart {
        case .silent:
            break
        case .full:
            feedback.holdStart()
        case .hapticOnly:
            feedback.holdStartHapticOnly()
        }
    }

    private func holdWarningFeedback() {
        switch feedbackProfile.holdWarning {
        case .silent:
            break
        case .full:
            feedback.holdWarning()
        case .hapticOnly:
            feedback.holdWarningHapticOnly()
        }
    }

    private func holdCommitFeedback() {
        switch feedbackProfile.holdCommit {
        case .silent:
            break
        case .full:
            feedback.holdCommit()
        case .hapticOnly:
            feedback.holdCommitHapticOnly()
        }
    }
}

private struct HoldActionGestureModifier: ViewModifier {
    let useLongPress: Bool
    let onTap: () -> Void
    let onLongPressPressing: (Bool) -> Void
    let onLongPress: () -> Void

    func body(content: Content) -> some View {
        if useLongPress {
            content
                .onLongPressGesture(
                    minimumDuration: HoldActionTiming.minimumPressDuration,
                    maximumDistance: HoldActionTiming.maximumPressMovement,
                    pressing: onLongPressPressing,
                    perform: onLongPress
                )
        } else {
            content
                .onTapGesture(perform: onTap)
        }
    }
}
