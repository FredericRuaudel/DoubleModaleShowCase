import ComposableArchitecture
import SwiftUI

@Reducer
struct ShareSheetReducer {
    @ObservableState
    struct State: Equatable {
        var value: Int = 0
    }

    enum Action {
        case closeButtonTapped
        case delegate(DelegateAction)
    }

    @CasePathable
    enum DelegateAction {
        case closeSharing
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .closeButtonTapped:
                return .send(.delegate(.closeSharing))
            case .delegate:
                return .none
            }
        }
    }
}

struct ShareSheetView: View {
    let store: StoreOf<ShareSheetReducer>

    var body: some View {
        NavigationStack {
            VStack {
                Image(systemName: "globe")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                Text("Hello, share sheet, sharing \(store.value)!")
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Close") {
                        store.send(.closeButtonTapped)
                    }
                }
            }
        }
        .frame(width: 400, height: 300)
    }
}

class ShareSheetViewController: UIViewController {
    let store: StoreOf<ShareSheetReducer>

    init(store: StoreOf<ShareSheetReducer>) {
        self.store = store
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let label = UILabel()
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])

        observe { [weak self] in
            guard let self else { return }
            label.text = "Hello, share sheet, sharing \(self.store.value)!"
        }

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Close",
            style: .plain,
            target: self,
            action: #selector(closeButtonTapped)
        )
    }

    @objc private func closeButtonTapped() {
        store.send(.closeButtonTapped)
    }
}

#Preview("SwiftUI") {
    ShareSheetView(
        store: .init(
            initialState: .init(value: 42),
            reducer: {
                ShareSheetReducer()._printChanges()
            }))
}

#Preview("UIKit") {
    UIViewControllerRepresenting {
        UINavigationController(
            rootViewController: ShareSheetViewController(
                store: .init(
                    initialState: .init(value: 42),
                    reducer: {
                        ShareSheetReducer()._printChanges()
                    }
                )
            )
        )
    }
}
