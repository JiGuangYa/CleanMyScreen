import Foundation
import CleanMyScreenKit

@main
struct CleanMyScreenVerification {
    static func main() async {
        await MainActor.run {
            verifyStartCleaning()
            verifyStopCleaning()
            verifyRepeatedStart()
            verifyOverlayExitCallback()
            verifySupportedLocalizations()
            verifyLocalizationKeysMatchEnglishBase()
            verifyLocalizationResolution()
        }

        print("CleanMyScreenVerification passed")
    }

    @MainActor
    private static func verifyStartCleaning() {
        let overlayFactory = MockOverlayFactory(controllerCount: 2)
        let applicationController = MockApplicationController()
        let mainWindowController = MockMainWindowController()
        let controller = CleaningSessionController(
            overlayFactory: overlayFactory,
            applicationController: applicationController,
            mainWindowController: mainWindowController
        )

        controller.startCleaning()

        require(controller.isCleaning, "Expected cleaning session to start")
        require(mainWindowController.hideCallCount == 1, "Expected main window to hide once")
        require(applicationController.activationCount == 1, "Expected app activation during start")
        require(overlayFactory.controllers.map(\.showCallCount) == [1, 1], "Expected each overlay to show once")
    }

    @MainActor
    private static func verifyStopCleaning() {
        let overlayFactory = MockOverlayFactory(controllerCount: 2)
        let applicationController = MockApplicationController()
        let mainWindowController = MockMainWindowController()
        let controller = CleaningSessionController(
            overlayFactory: overlayFactory,
            applicationController: applicationController,
            mainWindowController: mainWindowController
        )

        controller.startCleaning()
        controller.stopCleaning(trigger: .menuCommand)

        require(controller.isCleaning == false, "Expected cleaning session to stop")
        require(controller.lastExitTrigger == .menuCommand, "Expected menu trigger to be recorded")
        require(mainWindowController.showAndFocusCallCount == 1, "Expected main window to restore once")
        require(applicationController.activationCount == 2, "Expected app activation during stop")
        require(overlayFactory.controllers.map(\.closeCallCount) == [1, 1], "Expected each overlay to close once")
    }

    @MainActor
    private static func verifyRepeatedStart() {
        let overlayFactory = MockOverlayFactory(controllerCount: 1)
        let controller = CleaningSessionController(
            overlayFactory: overlayFactory,
            applicationController: MockApplicationController(),
            mainWindowController: MockMainWindowController()
        )

        controller.startCleaning()
        controller.startCleaning()

        require(overlayFactory.makeControllersCallCount == 1, "Expected repeated starts to be ignored")
        require(overlayFactory.controllers.map(\.showCallCount) == [1], "Expected overlay to show once")
    }

    @MainActor
    private static func verifyOverlayExitCallback() {
        let overlayFactory = MockOverlayFactory(controllerCount: 1)
        let applicationController = MockApplicationController()
        let mainWindowController = MockMainWindowController()
        let controller = CleaningSessionController(
            overlayFactory: overlayFactory,
            applicationController: applicationController,
            mainWindowController: mainWindowController
        )

        controller.startCleaning()
        overlayFactory.lastOnExit?(.escapeKey)

        require(controller.isCleaning == false, "Expected overlay callback to stop cleaning")
        require(controller.lastExitTrigger == .escapeKey, "Expected escape trigger to be recorded")
        require(mainWindowController.showAndFocusCallCount == 1, "Expected main window to restore after overlay exit")
        require(overlayFactory.controllers.first?.closeCallCount == 1, "Expected overlay to close after overlay exit")
    }

    @MainActor
    private static func verifySupportedLocalizations() {
        let supportedLocalizations = loadSupportedLocalizations()
        require(supportedLocalizations.count == 10, "Expected 10 supported localizations")

        let localizationDirectory = repositoryRootURL()
            .appendingPathComponent("Sources")
            .appendingPathComponent("CleanMyScreenKit")
            .appendingPathComponent("Resources")

        for localization in supportedLocalizations {
            let stringsURL = localizationDirectory
                .appendingPathComponent("\(localization).lproj")
                .appendingPathComponent("Localizable.strings")
            require(FileManager.default.fileExists(atPath: stringsURL.path), "Missing strings file for \(localization)")
        }
    }

    @MainActor
    private static func verifyLocalizationKeysMatchEnglishBase() {
        let supportedLocalizations = loadSupportedLocalizations()
        let baseDictionary = loadStringsDictionary(localization: "en")
        let expectedKeys = Set(LocalizationKey.allCases.map(\.rawValue))

        require(Set(baseDictionary.keys) == expectedKeys, "English localization keys do not match LocalizationKey definitions")

        for localization in supportedLocalizations where localization != "en" {
            let dictionary = loadStringsDictionary(localization: localization)
            require(Set(dictionary.keys) == expectedKeys, "Localization keys for \(localization) do not match English")
        }
    }

