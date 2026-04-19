import SwiftUI

public struct AppCommands: Commands {
    @ObservedObject private var sessionController: CleaningSessionController

    public init(sessionController: CleaningSessionController) {
        _sessionController = ObservedObject(wrappedValue: sessionController)
    }

    public var body: some Commands {
        CommandGroup(replacing: .newItem) { }

        CommandMenu(L10n.string(.menuCleaning)) {
            Button(L10n.string(.menuStartCleaning)) {
                sessionController.startCleaning()
            }
            .keyboardShortcut("k", modifiers: [.command, .shift])
            .disabled(sessionController.isCleaning)

            Button(L10n.string(.menuExitCleaning)) {
                sessionController.stopCleaning(trigger: .menuCommand)
            }
            .keyboardShortcut(.escape, modifiers: [])
            .disabled(!sessionController.isCleaning)
        }
    }
}
