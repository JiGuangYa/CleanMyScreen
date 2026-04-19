import AppKit
import SwiftUI

@MainActor
final class OverlayPresentationModel: ObservableObject {
    @Published var showsChrome = true
    @Published var showsHint = true

    private let reduceMotion: Bool
    private var chromeDismissWorkItem: DispatchWorkItem?
    private var hintDismissWorkItem: DispatchWorkItem?

    init(reduceMotion: Bool = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion) {
        self.reduceMotion = reduceMotion
    }

    func startPresentationCycle() {
        revealChrome(includeHint: true, hideAfter: 3.0)
        scheduleHintDismiss(after: 2.4)
    }

    func registerInteraction() {
        revealChrome(includeHint: false, hideAfter: 1.8)
    }

    private func revealChrome(includeHint: Bool, hideAfter delay: TimeInterval) {
        chromeDismissWorkItem?.cancel()

        animate {
            self.showsChrome = true
            if includeHint {
                self.showsHint = true
            }
        }

        let workItem = DispatchWorkItem { [weak self] in
            guard let self else {
                return
            }

            self.animate {
                self.showsChrome = false
            }
        }

        chromeDismissWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
    }

    private func scheduleHintDismiss(after delay: TimeInterval) {
        hintDismissWorkItem?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            guard let self else {
                return
            }

            self.animate {
                self.showsHint = false
            }
        }

        hintDismissWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
    }

    private func animate(_ changes: @escaping () -> Void) {
        if reduceMotion {
            changes()
        } else {
            withAnimation(.easeInOut(duration: 0.18), changes)
        }
    }
}

@MainActor
final class OverlayWindow: NSWindow {
    var onEscape: (() -> Void)?
    var onInteraction: (() -> Void)?

    override var canBecomeKey: Bool {
        true
    }

    override var canBecomeMain: Bool {
        false
    }

    override func sendEvent(_ event: NSEvent) {
        switch event.type {
        case .keyDown:
            if event.keyCode == 53 {
                onEscape?()
                return
            }
        case .mouseMoved, .leftMouseDown, .rightMouseDown, .otherMouseDown, .scrollWheel:
            onInteraction?()
        default:
            break
        }

        super.sendEvent(event)
    }

    override func cancelOperation(_ sender: Any?) {
        onEscape?()
    }
}

struct OverlayContentView: View {
    @ObservedObject var model: OverlayPresentationModel
    let onExit: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black
                .ignoresSafeArea()

            VStack(alignment: .trailing, spacing: 12) {
                if model.showsHint {
                    Text(verbatim: L10n.string(.hintPressEsc))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.trailing)
                        .accessibilityLabel(Text(verbatim: L10n.string(.accessibilityPressEsc)))
                }

                Button {
                    onExit()
                } label: {
                    Text(verbatim: L10n.string(.actionDone))
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .accessibilityLabel(Text(verbatim: L10n.string(.accessibilityExitCleaning)))
            }
            .padding(16)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(.white.opacity(0.08))
            )
            .padding(24)
            .opacity(model.showsChrome ? 1 : 0)
            .allowsHitTesting(model.showsChrome)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .contain)
    }
}

@MainActor
public final class ScreenOverlayWindowController: NSObject, OverlayWindowPresenting {
    private let screen: NSScreen
    private let onExit: @MainActor (ExitTrigger) -> Void
    private let presentationModel = OverlayPresentationModel()

    private var window: OverlayWindow?

    public init(screen: NSScreen, onExit: @escaping @MainActor (ExitTrigger) -> Void) {
        self.screen = screen
        self.onExit = onExit
    }

    public func show() {
        if window == nil {
            createWindow()
        }

        guard let window else {
            return
        }

        window.setFrame(screen.frame, display: true)
        window.orderFrontRegardless()
        window.makeKeyAndOrderFront(nil)

        presentationModel.startPresentationCycle()
    }

    public func close() {
        window?.orderOut(nil)
        window?.close()
        window = nil
    }

    private func createWindow() {
        let window = OverlayWindow(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false,
            screen: screen
        )

        window.backgroundColor = .black
        window.level = .screenSaver
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        window.isOpaque = true
        window.hasShadow = false
        window.hidesOnDeactivate = false
        window.ignoresMouseEvents = false
        window.acceptsMouseMovedEvents = true
        window.isMovable = false
        window.animationBehavior = .none
        window.isReleasedWhenClosed = false

        window.onEscape = { [weak self] in
            self?.requestExit(.escapeKey)
        }
        window.onInteraction = { [weak self] in
            self?.presentationModel.registerInteraction()
        }

        let hostingController = NSHostingController(
            rootView: OverlayContentView(model: presentationModel) { [weak self] in
                self?.requestExit(.button)
            }
        )

        window.contentViewController = hostingController
        self.window = window
    }

    private func requestExit(_ trigger: ExitTrigger) {
        onExit(trigger)
    }
}
