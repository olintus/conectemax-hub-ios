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
            Group {
                if model.stage == "restore" { LaunchLoadingScreen(error: model.error, retry: model.restore) }
                else if model.stage == "hub" { HubScreen(model: model) }
                else { AuthScreen(model: model) }
            }
                .tint(HubStyle.orange).foregroundStyle(HubStyle.ink).preferredColorScheme(.light)
                .task { if model.stage == "restore" { model.restore() } }
        }
    }
}

private struct LaunchLoadingScreen: View {
    let error: String?
    let retry: () -> Void
    var body: some View {
        ZStack {
            LinearGradient(colors: [HubStyle.dark, HubStyle.blue], startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
            VStack(spacing: 22) {
                Image(systemName: "wifi").font(.system(size: 58, weight: .bold)).foregroundStyle(.white).frame(width: 120, height: 120).background(.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 32))
                Text("conecte max").font(.system(size: 34, weight: .bold)).foregroundStyle(.white)
                Text(error == nil ? "Preparando tudo para você" : "Não foi possível carregar suas informações").font(.title3).foregroundStyle(.white).multilineTextAlignment(.center)
                if error == nil { ProgressView().tint(HubStyle.orange); Text("Só um instante…").foregroundStyle(.white.opacity(0.76)) }
                else { Text(error!).foregroundStyle(.white.opacity(0.78)).multilineTextAlignment(.center); Button("Tentar novamente", action: retry).buttonStyle(PrimaryButton()) }
            }.padding(34)
        }
    }
}
