import SwiftUI
import WebKit

struct BillingScreen: View {
    let billing: BillingSummary
    @State private var showingOpen = true
    private var invoices: [Invoice] { showingOpen ? billing.open : billing.paid }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
            Text("Minhas faturas").font(.largeTitle.bold())
            Picker("Faturas", selection: $showingOpen) {
                Text("Em aberto (\(billing.open.count))").tag(true)
                Text("Já pagas (\(billing.paid.count))").tag(false)
            }.pickerStyle(.segmented)
            if invoices.isEmpty {
                EmptyCard(icon: "doc.text", text: showingOpen ? "Não há faturas em aberto." : "Ainda não há faturas pagas disponíveis.")
            }
            ForEach(invoices) { invoice in
                HubCard {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(invoice.status).font(.caption.bold()).foregroundStyle(invoice.status.lowercased().contains("abert") ? HubStyle.orange : .green)
                                Text("Vencimento: \(dateLabel(invoice.dueDate))").font(.headline)
                            }
                            Spacer()
                            Text(currency(invoice.amount)).font(.title3.bold()).foregroundStyle(HubStyle.ink)
                        }
                        if let paidAt = invoice.paidAt { Text("Pagamento: \(dateLabel(paidAt))").font(.subheadline).foregroundStyle(HubStyle.medium) }
                        if let pix = invoice.pix { Text("PIX disponível").font(.caption.bold()).foregroundStyle(HubStyle.blue); Text(pix).font(.caption).lineLimit(1).foregroundStyle(HubStyle.medium) }
                        if let url = invoice.invoiceURL, let destination = URL(string: url) { Link("Abrir fatura", destination: destination).font(.subheadline.bold()).foregroundStyle(HubStyle.blue) }
                    }
                }
            }
            }.padding(20)
        }.navigationTitle("Faturas").navigationBarTitleDisplayMode(.inline)
    }
}

struct TrafficScreen: View {
    let traffic: TrafficSummary?
    @Bindable var model: HubModel
    @State private var pickerOpen = false
    private let months = recentMonths()
    var body: some View {
        ScrollView { VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 14) { Image(systemName: "chart.bar.fill").foregroundStyle(HubStyle.blue).font(.title2).frame(width: 58, height: 58).background(HubStyle.blue.opacity(0.12), in: RoundedRectangle(cornerRadius: 18)); VStack(alignment: .leading) { Text("Consumo de internet").font(.title.bold()); Text("Contrato \(traffic?.contractId ?? "selecionado")").foregroundStyle(HubStyle.medium) } }
            Button { pickerOpen = true } label: { HStack { VStack(alignment: .leading, spacing: 4) { Text("Período").font(.caption.bold()).foregroundStyle(HubStyle.medium); Text(periodLabel(traffic?.from)).font(.title3.bold()).foregroundStyle(HubStyle.ink) }; Spacer(); Image(systemName: "calendar").foregroundStyle(HubStyle.blue) }.padding(20).background(.white, in: RoundedRectangle(cornerRadius: 20)).overlay(RoundedRectangle(cornerRadius: 20).stroke(HubStyle.gray, lineWidth: 1)) }.buttonStyle(.plain)
            ZStack { RoundedRectangle(cornerRadius: 22).fill(HubStyle.dark); HStack { VStack(alignment: .leading, spacing: 4) { Text("Consumo total no período").font(.headline).foregroundStyle(.white); Text("Dados informados pelo SGP").font(.caption).foregroundStyle(.white.opacity(0.78)) }; Spacer(); Text(bytesLabel(traffic?.totalBytes ?? 0)).font(.title2.bold()).foregroundStyle(.white) }.padding(22) }.frame(height: 128)
            if let traffic, !traffic.days.isEmpty { let maximum = max(traffic.days.map(\.bytes).max() ?? 1, 1); ForEach(traffic.days) { day in HStack(spacing: 14) { Text(String(day.date.suffix(2))).font(.headline).frame(width: 30, alignment: .leading); ProgressView(value: day.bytes, total: maximum).tint(HubStyle.blue); Text(bytesLabel(day.bytes)).font(.headline).frame(width: 92, alignment: .trailing) }.padding(16).background(.white, in: RoundedRectangle(cornerRadius: 18)) } } else { EmptyCard(icon: "chart.pie", text: "Ainda não há consumo disponível para este período.") }
        }.padding(20) }.navigationTitle("Consumo").navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Selecione o mês", isPresented: $pickerOpen, titleVisibility: .visible) { ForEach(months) { month in Button(month.label) { model.loadTraffic(month: month.value) } } }
    }
}

