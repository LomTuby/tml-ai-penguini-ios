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

                VStack(spacing: 20) {
                    Button(action: {
                        viewModel.startManualTalk()
                    }) {
                        Text(viewModel.isListening && viewModel.isManualTalkMode ? "Listening..." : "Talk to Penguini")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(viewModel.isListening ? Color.blue.opacity(0.2) : Color.blue)
                            .foregroundColor(viewModel.isListening ? .blue : .white)
                            .cornerRadius(16)
                    }
                    .disabled(viewModel.isThinking || viewModel.isWakingUp)

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
                .padding(.bottom, 40)
            }
        }
    }
}
