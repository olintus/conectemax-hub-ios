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
            HubStyle.blue.ignoresSafeArea()
            GeometryReader { proxy in
                VStack(spacing: 0) {
                    Spacer().frame(height: proxy.size.height * 0.34)
                    Image("ConecteLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: min(proxy.size.width - 72, 350))
                        .accessibilityLabel("Conecte Max")
                    Spacer().frame(height: 56)
                    Text(error == nil ? "Preparando tudo para você" : "Não foi possível carregar suas informações")
                        .font(.system(size: 29, weight: .regular))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 26)
                    Spacer().frame(height: 76)
                    if error == nil {
                        ProgressView()
                            .controlSize(.large)
                            .tint(HubStyle.orange)
                        Spacer().frame(height: 42)
                        Text("Só um instante…")
                            .font(.title3)
                            .foregroundStyle(.white.opacity(0.76))
                    } else {
                        Text(error!)
                            .foregroundStyle(.white.opacity(0.78))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 34)
                        Spacer().frame(height: 22)
                        Button("Tentar novamente", action: retry)
                            .buttonStyle(PrimaryButton())
                            .padding(.horizontal, 34)
                    }
                    Spacer()
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
            }
        }
    }
}
