import ComposableArchitecture
import SwiftUI

@main
struct DoubleModaleShowcaseApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                VStack {
                    NavigationLink(destination: {
                        ContentView(
                            store: .init(
                                initialState: .init(),
                                reducer: {
                                    ContentReducer()._printChanges()
                                }))
                    }) {
                        Label("SwiftUI", systemImage: "globe")
                    }
                    NavigationLink(destination: {
                        UIViewControllerRepresenting {
                            ContentViewController(
                                store: .init(
                                    initialState: .init(),
                                    reducer: {
                                        ContentReducer()._printChanges()
                                    }))
                        }
                    }) {
                        Label("UIKit", systemImage: "pencil")
                    }
                }
                .navigationTitle("Switch UI")
            }
        }
    }
}
