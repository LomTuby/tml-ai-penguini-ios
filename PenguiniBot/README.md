# PenguiniBot (Gemma 4 Edition)

PenguiniBot is an offline AI chatbot for iOS featuring a cute, animated penguin. It listens for the keyword "Penguini", processes questions using the **Google Gemma 4 E4B** model locally on your device, and responds with a comical, high-pitched voice and expressive animations.

## Features

- **Keyword Spotting**: Listens for "Penguini" to start an interaction.
- **Offline LLM**: Uses MediaPipe Tasks GenAI with the **Gemma 4 E4B** model for advanced on-device reasoning.
- **Animated Face**: A custom-drawn SwiftUI penguin with context-aware expressions.
- **Comical Voice**: TTS with adjusted pitch for a funny penguin persona.

## Prerequisites

- **Xcode 15.4+**
- **iOS 17.5+** (Optimized for iPhone 17 Pro)

## Setup Instructions

1.  **Open the Project**:
    - Open `PenguiniBot/PenguiniBot.xcodeproj` in Xcode.
2.  **Add Dependencies (Swift Package Manager)**:
    - In Xcode, go to **File > Add Package Dependencies...**
    - Search for the following repository URL: `https://github.com/paescebu/SwiftTasksGenAI`
    - (This is a community-maintained SPM wrapper for MediaPipe GenAI Tasks).
    - Select **Up to Next Major Version** and click **Add Package**.
    - **Important**: In the next dialog, choose the `SwiftTasksGenAI` library and add it to the `PenguiniBot` target.
3.  **Download the Gemma 4 Model**:
    - Visit [Hugging Face](https://huggingface.co/litert-community/gemma-4-E4B-it-litert-lm).
    - Download the `gemma-4-E4B-it.litertlm` file.
4.  **Add Model to Xcode**:
    - Drag and drop the `gemma-4-E4B-it.litertlm` file into the `PenguiniBot` folder in the Xcode Project Navigator.
    - Ensure **"Copy items if needed"** and **"Add to targets: PenguiniBot"** are checked.
5.  **Run the App**:
    - Select your iPhone 17 Pro as the target device.
    - Build and Run (Cmd+R).

## Troubleshooting

### "Unable to resolve module dependency: 'MediaPipeTasksGenAI'"
If you see this error, it's likely because the Swift Package was added but the library wasn't correctly linked to the target.
1. Select the **PenguiniBot** project in the sidebar.
2. Go to the **PenguiniBot** target > **General** tab.
3. Scroll to **Frameworks, Libraries, and Embedded Content**.
4. Click the **+** button.
5. Select **SwiftTasksGenAI** (from the SwiftTasksGenAI package) and add it.

### Model Loading Error
Ensure the model file extension is `.litertlm` and that it is correctly added to the bundle (Check **Target > Build Phases > Copy Bundle Resources**).

## How to Use

- Say **"Penguini"** to wake him up.
- Wait for him to look surprised (eyes wide, brows up).
- Ask your question.
- Penguini will think and then respond with voice and context-appropriate animations!
