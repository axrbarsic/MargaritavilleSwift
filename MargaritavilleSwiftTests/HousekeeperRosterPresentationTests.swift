import Foundation
import Testing
@testable import MargaritavilleSwift

@Test
func housekeeperRosterPresentationSortsAndFiltersPrefixesDeterministically() {
    let roster = [
        Housekeeper(id: "clara", displayName: "Clara", palette: .coral),
        Housekeeper(id: "ana-b", displayName: "Ana", palette: .aqua),
        Housekeeper(id: "bea", displayName: "  Béa  ", palette: .amber),
        Housekeeper(id: "ana-a", displayName: "Ana", palette: .mint),
        Housekeeper(id: "nadya", displayName: "Надя", palette: .sky),
        Housekeeper(id: "nadezhda", displayName: " Надежда ", palette: .violet)
    ]

    let english = Locale(identifier: "en_US")
    let ordered = HousekeeperRosterPresentation.sorted(roster, locale: english)
    #expect(Array(ordered.prefix(4).map(\.id)) == ["ana-a", "ana-b", "bea", "clara"])

    #expect(HousekeeperRosterPresentation.suggestions(for: " a ", in: roster, locale: english).map(\.id) == ["ana-a", "ana-b"])
    #expect(HousekeeperRosterPresentation.suggestions(for: "BE", in: roster, locale: english).map(\.id) == ["bea"])
    #expect(HousekeeperRosterPresentation.suggestions(for: "béa", in: roster, locale: english).first?.displayName == "  Béa  ")
    #expect(HousekeeperRosterPresentation.suggestions(for: " ", in: roster, locale: english).isEmpty)

    let russianMatches = HousekeeperRosterPresentation.suggestions(
        for: " нАд ",
        in: roster,
        locale: Locale(identifier: "ru_RU")
    )
    #expect(russianMatches.map(\.id) == ["nadezhda", "nadya"])
}
