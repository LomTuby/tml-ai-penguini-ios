import Foundation
import CLiteRTLM

@MainActor // <-- Added @MainActor to ensure state synchronization and Sendability for concurrent contexts
final class LLMManager: ObservableObject {
    private var engineHandle: OpaquePointer?
    private var conversationHandle: OpaquePointer?
    @Published var isModelLoaded = false
    @Published var responseText = ""

    init() {
        setupModel()
    }

    deinit {
        if let conversationHandle {
            litert_lm_conversation_delete(conversationHandle)
        }
        if let engineHandle {
            litert_lm_engine_delete(engineHandle)
        }
    }

    private func setupModel() {
        guard let modelPath = Bundle.main.path(forResource: "gemma-4-E4B-it", ofType: "litertlm") else {
            print("Gemma 4 E4B model file not found in bundle.")
            return
        }

        let settings = litert_lm_engine_settings_create(modelPath, "cpu", nil, nil)
        guard let settings else {
            print("Failed to create LiteRT-LM engine settings.")
            return
        }
        defer { litert_lm_engine_settings_delete(settings) }

        litert_lm_engine_settings_set_max_num_tokens(settings, 1024)

        if let cachesURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
            litert_lm_engine_settings_set_cache_dir(settings, cachesURL.path)
        }

        guard let engine = litert_lm_engine_create(settings) else {
            print("Failed to create LiteRT-LM engine.")
            return
        }

        self.engineHandle = engine

        let cSessionConfig = litert_lm_session_config_create()
        guard let cSessionConfig else {
            print("Failed to create LiteRT-LM session config.")
            return
        }
        defer { litert_lm_session_config_delete(cSessionConfig) }

        guard let conversation = litert_lm_conversation_create(engine, litert_lm_conversation_config_create()) else {
            print("Failed to create LiteRT-LM conversation.")
            return
        }

        self.conversationHandle = conversation
        DispatchQueue.main.async {
            self.isModelLoaded = true
        }
    }

    func generateResponse(prompt: String, completion: @escaping (String) -> Void) {
        guard let conversationHandle else {
            completion("I'm sorry, I'm still waking up. (Gemma 4 not loaded)")
            return
        }

        Task {
            do {
                let text = try await sendMessage(conversationHandle: conversationHandle, prompt: prompt)
                // Operation is now safely on the MainActor due to class marking and DispatchQueue.main.async
                self.responseText = text 
                completion(text)
            } catch {
                // Operation is now safely on the MainActor
                DispatchQueue.main.async {
                    completion("Oops, I got a bit confused! \(error.localizedDescription)")
                }
            }
        }
    }

    func generateResponseStream(
        prompt: String,
        partialHandler: @escaping (String) -> Void,
        completion: @escaping (String) -> Void
    ) {
        guard let conversationHandle else {
            completion("LLM not loaded.")
            return
        }

        Task {
            do {
                let accumulator = ResponseAccumulator()
                for try await chunk in sendMessageStream(conversationHandle: conversationHandle, prompt: prompt) {
                    accumulator.append(chunk)
                    let snapshot = accumulator.value
                    DispatchQueue.main.async {
                        partialHandler(snapshot)
                    }
                }

                let finalResponse = accumulator.value
                DispatchQueue.main.async {
                    self.responseText = finalResponse
                    completion(finalResponse)
                }
            } catch {
                DispatchQueue.main.async {
                    completion("Failed to start generation: \(error.localizedDescription)")
                }
            }
        }
    }

    private func sendMessage(conversationHandle: OpaquePointer, prompt: String) async throws -> String {
        let messageString = try jsonMessageString(prompt: formattedPrompt(prompt))
        guard let responsePtr = litert_lm_conversation_send_message(conversationHandle, messageString, nil, nil) else {
            throw NSError(domain: "LiteRTLM", code: -1, userInfo: [NSLocalizedDescriptionKey: "Native sendMessage returned null."])
        }
        defer { litert_lm_json_response_delete(responsePtr) }

        guard let responseChars = litert_lm_json_response_get_string(responsePtr) else {
            throw NSError(domain: "LiteRTLM", code: -2, userInfo: [NSLocalizedDescriptionKey: "Native response string was null."])
        }

        return extractText(fromJSON: String(cString: responseChars))
    }

    private func sendMessageStream(conversationHandle: OpaquePointer, prompt: String) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let context = StreamContext(continuation: continuation)
            let retained = Unmanaged.passRetained(context)

            do {
                let messageString = try jsonMessageString(prompt: formattedPrompt(prompt))
                let status = litert_lm_conversation_send_message_stream(
                    conversationHandle,
                    messageString,
                    nil,
                    nil,
                    streamCallback,
                    retained.toOpaque()
                )

                if status != 0 {
                    retained.release()
                    continuation.finish(throwing: NSError(domain: "LiteRTLM", code: Int(status), userInfo: [NSLocalizedDescriptionKey: "Failed to start stream."]))
                }
            } catch {
                retained.release()
                continuation.finish(throwing: error)
            }
        }
    }

    internal final class StreamContext { // Changed 'private' to 'internal'
        let continuation: AsyncThrowingStream<String, Error>.Continuation

        init(continuation: AsyncThrowingStream<String, Error>.Continuation) {
            self.continuation = continuation
        }
    }

    private final class ResponseAccumulator {
        var value = ""

        func append(_ chunk: String) {
            value += chunk
        }
    }
}

private func streamCallback(
    userData: UnsafeMutableRawPointer?,
    responseJson: UnsafePointer<CChar>?,
    isFinal: Bool,
    errorMessage: UnsafePointer<CChar>?
) {
    guard let userData else { return }
    let context = Unmanaged<LLMManager.StreamContext>.fromOpaque(userData).takeUnretainedValue()

    if let errorMessage {
        context.continuation.finish(throwing: NSError(domain: "LiteRTLM", code: -1, userInfo: [NSLocalizedDescriptionKey: String(cString: errorMessage)]))
        Unmanaged<LLMManager.StreamContext>.fromOpaque(userData).release()
        return
    }

    if let responseJson {
        context.continuation.yield(extractText(fromJSON: String(cString: responseJson)))
    }

    if isFinal {
        context.continuation.finish()
        Unmanaged<LLMManager.StreamContext>.fromOpaque(userData).release()
    }
}

private func extractText(fromJSON jsonString: String) -> String {
    guard let data = jsonString.data(using: .utf8),
          let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          let content = object["content"] as? [[String: Any]] else {
        return jsonString
    }

    return content.compactMap { item in
        guard let type = item["type"] as? String, type == "text" else { return nil }
        return item["text"] as? String
    }.joined(separator: " ")
}

private func jsonMessageString(prompt: String) throws -> String {
    let json: [String: Any] = [
        "role": "user",
        "content": [["type": "text", "text": prompt]]
    ]
    let data = try JSONSerialization.data(withJSONObject: json, options: [])
    guard let string = String(data: data, encoding: .utf8) else {
        throw NSError(domain: "LiteRTLM", code: -3, userInfo: [NSLocalizedDescriptionKey: "Failed to encode message JSON."])
    }
    return string
}

private func formattedPrompt(_ prompt: String) -> String {
    let instruction = "You are Penguini, a friendly AI penguin talking to a 10-year-old. Keep answers short, simple, and concise. Avoid long explanations unless asked."
    return "\(instruction)\n\nUser: \(prompt)"
}
