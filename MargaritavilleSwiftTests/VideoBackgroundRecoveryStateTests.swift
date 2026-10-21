import Testing
@testable import MargaritavilleSwift

@Test
func videoBackgroundRecoveryResumesAfterInterruptionEndsWhileActive() {
    var state = VideoBackgroundRecoveryState()

    #expect(state.transition(.sceneActive, health: .healthy) == .resume)
    #expect(state.transition(.interruptionBegan, health: .healthy) == .pause)
    #expect(state.transition(.interruptionEnded, health: .healthy) == .resume)
    #expect(state.transition(.renderedFrame, health: .healthy) == .none)
}

@Test
func videoBackgroundRecoveryWaitsWhenInterruptionEndsBeforeSceneBecomesActive() {
    var state = VideoBackgroundRecoveryState()

    #expect(state.transition(.sceneActive, health: .healthy) == .resume)
    #expect(state.transition(.sceneInactive, health: .healthy) == .pause)
    #expect(state.transition(.interruptionBegan, health: .healthy) == .pause)
    #expect(state.transition(.interruptionEnded, health: .healthy) == .none)
    #expect(state.transition(.sceneActive, health: .healthy) == .resume)
}

@Test
func videoBackgroundRecoveryRebuildsOnceForDuplicateMediaReset() {
    var state = VideoBackgroundRecoveryState()

    #expect(state.transition(.sceneActive, health: .healthy) == .resume)
    #expect(
        state.transition(.mediaServicesWereReset, health: .renderPipelineLost)
            == .rebuild(generation: 1)
    )
    #expect(state.transition(.mediaServicesWereReset, health: .renderPipelineLost) == .none)
    #expect(state.transition(.renderedFrame, health: .healthy) == .none)
}

@Test
func videoBackgroundRecoveryIgnoresDuplicateInterruptionNotifications() {
    var state = VideoBackgroundRecoveryState()

    #expect(state.transition(.sceneActive, health: .healthy) == .resume)
    #expect(state.transition(.interruptionBegan, health: .healthy) == .pause)
    #expect(state.transition(.interruptionBegan, health: .healthy) == .none)
    #expect(state.transition(.interruptionEnded, health: .healthy) == .resume)
    #expect(state.transition(.interruptionEnded, health: .healthy) == .none)
}

@Test
func videoBackgroundRecoveryWaitsForActiveCaptureOwnerBeforeRebuild() {
    var state = VideoBackgroundRecoveryState()

    #expect(state.transition(.sceneActive, health: .healthy) == .resume)
    #expect(state.transition(.captureOwnershipChanged(isActive: true), health: .healthy) == .none)
    #expect(state.transition(.mediaServicesWereReset, health: .renderPipelineLost) == .none)
    #expect(
        state.transition(.captureOwnershipChanged(isActive: false), health: .renderPipelineLost)
            == .rebuild(generation: 1)
    )
}
