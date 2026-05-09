import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: ConversionViewModel

    var body: some View {
        VStack(spacing: 0) {
            DropZoneView(viewModel: viewModel)
                .padding()

            Divider()

            SettingsPanel(config: $viewModel.config)
                .padding(.horizontal)
                .padding(.vertical, 12)

            Divider()

            Spacer()

            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.horizontal)
            }

            HStack {
                if viewModel.isConverting {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Converting...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                if viewModel.outputURL != nil {
                    Button("Open in Books") {
                        viewModel.openInBooks()
                    }
                    .keyboardShortcut(.defaultAction)
                }
            }
            .padding()
        }
        .background(Color(.windowBackgroundColor))
    }
}
