import Foundation
import Testing
@testable import BrooklynWebBackgroundKit

@Test func navigationPolicyAllowsOnlyFilesInsideDistribution() {
    let root = URL(fileURLWithPath: "/tmp/BrooklynWeb/WebDist", isDirectory: true)

    #expect(BrooklynWebNavigationPolicy.allows(
        root.appendingPathComponent("index.html"),
        inside: root
    ))
    #expect(BrooklynWebNavigationPolicy.allows(
        root.appendingPathComponent("assets/app.js"),
        inside: root
    ))
    #expect(!BrooklynWebNavigationPolicy.allows(
        root.deletingLastPathComponent().appendingPathComponent("secret.txt"),
        inside: root
    ))
    #expect(!BrooklynWebNavigationPolicy.allows(
        URL(string: "https://brooklyn.sh"),
        inside: root
    ))
    #expect(!BrooklynWebNavigationPolicy.allows(
        URL(string: "data:text/html,blocked"),
        inside: root
    ))
}