struct ContractsScreen: View {
    let contracts: [CustomerContract]
    let selectedId: String?
    @Bindable var model: HubModel
    var body: some View { ScrollView { VStack(alignment: .leading, spacing: 18) { Text("Meus contratos").font(.largeTitle.bold()); ForEach(contracts) { contract in HubCard { VStack(alignment: .leading, spacing: 8) { HStack { Text(contract.statusLabel).font(.caption.bold()).foregroundStyle(contract.id == selectedId ? HubStyle.blue : HubStyle.medium); Spacer(); if contract.id == selectedId { Label("Selecionado", systemImage: "checkmark.circle.fill").font(.caption.bold()).foregroundStyle(.green) } }; Text(contract.address).font(.headline); Text(contract.city).foregroundStyle(HubStyle.medium); if let internet = contract.internet { Label(internet.message, systemImage: internet.online ? "wifi" : "wifi.slash").font(.subheadline).foregroundStyle(internet.online ? .green : HubStyle.orange) }; if contract.id != selectedId { Button("Selecionar contrato") { model.selectContract(contract.id) }.buttonStyle(PrimaryButton()).padding(.top, 4) } } } } }.padding(20) }.navigationTitle("Contratos").navigationBarTitleDisplayMode(.inline) }
}

struct AddOnsScreen: View {
    let summary: AddOnsSummary
    let contracts: [CustomerContract]
    let selectedId: String?
    @Bindable var model: HubModel
    private var included: [ContractService] { contracts.first(where: { $0.id == selectedId })?.services.filter { $0.category.lowercased() != "internet" } ?? [] }
    var body: some View { ScrollView { VStack(alignment: .leading, spacing: 18) { Text("Conecte+").font(.largeTitle.bold()); Text("Serviços incluídos e opções para deixar seu plano ainda melhor.").foregroundStyle(HubStyle.medium)
        if !included.isEmpty { Text("Incluídos no seu combo").font(.title3.bold()); ForEach(included) { service in HubCard { HStack(spacing: 14) { Image(systemName: "checkmark.seal.fill").font(.title2).foregroundStyle(.green); VStack(alignment: .leading, spacing: 4) { Text(service.name).font(.headline); Text(service.category).font(.caption).foregroundStyle(HubStyle.medium); Text("Incluído no seu combo").font(.caption.bold()).foregroundStyle(HubStyle.blue) } } } } }
        if !summary.requests.isEmpty { Text("Solicitados").font(.title3.bold()); ForEach(summary.requests) { request in HubCard { HStack { Image(systemName: "clock.badge.checkmark").foregroundStyle(HubStyle.orange); VStack(alignment: .leading) { Text(request.offerTitle).font(.headline); Text("Pedido \(request.status.lowercased()) · até 24 horas úteis").font(.caption).foregroundStyle(HubStyle.medium) } } } } }
        Text("Disponíveis para contratação").font(.title3.bold()); if summary.offers.isEmpty { EmptyCard(icon: "play.circle", text: "Não há serviços adicionais disponíveis para este contrato.") }
        ForEach(summary.offers) { offer in let requested = summary.requests.contains { $0.offerId == offer.id }; HubCard { VStack(alignment: .leading, spacing: 12) { HStack { Image(systemName: "play.circle.fill").font(.title).foregroundStyle(HubStyle.blue); VStack(alignment: .leading) { Text(offer.title).font(.title3.bold()); if let previous = offer.previousPrice { Text(currency(previous)).strikethrough().font(.caption).foregroundStyle(HubStyle.medium) } }; Spacer(); Text(currency(offer.price) + "/mês").font(.headline).foregroundStyle(HubStyle.orange) }; ForEach(offer.highlights, id: \.self) { Label($0, systemImage: "checkmark.circle.fill").font(.subheadline).foregroundStyle(HubStyle.medium) }; Button(requested ? "Pedido solicitado" : "Contratar") { if !requested { model.requestAddOn(offer.id) } }.buttonStyle(PrimaryButton()).disabled(requested || model.busy) } } }
    }.padding(20) }.navigationTitle("Conecte+").navigationBarTitleDisplayMode(.inline) }
}

