import SwiftUI

struct HoldActionTarget<Content: View>: View {
    let enabled: Bool
    let useLongPress: Bool
    let semanticLabel: String
    let onActivate: () -> Void
    @ViewBuilder let content: Content

    @Environment(\.interactionFeedback) private var feedback
    @State private var startTask: Task<Void, Never>?
    @State private var warningTask: Task<Void, Never>?

    var body: some View {
        content
            .contentShape(Rectangle())
            .accessibilityAddTraits(.isButton)
            .accessibilityLabel(semanticLabel)
            .modifier(
                HoldActionGestureModifier(
                    enabled: enabled,
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
            startTask?.cancel()
            warningTask?.cancel()
            startTask = Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(140))
                if !Task.isCancelled {
                    feedback.holdStart()
                }
            }
            warningTask = Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(330))
                if !Task.isCancelled {
                    feedback.holdWarning()
                }
            }
        } else {
            startTask?.cancel()
            startTask = nil
            warningTask?.cancel()
            warningTask = nil
        }
    }

    private func activateLongPress() {
        guard enabled, useLongPress else { return }
        startTask?.cancel()
        startTask = nil
        warningTask?.cancel()
        warningTask = nil
        feedback.holdCommit()
        onActivate()
    }
}

private struct HoldActionGestureModifier: ViewModifier {
    let enabled: Bool
    let useLongPress: Bool
    let onTap: () -> Void
    let onLongPressPressing: (Bool) -> Void
    let onLongPress: () -> Void

    func body(content: Content) -> some View {
        if useLongPress {
            content
                .onLongPressGesture(
                    minimumDuration: 0.46,
                    maximumDistance: 8,
                    pressing: onLongPressPressing,
                    perform: onLongPress
                )
        } else {
            content
                .onTapGesture(perform: onTap)
        }
    }
}
