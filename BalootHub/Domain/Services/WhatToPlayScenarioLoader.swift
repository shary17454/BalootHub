import Foundation
import BalootEngine

enum WhatToPlayScenarioLoader {
    static func generate(seed: UInt64, difficulty: WhatToPlayDifficulty) async throws -> WhatToPlayScenario {
        try await Task.detached(priority: .userInitiated) {
            try WhatToPlayTrainer.generateScenario(seed: seed, difficulty: difficulty)
        }.value
    }
}
