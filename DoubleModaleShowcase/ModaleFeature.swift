import ComposableArchitecture
import SwiftUI

@Reducer
struct ModaleReducer {
    @ObservableState
    struct State: Equatable {
        @Presents var destination: Destination.State?
        var shareResultMessage: String = "-"
    }

    enum Action {
        case shareButtonTapped
        case showShareSheet(Int)
        case destination(PresentationAction<Destination.Action>)
    }

    @Reducer(state: .equatable)
    enum Destination {
        case shareOptions(ShareOptionsReducer)
        case shareSheet(ShareSheetReducer)
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .shareButtonTapped:
                state.shareResultMessage = "Start sharing…"
                state.destination = .shareOptions(.init())
                return .none

            case .showShareSheet(let value):
                state.destination = .shareSheet(.init(value: value))
                return .none

            case let .destination(.presented(.shareOptions(.delegate(delegateAction)))):
                switch delegateAction {
                case let .share(value):
                    state.destination = .shareSheet(.init(value: value))
                    return .none
                case let .dismissThenShare(value):
                    state.shareResultMessage = "Sharing \(value)…"
                    state.destination = nil
                    return .run { [value] send in
                        try await Task.sleep(nanoseconds: 1000 * NSEC_PER_MSEC)
                        await send(.showShareSheet(value))
                    }

                case .cancelSharing:
                    state.destination = nil
                    state.shareResultMessage = "Cancel sharing!"
                    return .none
                }
            case let .destination(.presented(.shareSheet(.delegate(delegateAction)))):
                switch delegateAction {
                case .closeSharing:
                    state.destination = nil
                    state.shareResultMessage = "Shared!"
                    return .none
                }
            case .destination:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
}

struct ModaleView: View {
    @Bindable var store: StoreOf<ModaleReducer>

    var body: some View {
        NavigationStack {
            VStack {
                Image(systemName: "globe")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                Text("Sharing status: \(store.shareResultMessage)")
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Share") {
                        store.send(.shareButtonTapped)
                    }
                    .popover(
                        item: $store.scope(
                            state: \.destination,
                            action: \.destination)
                    ) { destinationStore in
                        switch destinationStore.state {
                        case .shareOptions:
                            if let popoverStore = destinationStore.scope(state: \.shareOptions, action: \.shareOptions)
                            {
                                ShareOptionsView(store: popoverStore)
                            }
                        case .shareSheet:
                            if let popoverStore = destinationStore.scope(state: \.shareSheet, action: \.shareSheet) {
                                ShareSheetView(store: popoverStore)
                            }
                        }
                    }
                }
            }
        }
    }
}

class ModaleViewController: UIViewController {
    @UIBindable var store: StoreOf<ModaleReducer>

    init(store: StoreOf<ModaleReducer>) {
        self.store = store
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 16),
            stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 16),
        ])

        let label = UILabel()
        stackView.addArrangedSubview(label)

        let shareBarButton = UIBarButtonItem(
            title: "Share",
            style: .plain,
            target: self,
            action: #selector(shareButtonTapped)
        )
        view.backgroundColor = .systemBackground
        self.navigationItem.rightBarButtonItem = shareBarButton

        observe { [weak self] in
            guard let self else { return }
            label.text = "Sharing status: \(store.shareResultMessage)"
        }

        present(item: $store.scope(state: \.destination, action: \.destination)) { destinationStore in
            var popoverVC: UIViewController?
            switch destinationStore.state {
            case .shareOptions:
                if let popoverStore = destinationStore.scope(state: \.shareOptions, action: \.shareOptions) {
                    popoverVC = ShareOptionsViewController(store: popoverStore)
                }
            case .shareSheet:
                if let popoverStore = destinationStore.scope(state: \.shareSheet, action: \.shareSheet) {
                    popoverVC = ShareSheetViewController(store: popoverStore)
                }
            }

            if let popoverVC {
                let navVC = UINavigationController(rootViewController: popoverVC)
                navVC.modalPresentationStyle = .popover
                navVC.popoverPresentationController?.barButtonItem = shareBarButton
                return navVC
            } else {
                return UIViewController()
            }
        }
    }

    @objc func shareButtonTapped() {
        store.send(.shareButtonTapped)
    }
}

#Preview("SwiftUI") {
    ModaleView(
        store: .init(
            initialState: .init(),
            reducer: {
                ModaleReducer()._printChanges()
            }))
}

#Preview("UIKit") {
    UIViewControllerRepresenting {
        ModaleViewController(
            store: .init(
                initialState: .init(),
                reducer: {
                    ModaleReducer()._printChanges()
                }))
    }
}
