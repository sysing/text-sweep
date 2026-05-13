import SwiftUI
import UniformTypeIdentifiers

struct DropZoneView: View {
    @ObservedObject var viewModel: ConversionViewModel

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    viewModel.isDragging ? Color.accentColor : Color.secondary.opacity(0.4),
                    style: StrokeStyle(lineWidth: 2, dash: [6, 4])
                )
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(viewModel.isDragging
                            ? Color.accentColor.opacity(0.08)
                            : Color(.controlBackgroundColor))
                )
                .animation(.easeInOut(duration: 0.15), value: viewModel.isDragging)

            VStack(spacing: 12) {
                if let filename = viewModel.selectedFilename {
                    Image(systemName: "doc.richtext")
                        .font(.system(size: 36))
                        .foregroundColor(.accentColor)
                    Text(filename)
                        .font(.headline)
                        .lineLimit(1)
                    Button("Convert") {
                        viewModel.convert()
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                    .disabled(viewModel.isConverting)
                } else {
                    Image(systemName: "arrow.down.doc")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("Drop EPUB file here")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    Text("or click to browse")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Button("Select File...") {
                        viewModel.selectFile()
                    }
                    .keyboardShortcut("o")
                    .padding(.top, 4)
                }
            }
            .padding(24)
        }
        .frame(height: 160)
        .onDrop(of: [.fileURL], isTargeted: $viewModel.isDragging) { providers in
            viewModel.handleDrop(providers: providers)
            return true
        }
        .onTapGesture {
            viewModel.selectFile()
        }
    }
}
