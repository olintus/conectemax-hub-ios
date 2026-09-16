import SwiftUI

struct HubScreen: View {
    @Bindable var model: HubModel
    var body: some View {
        Group {
            if let hub = model.hub {
                TabView {
                    container(hub: hub) { HomeScreen(hub: hub, reload: model.reload) }.tabItem { Label("Início", systemImage: "house") }
                    container(hub: hub) { ModuleList(title: "Conecte+", subtitle: "Seu plano abre novas possibilidades", modules: hub.modules.filter { $0.category == "plus" }) }.tabItem { Label("Conecte+", systemImage: "play.circle") }
                    container(hub: hub) { CityScreen(weather: hub.weather, camera: hub.weatherCamera) }.tabItem { Label("Cidade", systemImage: "building.2") }
                    container(hub: hub) { SupportHomeScreen(tickets: hub.supportTickets, model: model) }.tabItem { Label("Suporte", systemImage: "headphones") }
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
                switch id {
                case "billing": BillingScreen(billing: hub.billing)
                case "traffic": TrafficScreen(traffic: hub.traffic, model: model)
                case "speedtest": SpeedTestScreen()
                case "weather-details": WeatherDetailsScreen(weather: hub.weather, camera: hub.weatherCamera)
                case "wifi-outdoor": WifiOutsideScreen()
                case "avisos": NotificationsScreen(notifications: hub.notifications)
                case "minha": ContractsScreen(contracts: hub.contracts, selectedId: hub.selectedContractId, model: model)
                case "mais": AddOnsScreen(summary: hub.addOns, contracts: hub.contracts, selectedId: hub.selectedContractId, model: model)
                case "support-tickets": SupportTicketsScreen(tickets: hub.supportTickets)
                case "suporte": SupportHomeScreen(tickets: hub.supportTickets, model: model)
                default:
                    if let module = hub.modules.first(where: { $0.id == id }) { ModuleScreen(module: module) }
                }
            }
        }
    }
}
struct HomeScreen: View {
    let hub: Hub
    let reload: () -> Void
    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 14) {
                ZStack(alignment: .bottomTrailing) {
                    LinearGradient(colors: [HubStyle.dark, HubStyle.blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                    Circle().fill(HubStyle.orange).frame(width: 72).offset(x: 20, y: 22)
                    VStack(alignment: .leading, spacing: 12) {
                        Image("ConecteLogo").resizable().scaledToFit().frame(width: 255, height: 92).accessibilityLabel("Conecte Max")
                        Spacer().frame(height: 8)
                        Text("Olá, \(hub.name.uppercased())!").font(.system(size: 31, weight: .regular)).foregroundStyle(.white).lineLimit(2)
                        Text("Tudo o que conecta você está aqui.").font(.title3).foregroundStyle(.white.opacity(0.84))
                    }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading).padding(22)
                }.frame(height: 280)
                NavigationLink(value: "minha") {
                    HubCard { VStack(spacing: 16) {
                        HStack(spacing: 16) {
                            Image(systemName: "wifi").font(.system(size: 32, weight: .bold)).foregroundStyle(.white).frame(width: 86, height: 86).background(HubStyle.orange, in: Circle())
                            VStack(alignment: .leading, spacing: 5) {
                                HStack { Text(hub.status).font(.title3); Circle().fill(HubStyle.orange).frame(width: 12, height: 12) }
                                Text(hub.plan).font(.system(size: 25, weight: .regular)).foregroundStyle(HubStyle.ink).lineLimit(2)
                                Text("Plano de internet do contrato selecionado").font(.title3).foregroundStyle(HubStyle.medium)
                            }.frame(maxWidth: .infinity, alignment: .leading)
                        }
                        Divider()
                        HStack { Image(systemName: "doc.text.fill").font(.system(size: 34)).foregroundStyle(HubStyle.ink); VStack(alignment: .leading, spacing: 2) { Text("CONTRATO").font(.caption.bold()).foregroundStyle(HubStyle.medium); Text(hub.selectedContractId ?? "--").font(.system(size: 25, weight: .regular)) }; Spacer(); Text("Trocar contrato").font(.headline).foregroundStyle(HubStyle.blue); Text("→").font(.headline).foregroundStyle(HubStyle.blue) }
                    } }.frame(minHeight: 250)
                }.buttonStyle(.plain).padding(.horizontal, 20).padding(.top, -32)
                HomeInvoiceCard(open: hub.billing.open.first, paid: hub.billing.paid.first).padding(.horizontal, 20)
                HomePromiseCard().padding(.horizontal, 20)
                Text("Acesso rápido").font(.title3.bold()).padding(.horizontal, 20).padding(.top, 2)
                LazyVGrid(columns: columns, spacing: 12) {
                    QuickLink(title: "Faturas", icon: "doc.text", target: "billing")
                    QuickLink(title: "Velocidade", icon: "gauge", target: "speedtest")
                    QuickLink(title: "Consumo", icon: "chart.bar", target: "traffic")
                    QuickLink(title: "Suporte", icon: "headphones", target: "suporte")
                    QuickLink(title: "Contratos", icon: "rectangle.stack", target: "minha")
                    QuickLink(title: "Serviços", icon: "play.circle", target: "mais")
                }.padding(.horizontal, 20)
                ZStack(alignment: .bottomTrailing) {
                    RoundedRectangle(cornerRadius: 24).fill(HubStyle.blue)
                    Circle().fill(HubStyle.orange.opacity(0.9)).frame(width: 100).offset(x: 32, y: 34)
                    VStack(alignment: .leading, spacing: 6) { Text("Uma vida mais").foregroundStyle(.white).font(.headline); Text("conectada te espera.").foregroundStyle(HubStyle.orange).font(.headline); Text("Internet, streaming, benefícios e muito mais.").foregroundStyle(.white.opacity(0.85)).font(.subheadline); Text("Conheça agora  →").foregroundStyle(.white).font(.subheadline.bold()).padding(.top, 8) }.frame(maxWidth: .infinity, alignment: .leading).padding(22)
                }.frame(height: 150).padding(.horizontal, 20)
                Button("Atualizar informações", action: reload).frame(maxWidth: .infinity).foregroundStyle(HubStyle.blue).padding(.vertical, 8)
            }.padding(.bottom, 28)
        }.navigationTitle("").navigationBarTitleDisplayMode(.inline)
    }
}