struct SupportTicketsScreen: View { let tickets: [SupportTicket]; var body: some View { ScrollView { VStack(alignment: .leading, spacing: 16) { Text("Meus chamados").font(.largeTitle.bold()); if tickets.isEmpty { EmptyCard(icon: "headphones", text: "Você ainda não possui chamados.") }; ForEach(tickets) { ticket in HubCard { VStack(alignment: .leading, spacing: 6) { HStack { Text(ticket.open ? "Em andamento" : "Encerrado").font(.caption.bold()).foregroundStyle(ticket.open ? HubStyle.orange : .green); Spacer(); Text(ticket.protocolNumber ?? ticket.id).font(.caption).foregroundStyle(HubStyle.medium) }; Text(ticket.description).font(.headline); Text(dateLabel(ticket.createdAt)).font(.caption).foregroundStyle(HubStyle.medium) } } } }.padding(20) }.navigationTitle("Chamados").navigationBarTitleDisplayMode(.inline) } }

struct SupportHomeScreen: View {
    let tickets: [SupportTicket]
    @Bindable var model: HubModel
    @State private var formOpen = false
    @State private var kind = "Suporte técnico"
    @State private var description = ""
    var body: some View { ScrollView { VStack(alignment: .leading, spacing: 18) {
        ZStack(alignment: .bottomTrailing) { LinearGradient(colors: [HubStyle.dark, HubStyle.blue], startPoint: .topLeading, endPoint: .bottomTrailing); Image(systemName: "headphones").font(.system(size: 90)).foregroundStyle(.white.opacity(0.16)).padding(20); VStack(alignment: .leading, spacing: 8) { Text("SUPORTE CONECTE").font(.caption.bold()).foregroundStyle(HubStyle.orange); Text("Como podemos ajudar?").font(.title.bold()).foregroundStyle(.white); Text("Acompanhe solicitações e conte com nosso time.").foregroundStyle(.white.opacity(0.82)) }.frame(maxWidth: .infinity, alignment: .leading).padding(22) }.frame(height: 190).clipShape(RoundedRectangle(cornerRadius: 24))
        NavigationLink(value: "support-tickets") { HubCard { HStack(spacing: 16) { Image(systemName: "ticket").font(.title2).foregroundStyle(HubStyle.blue).frame(width: 58, height: 58).background(HubStyle.blue.opacity(0.12), in: RoundedRectangle(cornerRadius: 18)); VStack(alignment: .leading, spacing: 5) { Text("Meus chamados").font(.title3.bold()); Text(tickets.isEmpty ? "Nenhum chamado em aberto" : "\(tickets.filter(\.open).count) chamado(s) em andamento").font(.subheadline).foregroundStyle(HubStyle.medium) }; Spacer(); Image(systemName: "chevron.right").foregroundStyle(HubStyle.orange) } } }.buttonStyle(.plain)
        Button("Abrir chamado") { formOpen = true }.buttonStyle(PrimaryButton())
        HubCard { VStack(alignment: .leading, spacing: 8) { Label("Conexão lenta ou sem conexão", systemImage: "wifi.exclamationmark").font(.headline); Text("Verifique cabos, desligue e ligue o roteador e aguarde dois minutos. Se persistir, fale conosco pelo atendimento.").foregroundStyle(HubStyle.medium) } }
    }.padding(20) }.navigationTitle("Suporte").navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $formOpen) { NavigationStack { Form { Picker("Assunto", selection: $kind) { Text("Suporte técnico").tag("Suporte técnico"); Text("Financeiro").tag("Financeiro"); Text("Outros").tag("Outros") }; Section("Descreva sua solicitação") { TextEditor(text: $description).frame(minHeight: 130) } } .navigationTitle("Novo chamado").toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { formOpen = false } }; ToolbarItem(placement: .confirmationAction) { Button("Enviar") { model.openSupportTicket(kind: kind, description: description); formOpen = false; description = "" }.disabled(description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || model.busy) } } } }
        .alert("Solicitação enviada", isPresented: Binding(get: { model.confirmation != nil }, set: { if !$0 { model.confirmation = nil } })) { Button("Entendi") { model.confirmation = nil } } message: { Text(model.confirmation ?? "") }
    }
}

