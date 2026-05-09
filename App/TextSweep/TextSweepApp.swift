import SwiftUI

@main
struct TextSweepApp: App {
    @StateObject private var viewModel = ConversionViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
                .frame(minWidth: 480, minHeight: 400)
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 540, height: 420)
    }
}
