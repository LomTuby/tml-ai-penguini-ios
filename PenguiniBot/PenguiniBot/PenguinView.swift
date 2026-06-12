import SwiftUI

struct PenguinView: View {
    @ObservedObject var viewModel: PenguinViewModel

    var body: some View {
        ZStack {
            Color.blue.opacity(0.1).ignoresSafeArea()

            VStack {
                Text("Penguini")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.blue)
                    .padding(.top, 40)

                Spacer()

                PenguinFace(expression: viewModel.penguinExpression)
                    .frame(height: 300)

                Spacer()
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 16) {
                Button(action: {
                    viewModel.toggleManualTalk()
                }) {
                    ZStack {
                        Circle()
                            .fill(viewModel.isManualTalkMode || viewModel.isWakingUp ? Color.cyan.opacity(0.25) : Color.blue)
                            .frame(width: 72, height: 72)
                            .shadow(radius: 3)

                        Image(systemName: "fish.fill")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(viewModel.isManualTalkMode || viewModel.isWakingUp ? Color.cyan : .white)
                    }
                    .accessibilityLabel(viewModel.isManualTalkMode || viewModel.isWakingUp ? "Stop talking" : "Talk to Penguini")
                }
                .disabled(viewModel.isThinking)

                if viewModel.isListening {
                    Text(viewModel.isManualTalkMode ? "Listening..." : "Listening for 'Penguini'...")
                        .italic()
                        .foregroundColor(.gray)
                } else if viewModel.isThinking {
                    Text("Thinking...")
                        .foregroundColor(.blue)
                }

                if !viewModel.lastTranscribedText.isEmpty {
                    Text(viewModel.lastTranscribedText)
                        .font(.body)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(15)
                        .shadow(radius: 2)
                }

                if !viewModel.lastResponse.isEmpty {
                    ScrollView {
                        Text(viewModel.lastResponse)
                            .font(.body)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: 150)
                    .background(Color(.secondarySystemBackground).opacity(0.8))
                    .cornerRadius(15)
                    .padding()
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 20)
            .background(.ultraThinMaterial)
        }
    }
}
