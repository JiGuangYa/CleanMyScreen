import Foundation

package enum LocalizationKey: String, CaseIterable {
    case appTitle = "app.title"
    case mainSubtitle = "main.subtitle"
    case actionStartCleaning = "action.startCleaning"
    case accessibilityStartCleaning = "accessibility.startCleaning"
    case mainFooterHint = "main.footerHint"
    case accessibilityFooterHint = "accessibility.footerHint"
    case hintPressEsc = "hint.pressEsc"
    case accessibilityPressEsc = "accessibility.pressEsc"
    case actionDone = "action.done"
    case accessibilityExitCleaning = "accessibility.exitCleaning"
    case menuCleaning = "menu.cleaning"
    case menuStartCleaning = "menu.startCleaning"
    case menuExitCleaning = "menu.exitCleaning"
}

package enum L10n {
    package static let bundle = Bundle.module

    package static func string(_ key: LocalizationKey) -> String {
        bundle.localizedString(forKey: key.rawValue, value: nil, table: nil)
    }
}
