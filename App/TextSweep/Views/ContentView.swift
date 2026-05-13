import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: ConversionViewModel

    var body: some View {
        VStack(spacing: 0) {
            DropZoneView(viewModel: viewModel)
                .padding()

            if !viewModel.recentFiles.isEmpty {
                recentFilesSection
                    .padding(.horizontal)
                    .padding(.bottom, 8)
            }

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
                    .keyboardShortcut("b", modifiers: .command)
                }
            }
            .padding()
        }
        .background(Color(.windowBackgroundColor))
    }

    private var recentFilesSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Recent")
                .font(.caption)
                .foregroundColor(.secondary)

            ForEach(viewModel.recentFiles, id: \.path) { url in
                Button(url.lastPathComponent) {
                    viewModel.openRecentFile(url)
                }
                .buttonStyle(.link)
                .font(.caption)
                .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
