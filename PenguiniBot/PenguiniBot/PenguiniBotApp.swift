import SwiftUI

@main
struct PenguiniBotApp: App {
    @StateObject private var viewModel = PenguinViewModel()

    var body: some Scene {
        WindowGroup {
            PenguinView(viewModel: viewModel)
        }
    }
}
