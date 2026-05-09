import SwiftUI

struct SettingsPanel: View {
    @Binding var config: BionicConfigViewModel

    var body: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Fixation strength:")
                        .font(.caption)
                    Text("\(Int(config.fixationRatio * 100))%")
                        .font(.caption.monospacedDigit())
                        .foregroundColor(.secondary)
                }
                Slider(value: $config.fixationRatio, in: 0.30...0.50, step: 0.01)
                    .frame(width: 160)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Min word length:")
                    .font(.caption)
                Picker("", selection: $config.minimumWordLength) {
                    ForEach(1...5, id: \.self) { n in
                        Text("\(n)").tag(n)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 120)
            }

            Toggle("Skip common words", isOn: $config.skipStopWords)
                .font(.caption)
        }
    }
}
