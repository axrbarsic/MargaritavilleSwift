#if os(iOS)
import SwiftUI

public struct BrooklynWebBackgroundView: View {
    @Environment(\.scenePhase) private var scenePhase
    private let configuration: BrooklynWebConfiguration
    private let telemetryDurationMS: Int?

    public init(
        configuration: BrooklynWebConfiguration = .default,
        telemetryDurationMS: Int? = BrooklynWebTelemetryRequest.durationMS()
    ) {
        self.configuration = configuration
        self.telemetryDurationMS = telemetryDurationMS
    }

    public var body: some View {
        ZStack {
            Color.black
            BrooklynWebContainer(
                isActive: scenePhase == .active,
                configuration: configuration,
                telemetryDurationMS: telemetryDurationMS
            )
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
#endif
