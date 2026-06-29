import HospitalityFoundation
import MargaritavilleHostedRoot
import MargaritavilleLabContainer
import SwiftUI

@main
struct MargaritavilleStandaloneApp: App {
    private static let bundleIdentifier = "com.alex.margaritaville.swift"

    var body: some Scene {
        WindowGroup {
            MargaritavilleEmbeddedRootView(
                bootstrap: MargaritavilleHostedRootBootstrap(
                    runtimeContract: Self.runtimeContract,
                    configureApplicationSupportOverride: AppStorageDirectory.configureApplicationSupportOverride
                )
            )
            .preferredColorScheme(.dark)
        }
    }

    private static var runtimeContract: HospitalityContainerRuntimeContract {
        HospitalityContainerRuntimeContract.hosted(
            descriptor: MargaritavilleLabContainer.descriptor,
            payloadKind: .thinStandaloneAppTarget,
            hostIdentity: HospitalityAppIdentity(
                displayName: "Margaritaville",
                bundleIdentifier: bundleIdentifier,
                storageNamespace: bundleIdentifier
            ),
            runtimeBundleIdentifier: bundleIdentifier,
            applicationSupportRoot: "MargaritavilleSwift",
            interactionPolicy: .standalone
        )
    }
}
