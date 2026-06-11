import os
import sys

def check_file(filepath, required_imports, required_keywords):
    if not os.path.exists(filepath):
        print(f"Error: {filepath} not found.")
        return False

    with open(filepath, 'r') as f:
        content = f.read()

    missing_imports = [imp for imp in required_imports if f"import {imp}" not in content]
    missing_keywords = [key for key in required_keywords if key not in content]

    if missing_imports:
        print(f"Error in {filepath}: Missing imports {missing_imports}")
    if missing_keywords:
        print(f"Error in {filepath}: Missing keywords {missing_keywords}")

    return not (missing_imports or missing_keywords)

files_to_check = [
    ("PenguiniBot/PenguiniBot/SpeechManager.swift", ["Speech", "AVFoundation"], ["SFSpeechRecognizer", "penguini"]),
    ("PenguiniBot/PenguiniBot/LLMManager.swift", ["MediaPipeTasksGenAI"], ["LlmInference", "gemma"]),
    ("PenguiniBot/PenguiniBot/VoiceManager.swift", ["AVFoundation"], ["AVSpeechSynthesizer", "pitchMultiplier"]),
    ("PenguiniBot/PenguiniBot/PenguinFace.swift", ["SwiftUI"], ["PenguinExpression", "BeakView"]),
    ("PenguiniBot/PenguiniBot/PenguinViewModel.swift", ["Combine"], ["PenguinViewModel", "llmManager"]),
    ("PenguiniBot/PenguiniBot/PenguiniBotApp.swift", ["SwiftUI"], ["PenguiniBotApp", "@main"]),
]

all_passed = True
for filepath, imports, keywords in files_to_check:
    if not check_file(filepath, imports, keywords):
        all_passed = False

if not os.path.exists("PenguiniBot/PenguiniBot.xcodeproj/project.pbxproj"):
    print("Error: project.pbxproj not found.")
    all_passed = False

if not os.path.exists("PenguiniBot/PenguiniBot/Info.plist"):
    print("Error: Info.plist not found.")
    all_passed = False

if all_passed:
    print("All basic validations passed!")
    sys.exit(0)
else:
    print("Some validations failed.")
    sys.exit(1)
