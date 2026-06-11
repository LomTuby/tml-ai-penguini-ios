import Foundation
import MediaPipeTasksGenAI

class LLMManager: ObservableObject {
    private var llmInference: LlmInference?
    @Published var isModelLoaded = false
    @Published var responseText = ""

    init() {
        setupModel()
    }

    private func setupModel() {
        guard let modelPath = Bundle.main.path(forResource: "gemma-2b-it-cpu-int4", ofType: "bin") else {
            print("Model file not found in bundle.")
            return
        }

        let options = LlmInference.Options(modelPath: modelPath)
        options.maxTokens = 512
        options.temperature = 0.7
        options.randomSeed = Int.random(in: 0...1000)

        do {
            llmInference = try LlmInference(options: options)
            DispatchQueue.main.async {
                self.isModelLoaded = true
            }
        } catch {
            print("Failed to initialize LlmInference: \(error)")
        }
    }

    func generateResponse(prompt: String, completion: @escaping (String) -> Void) {
        guard let llmInference = llmInference else {
            completion("I'm sorry, I'm still waking up. (Model not loaded)")
            return
        }

        // Wrap prompt in Gemma format if needed, though MediaPipe handles some of it
        let formattedPrompt = "<start_of_turn>user\n\(prompt)<end_of_turn>\n<start_of_turn>model\n"

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let response = try llmInference.generateResponse(inputText: formattedPrompt)
                DispatchQueue.main.async {
                    self.responseText = response
                    completion(response)
                }
            } catch {
                DispatchQueue.main.async {
                    completion("Oops, I got a bit confused! \(error.localizedDescription)")
                }
            }
        }
    }

    // For streaming responses (better UX)
    func generateResponseStream(prompt: String, partialHandler: @escaping (String) -> Void, completion: @escaping (String) -> Void) {
        guard let llmInference = llmInference else { return }

        let formattedPrompt = "<start_of_turn>user\n\(prompt)<end_of_turn>\n<start_of_turn>model\n"
        var fullResponse = ""

        llmInference.generateResponseAsync(inputText: formattedPrompt) { partialResponse, error in
            if let error = error {
                print("Streaming error: \(error)")
                return
            }

            if let partial = partialResponse {
                fullResponse += partial
                DispatchQueue.main.async {
                    partialHandler(fullResponse)
                }
            } else {
                // Final call
                DispatchQueue.main.async {
                    completion(fullResponse)
                }
            }
        }
    }
}
