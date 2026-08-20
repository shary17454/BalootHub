import XCTest
import BalootEngine
@testable import BalootHub

final class AppRouteTests: XCTestCase {
    func testWhatToPlayTrainerRouteCarriesGameMode() {
        let sunRoute = AppRoute.whatToPlayTrainer(
            seed: 123,
            difficulty: .medium,
            focusKind: .openingLead,
            gameMode: .sun
        )
        let hokumRoute = AppRoute.whatToPlayTrainer(
            seed: 123,
            difficulty: .medium,
            focusKind: .openingLead,
            gameMode: .hokum
        )

        XCTAssertNotEqual(sunRoute, hokumRoute)
        XCTAssertEqual(
            sunRoute,
            .whatToPlayTrainer(
                seed: 123,
                difficulty: .medium,
                focusKind: .openingLead,
                gameMode: .sun
            )
        )
    }
}
