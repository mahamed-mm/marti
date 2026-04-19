import Foundation
import Testing
@testable import Marti

@MainActor
@Suite struct FavoriteHeartButtonTests {
    @Test func smallReports32VisibleAnd44Hit() {
        #expect(FavoriteHeartButton.Size.small.visibleDiameter == 32)
        #expect(FavoriteHeartButton.Size.small.hitDiameter == 44)
    }

    @Test func largeReports44VisibleAnd44Hit() {
        #expect(FavoriteHeartButton.Size.large.visibleDiameter == 44)
        #expect(FavoriteHeartButton.Size.large.hitDiameter == 44)
    }
}