private struct QuickLink: View {
    let title: String; let icon: String; let target: String
    var body: some View { NavigationLink(value: target) { VStack(alignment: .leading, spacing: 12) { Image(systemName: icon).foregroundStyle(HubStyle.blue).font(.title3).frame(width: 42, height: 42).background(HubStyle.blue.opacity(0.10), in: RoundedRectangle(cornerRadius: 13)); Text(title).font(.caption.bold()).foregroundStyle(HubStyle.ink).lineLimit(1) }.frame(maxWidth: .infinity, minHeight: 112, alignment: .leading).padding(13).background(.white, in: RoundedRectangle(cornerRadius: 18)).overlay(RoundedRectangle(cornerRadius: 18).stroke(HubStyle.gray, lineWidth: 1)) }.buttonStyle(.plain) }
}
private struct HomeInvoiceCard: View {
    let open: Invoice?
    let paid: Invoice?
    private var invoice: Invoice? { open ?? paid }
    var body: some View {
        NavigationLink(value: "billing") {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Última fatura").font(.subheadline).foregroundStyle(HubStyle.medium)
                    if let invoice {
                        Text(currency(invoice.amount)).font(.title3.bold()).foregroundStyle(open == nil ? .green : HubStyle.orange)
                        Text(open == nil ? "Pago" : "Vencimento: \(dateLabel(invoice.dueDate))").font(.caption).foregroundStyle(HubStyle.medium)
                    } else { Text("Ainda não foi gerada uma fatura no período").font(.headline) }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 14) { Label(open == nil ? "Ver faturas" : "Pagar fatura", systemImage: "viewfinder").font(.headline.bold()).foregroundStyle(.white).padding(.horizontal, 16).padding(.vertical, 11).background(HubStyle.orange, in: Capsule()); Text("Ver faturas").font(.headline.bold()).foregroundStyle(HubStyle.blue) }
            }
            .padding(20)
            .frame(minHeight: 164)
            .background(.white, in: RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(HubStyle.gray, lineWidth: 1))
            .shadow(color: .black.opacity(0.10), radius: 8, y: 4)
        }.buttonStyle(.plain)
    }
}
private struct HomePromiseCard: View {
    var body: some View {
        HubCard { HStack(spacing: 16) {
            Image(systemName: "calendar.badge.clock").font(.title2).foregroundStyle(HubStyle.blue).frame(width: 58, height: 58).background(HubStyle.blue.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
            VStack(alignment: .leading, spacing: 4) { Text("Promessa de pagamento").font(.headline); Text("Negocie e mantenha sua conexão em dia.").font(.caption).foregroundStyle(HubStyle.medium) }
            Spacer(); Text("›").font(.title).foregroundStyle(HubStyle.orange)
        } }.opacity(0.46)
    }
}
struct ModuleList: View {
    let title: String
    let subtitle: String
    let modules: [HubModule]
    var body: some View {
        ScrollView { LazyVStack(alignment: .leading, spacing: 16) {
            ZStack(alignment: .bottomTrailing) {
                LinearGradient(colors: [HubStyle.dark, HubStyle.blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                Image(systemName: "play.circle.fill").font(.system(size: 96)).foregroundStyle(.white.opacity(0.18)).padding(18)
                VStack(alignment: .leading, spacing: 8) { Text("BENEFÍCIOS E SERVIÇOS").font(.caption.bold()).foregroundStyle(HubStyle.orange); Text(title).font(.largeTitle.bold()).foregroundStyle(.white); Text(subtitle).foregroundStyle(.white.opacity(0.82)) }.frame(maxWidth: .infinity, alignment: .leading).padding(24)
            }.frame(height: 210).clipShape(RoundedRectangle(cornerRadius: 26))
            ForEach(modules) { ModuleLink(module: $0) }
        }.padding(20) }
    }
}
struct ModuleLink: View {
    let module: HubModule
    var body: some View {
        NavigationLink(value: module.id) {
            HubCard { HStack(alignment: .center, spacing: 16) {
                Image(systemName: symbol(module.icon)).font(.title2).foregroundStyle(module.id == "energia" ? .green : HubStyle.blue).frame(width: 68, height: 68).background((module.id == "energia" ? Color.green : HubStyle.blue).opacity(0.12), in: RoundedRectangle(cornerRadius: 20)).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 6) { Text(module.title).font(.title3.bold()); Text(module.subtitle).font(.subheadline).foregroundStyle(HubStyle.medium).lineLimit(3) }.frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "arrow.right").foregroundStyle(HubStyle.orange).padding(10).background(HubStyle.orange.opacity(0.12), in: Circle()).accessibilityHidden(true)
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
    @State private var current = ""
    @State private var password = ""
    @State private var confirmation = ""
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
