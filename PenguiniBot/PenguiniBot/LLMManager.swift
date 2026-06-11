import Foundation

#if canImport(MediaPipeTasksGenAI)
import MediaPipeTasksGenAI
#elseif canImport(SwiftTasksGenAI)
import SwiftTasksGenAI
#endif

class LLMManager: ObservableObject {
    private var llmInference: LlmInference?
    @Published var isModelLoaded = false
    @Published var responseText = ""

    init() {
        setupModel()
    }

    private func setupModel() {
        // Updated for Gemma 4 E4B
        guard let modelPath = Bundle.main.path(forResource: "gemma-4-E4B-it", ofType: "litertlm") else {
            print("Gemma 4 E4B model file not found in bundle.")
            return
        }

        let options = LlmInference.Options(modelPath: modelPath)
        options.maxTokens = 1024

        do {
            llmInference = try LlmInference(options: options)
            DispatchQueue.main.async {
                self.isModelLoaded = true
            }
        } catch {
            print("Failed to initialize LlmInference with Gemma 4: \(error)")
        }
    }

    func generateResponse(prompt: String, completion: @escaping (String) -> Void) {
        guard let llmInference = llmInference else {
            completion("I'm sorry, I'm still waking up. (Gemma 4 not loaded)")
            return
        }

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

    func generateResponseStream(prompt: String, partialHandler: @escaping (String) -> Void, completion: @escaping (String) -> Void) {
        guard let llmInference = llmInference else { return }

        let formattedPrompt = "<start_of_turn>user\n\(prompt)<end_of_turn>\n<start_of_turn>model\n"
        var fullResponse = ""

        // generateResponseAsync is not a throwing function in the current SDK version
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
            }
        } completion: {
            DispatchQueue.main.async {
                completion(fullResponse)
            }
        }
    }
}
