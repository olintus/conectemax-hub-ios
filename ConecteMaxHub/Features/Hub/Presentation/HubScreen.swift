import SwiftUI

struct HubScreen: View {
    @Bindable var model: HubModel
    var body: some View {
        Group {
            if let hub = model.hub {
                TabView {
                    container(hub: hub) { HomeScreen(hub: hub, reload: model.reload) }.tabItem { Label("Início", systemImage: "house") }
                    container(hub: hub) { ModuleList(title: "Conecte+", subtitle: "Seu plano abre novas possibilidades", modules: hub.modules.filter { $0.category == "plus" }) }.tabItem { Label("Conecte+", systemImage: "play.circle") }
                    container(hub: hub) { ModuleList(title: "Perto de você", subtitle: "Descubra sua cidade e siga conectado", modules: hub.modules.filter { $0.category == "city" }) }.tabItem { Label("Cidade", systemImage: "building.2") }
                    container(hub: hub) { if let module = hub.modules.first(where: { $0.id == "suporte" }) { ModuleScreen(module: module) } }.tabItem { Label("Suporte", systemImage: "headphones") }
                    container(hub: hub) { ProfileScreen(model: model) }.tabItem { Label("Perfil", systemImage: "person") }
                }
            } else {
                VStack(spacing: 20) { if model.busy { ProgressView() }; if let error = model.error { Text(error) }; Button("Carregar conteúdo", action: model.reload).disabled(model.busy) }.padding()
            }
        }.background(HubStyle.paper)
    }
    private func container<Content: View>(hub: Hub, @ViewBuilder content: () -> Content) -> some View {
        NavigationStack {
            VStack(spacing: 0) {
                if model.busy { ProgressView().padding(4) }
                if let error = model.error { Text(error).font(.caption).foregroundStyle(.red).padding(12) }
                content()
            }
            .background(HubStyle.paper).navigationTitle("Conecte Max Hub").navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(HubStyle.dark, for: .navigationBar).toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { NavigationLink(value: "avisos") { Image(systemName: "bell").foregroundStyle(.white).accessibilityLabel("Avisos") } } }
            .navigationDestination(for: String.self) { id in
                if let module = hub.modules.first(where: { $0.id == id }) { ModuleScreen(module: module) }
            }
        }
    }
}
struct HomeScreen: View {
    let hub: Hub
    let reload: () -> Void
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                Text("SEU DIA, MAIS CONECTADO").font(.caption.bold()).foregroundStyle(HubStyle.blue)
                Text("Olá, \(hub.name).").font(.largeTitle.bold())
                Text("Tudo o que conecta você está aqui.").foregroundStyle(.secondary)
                NavigationLink(value: "minha") {
                    VStack(alignment: .leading, spacing: 16) {
                        Label(hub.status, systemImage: "wifi").font(.subheadline)
                        Text(hub.plan).font(.title.bold())
                        Text("Minha Conecte  →").font(.headline).foregroundStyle(HubStyle.orange)
                    }.frame(maxWidth: .infinity, alignment: .leading).padding(24)
                        .foregroundStyle(Color.white).background(LinearGradient(colors: [HubStyle.dark, HubStyle.blue], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 24))
                }.buttonStyle(.plain)
                Text("Seu Hub").font(.title2.bold())
                ForEach(hub.modules.filter { ["mais", "clube", "wifi", "indique"].contains($0.id) }) { ModuleLink(module: $0) }
                Text("Acontece por aqui").font(.title2.bold())
                ForEach(hub.modules.filter { ["cidade", "cameras", "avisos"].contains($0.id) }) { ModuleLink(module: $0) }
                Text(hub.notice).font(.caption).foregroundStyle(.secondary)
                Button("Atualizar informações", action: reload)
            }.padding(24)
        }
    }
}
struct ModuleList: View {
    let title: String
    let subtitle: String
    let modules: [HubModule]
    var body: some View {
        ScrollView { LazyVStack(alignment: .leading, spacing: 16) {
            Text(title).font(.largeTitle.bold()); Text(subtitle).foregroundStyle(.secondary)
            ForEach(modules) { ModuleLink(module: $0) }
        }.padding(24) }
    }
}
struct ModuleLink: View {
    let module: HubModule
    var body: some View {
        NavigationLink(value: module.id) {
            HubCard { HStack(alignment: .top, spacing: 16) {
                Image(systemName: symbol(module.icon)).font(.title2).foregroundStyle(HubStyle.blue).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 6) { Text(module.title).font(.headline); Text(module.subtitle).font(.subheadline).foregroundStyle(.secondary) }.frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.right").foregroundStyle(HubStyle.orange).accessibilityHidden(true)
            } }
        }.buttonStyle(.plain)
    }
}
struct ModuleScreen: View {
    let module: HubModule
    @State private var selected: HubItem?
    var body: some View {
        ScrollView { LazyVStack(alignment: .leading, spacing: 18) {
            Image(systemName: symbol(module.icon)).font(.largeTitle).foregroundStyle(HubStyle.blue).accessibilityHidden(true)
            Text(module.title).font(.largeTitle.bold())
            Text(module.subtitle).foregroundStyle(.secondary)
            ForEach(module.items) { item in HubCard {
                Text(item.title).font(.title2.bold())
                Text(item.detail).foregroundStyle(.secondary)
                Button(item.action + "  →") { selected = item }.padding(.vertical, 8)
            } }
        }.padding(24) }.background(HubStyle.paper)
            .sheet(item: $selected) { item in NavigationStack {
                VStack(alignment: .leading, spacing: 20) { Text(item.title).font(.title.bold()); Text(item.detail); Spacer() }.padding(24)
                    .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Entendi") { selected = nil } } }
            }.presentationDetents([.medium, .large]) }
    }
}
struct ProfileScreen: View {
    @Bindable var model: HubModel
    @State private var current = "", password = "", confirmation = ""
    var body: some View {
        ScrollView { VStack(alignment: .leading, spacing: 20) {
            Text("Meu perfil").font(.largeTitle.bold())
            Text(model.hub?.name ?? "")
            HubCard {
                Text("Segurança").font(.title2.bold())
                Text("Gerencie sua senha de acesso.")
                Text("Alterar senha").font(.headline)
                SecureField("Senha atual", text: $current).textContentType(.password).hubField()
                SecureField("Nova senha", text: $password).textContentType(.newPassword).hubField()
                SecureField("Confirmar nova senha", text: $confirmation).textContentType(.newPassword).hubField()
                Button("Alterar e encerrar sessões") { model.changePassword(current, password, confirmation); current = ""; password = ""; confirmation = "" }
                    .buttonStyle(PrimaryButton()).disabled(model.busy || current.isEmpty || password.isEmpty || password.count > 128 || password != confirmation)
            }
            Button("Sair da conta", action: model.logout).buttonStyle(.bordered).disabled(model.busy)
        }.padding(24) }
    }
}
private func symbol(_ icon: String) -> String {
    switch icon { case "wifi": "wifi"; case "play": "play.circle"; case "gift": "gift"; case "city": "building.2"; case "video": "video"; case "help": "headphones"; default: "bell" }
}
