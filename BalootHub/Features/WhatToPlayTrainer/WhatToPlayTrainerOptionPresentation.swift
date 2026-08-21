import SwiftUI
import BalootEngine

extension WhatToPlayTrainerView {
    func optionOutcomeText(_ outcome: WhatToPlayOptionOutcome) -> String {
        switch outcome {
        case .leadsTrick:
            "يفتتح الأكلة".localized
        case .developsTrick:
            "يبقي الأكلة مفتوحة".localized
        case .winsTrick:
            "يكسب الأكلة".localized
        case .losesTrick:
            "يخسر الأكلة".localized
        }
    }

    func optionOutcomeIcon(_ outcome: WhatToPlayOptionOutcome) -> String {
        switch outcome {
        case .leadsTrick:
            "arrowshape.turn.up.forward.fill"
        case .developsTrick:
            "ellipsis.circle.fill"
        case .winsTrick:
            "checkmark.circle.fill"
        case .losesTrick:
            "xmark.circle.fill"
        }
    }

    func optionOutcomeTint(_ outcome: WhatToPlayOptionOutcome) -> Color {
        switch outcome {
        case .winsTrick:
            AppColor.success
        case .losesTrick:
            AppColor.danger
        case .leadsTrick, .developsTrick:
            AppColor.accent
        }
    }

    func optionTacticalTint(_ tag: WhatToPlayOptionTacticalTag) -> Color {
        switch tag {
        case .expertPick, .winsNow:
            AppColor.success
        case .closeAlternative, .holdsPosition:
            AppColor.accent
        case .opensRisk:
            AppColor.warning
        case .costly:
            AppColor.danger
        }
    }
}
