import Testing
@testable import MargaritavilleSwift

@Test
func roomCommandCenterAtomicCommandCollapsesOnlyAfterSuccessfulCommit() {
    var state = RoomCommandCenterStateMachine()

    let beganStatus = state.begin(.status(.ready))
    #expect(beganStatus)
    let rejectedConcurrentVIP = state.begin(.vip)
    #expect(!rejectedConcurrentVIP)
    #expect(state.finishAtomic(succeeded: true) == .collapse)
    #expect(state.phase == .idle)

    let beganVIP = state.begin(.vip)
    #expect(beganVIP)
    #expect(state.finishAtomic(succeeded: false) == .stayOpen)
    #expect(state.phase == .idle)
}

@Test
func roomCommandCenterChildFlowStaysOpenOnCancelAndCollapsesOnMutation() {
    var state = RoomCommandCenterStateMachine()

    let beganSchedule = state.begin(.schedule)
    #expect(beganSchedule)
    state.childDismissedWithoutMutation()
    #expect(state.phase == .idle)

    let beganMedia = state.begin(.details(.media))
    #expect(beganMedia)
    #expect(state.childDidMutateRoom() == .collapse)
    #expect(state.phase == .idle)
}
