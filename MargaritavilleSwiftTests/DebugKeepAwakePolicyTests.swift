import Foundation
import Testing
@testable import MargaritavilleSwift

@Suite
struct DebugKeepAwakePolicyTests {
#if DEBUG
    @Test
    func policyRequiresExactOptInEnvironmentValue() {
        #expect(
            DebugKeepAwakePolicy(
                environment: ["MARGARITAVILLE_KEEP_SCREEN_AWAKE": "1"]
            ).isRequested
        )
        #expect(
            !DebugKeepAwakePolicy(
                environment: ["MARGARITAVILLE_KEEP_SCREEN_AWAKE": "true"]
            ).isRequested
        )
        #expect(!DebugKeepAwakePolicy(environment: [:]).isRequested)
    }

    @Test
    func policyOnlyDisablesIdleTimerWhileRequestedAndActive() {
        let requested = DebugKeepAwakePolicy(
            environment: ["MARGARITAVILLE_KEEP_SCREEN_AWAKE": "1"]
        )
        let absent = DebugKeepAwakePolicy(environment: [:])

        #expect(requested.shouldDisableIdleTimer(isAppActive: true))
        #expect(!requested.shouldDisableIdleTimer(isAppActive: false))
        #expect(!absent.shouldDisableIdleTimer(isAppActive: true))
        #expect(!absent.shouldDisableIdleTimer(isAppActive: false))
    }

    @Test
    func stateIsIdempotentAndResetsOnInactive() {
        var state = DebugKeepAwakeState(
            policy: DebugKeepAwakePolicy(
                environment: ["MARGARITAVILLE_KEEP_SCREEN_AWAKE": "1"]
            )
        )

        #expect(state.transition(isAppActive: true) == true)
        #expect(state.transition(isAppActive: true) == nil)
        #expect(state.transition(isAppActive: false) == false)
        #expect(state.transition(isAppActive: false) == nil)
        #expect(state.reset() == nil)
    }

    @Test
    func stateExplicitlyAppliesFalseWithoutOptIn() {
        var state = DebugKeepAwakeState(
            policy: DebugKeepAwakePolicy(environment: [:])
        )

        #expect(state.transition(isAppActive: true) == false)
        #expect(state.transition(isAppActive: true) == nil)
    }
#endif

}