    @MainActor
    private static func verifyLocalizationResolution() {
        let availableLocalizations = L10n.bundle.localizations
        let normalizedSupportedLocalizations = Set(loadSupportedLocalizations().map { $0.lowercased() })

        require(
            Set(availableLocalizations) == normalizedSupportedLocalizations,
            "Expected resource bundle localizations to match supported_localizations.txt"
        )

        require(
            Bundle.preferredLocalizations(from: availableLocalizations, forPreferences: ["zh-Hans-CN"]).first == "zh-hans",
            "Expected Simplified Chinese preference to resolve to zh-Hans"
        )
        require(
            Bundle.preferredLocalizations(from: availableLocalizations, forPreferences: ["zh-Hant-HK"]).first == "zh-hant",
            "Expected Traditional Chinese preference to resolve to zh-Hant"
        )
        require(
            Bundle.preferredLocalizations(from: availableLocalizations, forPreferences: ["ja-JP"]).first == "ja",
            "Expected Japanese preference to resolve to ja"
        )
        require(
            Bundle.preferredLocalizations(from: availableLocalizations, forPreferences: ["ko-KR"]).first == "ko",
            "Expected Korean preference to resolve to ko"
        )
        require(
            Bundle.preferredLocalizations(from: availableLocalizations, forPreferences: ["fr-FR"]).first == "fr",
            "Expected French preference to resolve to fr"
        )
        require(
            Bundle.preferredLocalizations(from: availableLocalizations, forPreferences: ["de-DE"]).first == "de",
            "Expected German preference to resolve to de"
        )
        require(
            Bundle.preferredLocalizations(from: availableLocalizations, forPreferences: ["es-ES"]).first == "es",
            "Expected Spanish preference to resolve to es"
        )
        require(
            Bundle.preferredLocalizations(from: availableLocalizations, forPreferences: ["it-IT"]).first == "it",
            "Expected Italian preference to resolve to it"
        )
        require(
            Bundle.preferredLocalizations(from: availableLocalizations, forPreferences: ["pt-BR"]).first == "pt-br",
            "Expected Brazilian Portuguese preference to resolve to pt-BR"
        )
        require(
            Bundle.preferredLocalizations(from: availableLocalizations, forPreferences: ["nl-NL", "fr-FR"]).first == "fr",
            "Expected unsupported Dutch with French fallback to resolve to fr"
        )
        require(
            Bundle.preferredLocalizations(from: availableLocalizations, forPreferences: ["nl-NL", "sv-SE"]).first == "en",
            "Expected unsupported preferences to fall back to en"
        )
    }

    private static func require(_ condition: @autoclosure () -> Bool, _ message: String) {
        guard condition() else {
            fputs("Verification failed: \(message)\n", stderr)
            exit(EXIT_FAILURE)
        }
    }

    private static func repositoryRootURL() -> URL {
        URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
    }

    private static func loadSupportedLocalizations() -> [String] {
        let supportedLocalizationsURL = repositoryRootURL()
            .appendingPathComponent("Localization")
            .appendingPathComponent("supported_localizations.txt")

        guard let contents = try? String(contentsOf: supportedLocalizationsURL, encoding: .utf8) else {
            fputs("Verification failed: Missing supported_localizations.txt\n", stderr)
            exit(EXIT_FAILURE)
        }

        return contents
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private static func loadStringsDictionary(localization: String) -> [String: String] {
        let stringsURL = repositoryRootURL()
            .appendingPathComponent("Sources")
            .appendingPathComponent("CleanMyScreenKit")
            .appendingPathComponent("Resources")
            .appendingPathComponent("\(localization).lproj")
            .appendingPathComponent("Localizable.strings")

        guard let dictionary = NSDictionary(contentsOf: stringsURL) as? [String: String] else {
            fputs("Verification failed: Unable to parse \(stringsURL.path)\n", stderr)
            exit(EXIT_FAILURE)
        }

        return dictionary
    }
}

@MainActor
private final class MockOverlayFactory: OverlayWindowFactory {
    private let controllerCount: Int

    var makeControllersCallCount = 0
    var controllers: [MockOverlayController] = []
    var lastOnExit: (@MainActor (ExitTrigger) -> Void)?

    init(controllerCount: Int) {
        self.controllerCount = controllerCount
    }

    func makeControllers(onExit: @escaping @MainActor (ExitTrigger) -> Void) -> [OverlayWindowPresenting] {
        makeControllersCallCount += 1
        lastOnExit = onExit
        controllers = (0..<controllerCount).map { _ in MockOverlayController() }
        return controllers
    }
}

@MainActor
private final class MockOverlayController: OverlayWindowPresenting {
    var showCallCount = 0
    var closeCallCount = 0

    func show() {
        showCallCount += 1
    }

    func close() {
        closeCallCount += 1
    }
}

@MainActor
private final class MockApplicationController: ApplicationControlling {
    var activationCount = 0

    func activate(ignoringOtherApps: Bool) {
        activationCount += 1
    }
}

@MainActor
private final class MockMainWindowController: MainWindowControlling {
    var hideCallCount = 0
    var showAndFocusCallCount = 0

    func hide() {
        hideCallCount += 1
    }

    func showAndFocus() {
        showAndFocusCallCount += 1
    }
}
