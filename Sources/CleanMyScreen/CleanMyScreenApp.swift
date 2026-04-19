import AppKit
import CleanMyScreenKit
import SwiftUI

@main
struct CleanMyScreenApp: App {
    @NSApplicationDelegateAdaptor(CleanMyScreenAppDelegate.self) private var appDelegate
    @StateObject private var sessionController = CleaningSessionController()

    var body: some Scene {
        WindowGroup(L10n.string(.appTitle)) {
            MainView(sessionController: sessionController)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 480, height: 320)
        .commands {
            AppCommands(sessionController: sessionController)
        }
    }
}

final class CleanMyScreenAppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}
