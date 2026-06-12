import SwiftUI

extension AnyTransition {
    static var roomActionMenuLamp: AnyTransition {
        .asymmetric(
            insertion: .modifier(
                active: RoomActionMenuLampModifier(progress: 0),
                identity: RoomActionMenuLampModifier(progress: 1)
            ),
            removal: .modifier(
                active: RoomActionMenuLampModifier(progress: 0),
                identity: RoomActionMenuLampModifier(progress: 1)
            )
        )
    }
}

private struct RoomActionMenuLampModifier: ViewModifier, @preconcurrency Animatable {
    var progress: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func body(content: Content) -> some View {
        let eased = 1 - pow(1 - min(max(progress, 0), 1), 3)
        content
            .scaleEffect(x: 0.68 + eased * 0.32, y: 0.08 + eased * 0.92, anchor: .top)
            .offset(y: -10 * (1 - eased))
            .blur(radius: 2.8 * (1 - eased))
            .opacity(0.30 + 0.70 * eased)
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: 13 + 10 * (1 - eased),
                    bottomTrailingRadius: 13 + 10 * (1 - eased),
                    topTrailingRadius: 0,
                    style: .continuous
                )
            )
    }
}
