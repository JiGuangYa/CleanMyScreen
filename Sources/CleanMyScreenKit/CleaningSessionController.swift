import AppKit
import Combine
import Foundation

public enum ExitTrigger: Equatable {
    case escapeKey
    case button
    case menuCommand
}

@MainActor
public protocol OverlayWindowPresenting: AnyObject {
    func show()
    func close()
}

@MainActor
public protocol OverlayWindowFactory {
    func makeControllers(onExit: @escaping @MainActor (ExitTrigger) -> Void) -> [OverlayWindowPresenting]
}

@MainActor
public protocol MainWindowControlling: AnyObject {
    func hide()
    func showAndFocus()
}

@MainActor
public protocol ApplicationControlling: AnyObject {
    func activate(ignoringOtherApps: Bool)
}

extension NSApplication: ApplicationControlling { }

@MainActor
public final class AppMainWindowController: MainWindowControlling {
    private weak var window: NSWindow?

    public init(window: NSWindow) {
        self.window = window
    }

    public func hide() {
        window?.orderOut(nil)
    }

    public func showAndFocus() {
        guard let window else {
            return
        }

        if window.isMiniaturized {
            window.deminiaturize(nil)
        }

        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
    }
}

@MainActor
public final class ScreenOverlayWindowFactory: OverlayWindowFactory {
    public init() { }

    public func makeControllers(onExit: @escaping @MainActor (ExitTrigger) -> Void) -> [OverlayWindowPresenting] {
        NSScreen.screens.map { screen in
            ScreenOverlayWindowController(screen: screen, onExit: onExit)
        }
    }
}

@MainActor
public final class CleaningSessionController: ObservableObject {
    @Published public private(set) var isCleaning = false

    private let overlayFactory: OverlayWindowFactory
    private let applicationController: ApplicationControlling
    private var overlayControllers: [OverlayWindowPresenting] = []
    private var mainWindowController: MainWindowControlling?

    public private(set) var lastExitTrigger: ExitTrigger?

    public init(
        overlayFactory: OverlayWindowFactory = ScreenOverlayWindowFactory(),
        applicationController: ApplicationControlling = NSApplication.shared,
        mainWindowController: MainWindowControlling? = nil
    ) {
        self.overlayFactory = overlayFactory
        self.applicationController = applicationController
        self.mainWindowController = mainWindowController
    }

    public func registerMainWindow(_ window: NSWindow) {
        mainWindowController = AppMainWindowController(window: window)
    }

    public func startCleaning() {
        guard !isCleaning else {
            return
        }

        let controllers = overlayFactory.makeControllers { [weak self] trigger in
            self?.stopCleaning(trigger: trigger)
        }

        guard !controllers.isEmpty else {
            return
        }

        overlayControllers = controllers
        isCleaning = true
        lastExitTrigger = nil

        mainWindowController?.hide()
        overlayControllers.forEach { $0.show() }
        applicationController.activate(ignoringOtherApps: true)
    }

    public func stopCleaning(trigger: ExitTrigger) {
        guard isCleaning else {
            return
        }

        overlayControllers.forEach { $0.close() }
        overlayControllers.removeAll()

        isCleaning = false
        lastExitTrigger = trigger

        mainWindowController?.showAndFocus()
        applicationController.activate(ignoringOtherApps: true)
    }
}
