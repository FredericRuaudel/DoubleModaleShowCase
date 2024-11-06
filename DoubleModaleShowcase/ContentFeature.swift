import ComposableArchitecture
import SwiftUI
import UIKit

@Reducer
struct ContentReducer {
    @ObservableState
    struct State: Equatable {
        @Presents var destination: Destination.State?
        init() {}
    }

    enum Action {
        case showModaleButtonTapped
        case destination(PresentationAction<Destination.Action>)
    }

    @Reducer(state: .equatable)
    enum Destination {
        case modale(ModaleReducer)
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .showModaleButtonTapped:
                state.destination = .modale(.init())
                return .none
            case .destination:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
}

struct ContentView: View {
    @Bindable var store: StoreOf<ContentReducer>

    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
            Button("Show modal") {
                store.send(.showModaleButtonTapped)
            }
        }
        .padding()
        .sheet(
            item: $store.scope(
                state: \.destination?.modale,
                action: \.destination.modale
            )
        ) { modaleStore in
            ModaleView(store: modaleStore)
        }
    }
}

class ContentViewController: UIViewController {
    @UIBindable var store: StoreOf<ContentReducer>

    init(store: StoreOf<ContentReducer>) {
        self.store = store
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let button = UIButton(
            frame: .zero,
            primaryAction: UIAction {
                [weak self] _ in
                self?.store.send(.showModaleButtonTapped)
            })
        button.setTitle("Show modal", for: .normal)
        button.setTitleColor(.tintColor, for: .normal)

        let stackView = UIStackView(arrangedSubviews: [
            button
        ])
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 16),
            stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 16),
        ])
        view.backgroundColor = .systemBackground

        present(item: $store.scope(state: \.destination?.modale, action: \.destination.modale)) { modaleStore in
            let modaleVC = ModaleViewController(store: modaleStore)
            modaleVC.modalPresentationStyle = .pageSheet
            return UINavigationController(rootViewController: modaleVC)
        }
    }
}

#Preview("SwiftUI") {
    ContentView(
        store: .init(
            initialState: .init(),
            reducer: {
                ContentReducer()._printChanges()
            }
        )
    )
}

#Preview("UIKit") {
    UIViewControllerRepresenting {
        ContentViewController(
            store: .init(
                initialState: .init(),
                reducer: {
                    ContentReducer()._printChanges()
                }
            )
        )
    }
}
