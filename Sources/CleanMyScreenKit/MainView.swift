import SwiftUI

public struct MainView: View {
    @ObservedObject private var sessionController: CleaningSessionController

    public init(sessionController: CleaningSessionController) {
        _sessionController = ObservedObject(wrappedValue: sessionController)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 10) {
                Text(verbatim: L10n.string(.appTitle))
                    .font(.largeTitle.weight(.semibold))
                    .foregroundStyle(.primary)
                    .accessibilityAddTraits(.isHeader)

                Text(verbatim: L10n.string(.mainSubtitle))
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button {
                sessionController.startCleaning()
            } label: {
                Text(verbatim: L10n.string(.actionStartCleaning))
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(sessionController.isCleaning)
            .accessibilityLabel(Text(verbatim: L10n.string(.accessibilityStartCleaning)))

            Text(verbatim: L10n.string(.mainFooterHint))
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityLabel(Text(verbatim: L10n.string(.accessibilityFooterHint)))

            Spacer(minLength: 0)
        }
        .padding(32)
        .frame(minWidth: 480, idealWidth: 480, maxWidth: 560, minHeight: 320, idealHeight: 320, maxHeight: 420, alignment: .topLeading)
        .background(
            WindowAccessor { window in
                sessionController.registerMainWindow(window)
            }
        )
    }
}