struct NotificationsScreen: View { let notifications: [AppNotification]; var body: some View { ScrollView { VStack(alignment: .leading, spacing: 16) { Text("Avisos e campanhas").font(.largeTitle.bold()); if notifications.isEmpty { EmptyCard(icon: "bell", text: "Não há novos avisos para você.") }; ForEach(notifications) { notice in HubCard { VStack(alignment: .leading, spacing: 6) { Text(notice.title).font(.headline); Text(notice.body).foregroundStyle(HubStyle.medium); Text(dateLabel(notice.sentAt)).font(.caption).foregroundStyle(HubStyle.medium) } } } }.padding(20) }.navigationTitle("Avisos").navigationBarTitleDisplayMode(.inline) } }

struct SpeedTestScreen: View {
    private let url = URL(string: "https://www.minhaconexao.com.br/widgets/speedometer/uol")!
    var body: some View { VStack(spacing: 0) { HStack(spacing: 12) { Image(systemName: "gauge").foregroundStyle(HubStyle.blue).font(.title2).frame(width: 48, height: 48).background(HubStyle.blue.opacity(0.12), in: RoundedRectangle(cornerRadius: 14)); VStack(alignment: .leading) { Text("Teste de velocidade").font(.title3.bold()); Text("Minha Conexão").font(.subheadline).foregroundStyle(HubStyle.medium) }; Spacer(); Link(destination: url) { Image(systemName: "arrow.up.right.square").foregroundStyle(HubStyle.blue) } }.padding(18); WebView(url: url) }.navigationTitle("Teste de velocidade").navigationBarTitleDisplayMode(.inline) }
}

private struct WebView: UIViewRepresentable { let url: URL; func makeUIView(context: Context) -> WKWebView { WKWebView() }; func updateUIView(_ view: WKWebView, context: Context) { if view.url != url { view.load(URLRequest(url: url)) } } }
private struct EmptyCard: View { let icon: String; let text: String; var body: some View { VStack(spacing: 12) { Image(systemName: icon).font(.largeTitle).foregroundStyle(HubStyle.medium); Text(text).multilineTextAlignment(.center).foregroundStyle(HubStyle.medium) }.frame(maxWidth: .infinity).padding(30).background(.white, in: RoundedRectangle(cornerRadius: 22)) } }
private func currency(_ value: Double) -> String { value.formatted(.currency(code: "BRL").locale(Locale(identifier: "pt_BR"))) }
private func bytesLabel(_ bytes: Double) -> String { let units = ["KB", "MB", "GB", "TB"]; var value = max(bytes / 1024, 0); var index = 0; while value >= 1024, index < units.count - 1 { value /= 1024; index += 1 }; return String(format: "%.2f %@", value, units[index]) }
private func dateLabel(_ value: String) -> String { String(value.prefix(10).replacingOccurrences(of: "-", with: "/")) }
private func periodLabel(_ value: String?) -> String { guard let value, value.count >= 7 else { return "Período atual" }; let names = ["Janeiro", "Fevereiro", "Março", "Abril", "Maio", "Junho", "Julho", "Agosto", "Setembro", "Outubro", "Novembro", "Dezembro"]; let month = Int(value.dropFirst(5).prefix(2)).flatMap { $0 > 0 && $0 <= 12 ? names[$0 - 1] : nil } ?? "Período"; return "\(month) de \(value.prefix(4))" }
private struct MonthChoice: Identifiable { let value: String; let label: String; var id: String { value } }
private func recentMonths() -> [MonthChoice] { let calendar = Calendar(identifier: .gregorian); return (0..<24).compactMap { offset in guard let date = calendar.date(byAdding: .month, value: -offset, to: Date()) else { return nil }; let value = date.formatted(.dateTime.year().month(.twoDigits)); return MonthChoice(value: value, label: periodLabel(value)) } }
