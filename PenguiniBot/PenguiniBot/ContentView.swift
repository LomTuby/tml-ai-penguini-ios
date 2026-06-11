import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: PenguinViewModel

    var body: some View {
        PenguinView(viewModel: viewModel)
    }
}
