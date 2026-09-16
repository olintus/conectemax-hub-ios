import SwiftUI

@main struct ConecteMaxHubApp: App {
    @State private var model: HubModel
    init() {
        let url = URL(string: "https://api-homolog.conectemax.com.br/")!
        let auth = DemoAPIAuthRepository(api: APIClient(baseURL: url), store: KeychainSessionStore())
        _model = State(initialValue: HubModel(auth: auth, repository: DemoAPIHubRepository(auth: auth)))
    }
    var body: some Scene {
        WindowGroup {
            Group { if model.stage == "hub" { HubScreen(model: model) } else { AuthScreen(model: model) } }
                .tint(HubStyle.orange).foregroundStyle(HubStyle.ink).preferredColorScheme(.light)
                .task { if model.stage == "restore" { model.restore() } }
        }
    }
}
