import ComposableArchitecture
import SwiftUI

@Reducer
struct ShareOptionsReducer {
    @ObservableState
    struct State: Equatable {
    }

    enum Action {
        case dismissThenShareButtonTapped
        case shareButtonTapped
        case cancelButtonTapped
        case delegate(DelegateAction)
    }

    @CasePathable
    enum DelegateAction {
        case share(Int)
        case dismissThenShare(Int)
        case cancelSharing
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .cancelButtonTapped:
                return .send(.delegate(.cancelSharing))
            case .shareButtonTapped:
                return .send(.delegate(.share(Int.random(in: 0...42))))
            case .dismissThenShareButtonTapped:
                return .send(.delegate(.dismissThenShare(Int.random(in: 0...42))))
            case .delegate:
                return .none
            }
        }
    }
}

struct ShareOptionsView: View {
    let store: StoreOf<ShareOptionsReducer>

    var body: some View {
        NavigationStack {
            VStack {
                Image(systemName: "globe")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                Text("Hello, share sheet options!")
            }
            .padding()
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button("Share") {
                        store.send(.shareButtonTapped)
                    }
                    Button("Dismiss & Share") {
                        store.send(.dismissThenShareButtonTapped)
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        store.send(.cancelButtonTapped)
                    }
                }
            }
        }
        .frame(width: 400, height: 300)
    }
}

class ShareOptionsViewController: UIViewController {
    let store: StoreOf<ShareOptionsReducer>

    init(store: StoreOf<ShareOptionsReducer>) {
        self.store = store
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let label = UILabel()
        label.text = "Hello, share sheet options!"
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])

        let shareBarButton = UIBarButtonItem(
            title: "Share",
            style: .plain,
            target: self,
            action: #selector(shareButtonTapped)
        )

        let dismissThenShareBarButton = UIBarButtonItem(
            title: "Dismiss & Share",
            style: .plain,
            target: self,
            action: #selector(dismissThenShareButtonTapped)
        )

        navigationItem.rightBarButtonItems = [
            shareBarButton,
            dismissThenShareBarButton,
        ]

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Cancel",
            style: .plain,
            target: self,
            action: #selector(cancelButtonTapped)
        )

    }

    @objc func shareButtonTapped() {
        store.send(.shareButtonTapped)
    }

    @objc func cancelButtonTapped() {
        store.send(.cancelButtonTapped)
    }

    @objc func dismissThenShareButtonTapped() {
        store.send(.dismissThenShareButtonTapped)
    }
}

#Preview("SwiftUI") {
    ShareOptionsView(
        store: .init(
            initialState: .init(),
            reducer: {
                ShareOptionsReducer()._printChanges()
            }))
}

#Preview("UIKit") {
    UIViewControllerRepresenting {
        UINavigationController(
            rootViewController: ShareOptionsViewController(
                store: .init(
                    initialState: .init(),
                    reducer: {
                        ShareOptionsReducer()._printChanges()
                    }
                )
            )
        )
    }
}
