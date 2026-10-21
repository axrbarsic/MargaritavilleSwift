import SwiftUI
import UIKit

struct RoomSelectionHDRFlashEvent: Equatable, Sendable {
    static let envelope = RoomHDRPulseEnvelope(
        riseDuration: 0.045,
        peakTime: 0.085,
        fadeDuration: 1.8,
        cleanupTime: 1.95,
        brightnessMultiplier: 3.6
    )

    let generation: Int
    let roomID: RoomID
    let palette: HousekeeperPalette
    let startedAt: Date

    func isActive(at date: Date) -> Bool {
        Self.envelope.isActive(startedAt: startedAt, now: date)
    }
}

struct WorkSetupRoomBoundsPreferenceKey: PreferenceKey {
    static let defaultValue: [RoomID: Anchor<CGRect>] = [:]

    static func reduce(
        value: inout [RoomID: Anchor<CGRect>],
        nextValue: () -> [RoomID: Anchor<CGRect>]
    ) {
        value.merge(nextValue(), uniquingKeysWith: { _, latest in latest })
    }
}

struct WorkSetupSelectionHDRFlashOverlay: View {
    let events: [RoomID: RoomSelectionHDRFlashEvent]
    let bounds: [RoomID: Anchor<CGRect>]
    let layout: HotelSummaryLayout

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { proxy in
            TimelineView(.animation(minimumInterval: 1.0 / 120.0, paused: events.isEmpty)) { timeline in
                flashLayers(fragments: fragments(at: timeline.date, proxy: proxy))
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func flashLayers(fragments: [WorkSetupSelectionHDRFragment]) -> some View {
        ZStack(alignment: .topLeading) {
            WorkSetupSelectionHDRCanvas(fragments: fragments)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            ForEach(fragments, id: \.roomID) { fragment in
                WorkSetupRoomNumberForeground(room: fragment.roomID, layout: layout)
                    .foregroundStyle(OceanKeyTheme.roomForeground)
                    .frame(width: fragment.frame.width, height: fragment.frame.height)
                    .position(x: fragment.frame.midX, y: fragment.frame.midY)
            }
        }
    }

    private func fragments(
        at date: Date,
        proxy: GeometryProxy
    ) -> [WorkSetupSelectionHDRFragment] {
        events.values.compactMap { event in
            guard event.isActive(at: date), let anchor = bounds[event.roomID] else { return nil }
            let heat = RoomSelectionHDRFlashEvent.envelope.heat(
                startedAt: event.startedAt,
                now: date
            )
            return WorkSetupSelectionHDRFragment(
                roomID: event.roomID,
                frame: proxy[anchor],
                palette: event.palette,
                heat: heat,
                intensity: reduceMotion
                    ? 1.15
                    : RoomSelectionHDRFlashEvent.envelope.brightnessMultiplier,
                seed: Double(abs(event.roomID.hashValue % 10_000)) / 10_000
            )
        }
    }
}

struct WorkSetupSelectionHDRFragment {
    let roomID: RoomID
    let frame: CGRect
    let palette: HousekeeperPalette
    let heat: CGFloat
    let intensity: CGFloat
    let seed: Double
}

private struct WorkSetupSelectionHDRCanvas: UIViewRepresentable {
    let fragments: [WorkSetupSelectionHDRFragment]

    func makeUIView(context: Context) -> WorkSetupSelectionHDRCanvasView {
        WorkSetupSelectionHDRCanvasView()
    }

    func updateUIView(_ view: WorkSetupSelectionHDRCanvasView, context: Context) {
        view.fragments = fragments
    }
}

private final class WorkSetupSelectionHDRCanvasView: UIView {
    var fragments: [WorkSetupSelectionHDRFragment] = [] {
        didSet {
            configureDynamicRange()
            setNeedsDisplay()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        isOpaque = false
        isUserInteractionEnabled = false
        backgroundColor = .clear
        contentMode = .redraw
        layer.contentsScale = UIScreen.main.scale
        layer.contentsFormat = .RGBA16Float
        layer.drawsAsynchronously = true
        configureDynamicRange()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext(), !bounds.isEmpty else { return }
        let targetHeadroom = maximumTargetHeadroom
        RoomHDRRuntime.configure(context: context, targetHeadroom: targetHeadroom)
        context.clear(rect)

        for fragment in fragments where fragment.heat > 0 {
            draw(fragment, in: context)
        }
    }

    private func draw(_ fragment: WorkSetupSelectionHDRFragment, in context: CGContext) {
        let targetHeadroom = RoomHDRRuntime.targetHeadroom(intensity: fragment.intensity)
        let components = fragment.palette.rgbComponents
        let path = UIBezierPath(
            roundedRect: fragment.frame.insetBy(dx: 0.5, dy: 0.5),
            cornerRadius: 12
        )

        context.saveGState()
        path.addClip()
        context.setAlpha(fragment.heat)
        context.setFillColor(
            RoomHDRRuntime.extendedColor(
                components: components,
                targetHeadroom: targetHeadroom,
                alpha: 1
            )
        )
        context.fill(fragment.frame)
        RoomHDRRuntime.drawSameColorLift(
            in: fragment.frame,
            context: context,
            components: components,
            targetHeadroom: targetHeadroom,
            seed: fragment.seed
        )
        context.restoreGState()
    }

    private var maximumTargetHeadroom: CGFloat {
        fragments.map { RoomHDRRuntime.targetHeadroom(intensity: $0.intensity) }.max() ?? 1
    }

    private func configureDynamicRange() {
        RoomHDRRuntime.configure(layer: layer, targetHeadroom: maximumTargetHeadroom)
    }
}
