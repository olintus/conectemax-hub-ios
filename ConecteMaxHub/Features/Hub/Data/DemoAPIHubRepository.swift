import Foundation

private struct CatalogDTO: Decodable { let name: String; let plan: String; let status: String; let notice: String; let modules: [ModuleDTO] }
private struct ModuleDTO: Decodable {
    let id: String; let title: String; let subtitle: String; let category: String; let icon: String; let items: [ItemDTO]
    var domain: HubModule { HubModule(id: id, title: title, subtitle: subtitle, category: category, icon: icon, items: items.map(\.domain)) }
}
private struct ItemDTO: Decodable { let title: String; let detail: String; let action: String; var domain: HubItem { HubItem(title: title, detail: detail, action: action) } }

private struct MeDTO: Decodable { let name: String; let selectedContractId: String?; let contracts: [ContractDTO] }
private struct ContractDTO: Decodable {
    let id: String; let status: Int; let statusLabel: String; let city: String; let address: String; let internet: InternetDTO?; let services: [ServiceDTO]
    var domain: CustomerContract { CustomerContract(id: id, status: String(status), statusLabel: statusLabel, city: city, address: address, internet: internet?.domain, services: services.map(\.domain)) }
}
private struct InternetDTO: Decodable { let online: Bool; let message: String; var domain: InternetStatus { InternetStatus(online: online, message: message) } }
private struct ServiceDTO: Decodable { let id: String; let type: String; let plan: String; let status: String; var domain: ContractService { ContractService(id: id, name: plan, category: type) } }

private struct BillingDTO: Decodable { let open: [InvoiceDTO]; let paid: [InvoiceDTO]; var domain: BillingSummary { BillingSummary(open: open.map(\.domain), paid: paid.map(\.domain)) } }
private struct InvoiceDTO: Decodable {
    let id: String; let contractId: String; let dueDate: String; let paidAt: String?; let amount: Double; let status: String; let barcode: String?; let pix: String?; let invoiceUrl: String?
    var domain: Invoice { Invoice(id: id, contractId: contractId, dueDate: dueDate, paidAt: paidAt, amount: amount, status: status, barcode: barcode, pix: pix, invoiceURL: invoiceUrl) }
}

private struct TrafficDTO: Decodable {
    let contractId: String; let from: String; let to: String; let totalBytes: Double; let days: [TrafficDayDTO]
    var domain: TrafficSummary { TrafficSummary(contractId: contractId, from: from, to: to, totalBytes: totalBytes, days: days.map(\.domain)) }
}
private struct TrafficDayDTO: Decodable { let date: String; let bytes: Double; var domain: TrafficDay { TrafficDay(date: date, bytes: bytes) } }

private struct TicketsDTO: Decodable { let tickets: [TicketDTO] }
private struct TicketDTO: Decodable {
    let id: String; let `protocol`: String?; let description: String; let reason: String?; let plan: String?; let observation: String?; let status: String; let createdAt: String; let scheduledAt: String?; let closedAt: String?; let open: Bool
    var domain: SupportTicket { SupportTicket(id: id, protocolNumber: `protocol`, description: description, reason: reason, plan: plan, observation: observation, status: status, createdAt: createdAt, scheduledAt: scheduledAt, closedAt: closedAt, open: open) }
}

private struct NotificationsDTO: Decodable { let notifications: [NotificationDTO] }
private struct NotificationDTO: Decodable { let id: String; let title: String; let body: String; let sentAt: Double; var domain: AppNotification { AppNotification(id: id, title: title, body: body, sentAt: Date(timeIntervalSince1970: sentAt / (sentAt > 10_000_000_000 ? 1_000 : 1)).ISO8601Format()) } }

private struct AddOnsDTO: Decodable { let contractId: String?; let offers: [OfferDTO]; let requests: [AddOnRequestDTO]; var domain: AddOnsSummary { AddOnsSummary(contractId: contractId, offers: offers.map(\.domain), requests: requests.map(\.domain)) } }
private struct OfferDTO: Decodable { let id: String; let title: String; let price: Double; let previousPrice: Double?; let highlights: [String]; var domain: AddOnOffer { AddOnOffer(id: id, title: title, price: price, previousPrice: previousPrice, highlights: highlights) } }
private struct AddOnRequestDTO: Decodable {
    let id: String; let contractId: String; let offerId: String; let offerTitle: String; let amount: Double; let status: String; let createdAt: Double; let title: String; let message: String
    var domain: AddOnRequest { AddOnRequest(id: id, contractId: contractId, offerId: offerId, offerTitle: offerTitle, amount: amount, status: status, createdAt: Date(timeIntervalSince1970: createdAt / (createdAt > 10_000_000_000 ? 1_000 : 1)).ISO8601Format(), title: title, message: message) }
}
private struct WeatherDTO: Decodable {
    let locationName: String; let observedAt: String; let temperatureC: Double?; let humidityPercent: Double?; let pressureHpa: Double?; let feelsLikeC: Double?; let windSpeedKmh: Double?; let windGustKmh: Double?; let windDirectionCardinal: String?; let precipitationRateMmH: Double?; let precipitationTotalMm: Double?; let uvIndex: Double?; let solarRadiationWm2: Double?
    var domain: WeatherReading { WeatherReading(location: locationName, observedAt: observedAt, temperature: temperatureC, humidity: humidityPercent, pressure: pressureHpa, feelsLike: feelsLikeC, windSpeed: windSpeedKmh, windGust: windGustKmh, windDirection: windDirectionCardinal, rainRate: precipitationRateMmH, rainTotal: precipitationTotalMm, uv: uvIndex, radiation: solarRadiationWm2) }
}
private struct CameraDTO: Decodable { let title: String; let hlsUrl: String; var domain: WeatherCamera { WeatherCamera(title: title, hlsURL: hlsUrl) } }
private struct AddOnRequestPayload: Encodable { let offerId: String; let confirmed: Bool }
private struct SupportTicketPayload: Encodable { let kind: String; let description: String }
private struct OfflineSupportDTO: Decodable { let message: String }

@MainActor final class DemoAPIHubRepository: HubRepository {
    let auth: DemoAPIAuthRepository
    init(auth: DemoAPIAuthRepository) { self.auth = auth }

    func load() async throws -> Hub {
        async let catalogRequest: CatalogDTO = auth.authorized("hub")
        async let meRequest: MeDTO = auth.authorized("me")
        async let billingRequest: BillingDTO = auth.authorized("billing")
        let (catalog, me, billing) = try await (catalogRequest, meRequest, billingRequest)

        let selectedId = me.selectedContractId ?? me.contracts.first?.id
        async let trafficRequest: TrafficDTO? = optional("traffic")
        async let ticketsRequest: TicketsDTO? = optional("support/tickets")
        async let notificationsRequest: NotificationsDTO? = optional("notifications")
        async let addOnsRequest: AddOnsDTO? = optional("addons")
        async let weatherRequest: WeatherDTO? = optional("weather/current")
        async let cameraRequest: CameraDTO? = optional("camera/patio")
        let (traffic, tickets, notifications, addOns, weather, camera) = await (trafficRequest, ticketsRequest, notificationsRequest, addOnsRequest, weatherRequest, cameraRequest)

        let selectedBilling = BillingSummary(
            open: billing.open
                .filter { selectedId == nil || $0.contractId == selectedId }
                .map(\.domain),
            paid: billing.paid
                .filter { selectedId == nil || $0.contractId == selectedId }
                .map(\.domain)
        )

        return Hub(
            name: me.name.isEmpty ? catalog.name : me.name,
            plan: catalog.plan,
            status: catalog.status,
            notice: catalog.notice,
            modules: catalog.modules.map(\.domain),
            contracts: me.contracts.map(\.domain),
            selectedContractId: selectedId,
            billing: selectedBilling,
            traffic: traffic?.domain,
            supportTickets: tickets?.tickets.map(\.domain) ?? [],
            notifications: notifications?.notifications.map(\.domain) ?? [],
            addOns: addOns?.domain ?? AddOnsSummary(contractId: selectedId, offers: [], requests: []),
            weather: weather?.domain,
            weatherCamera: camera?.domain
        )
    }

    func traffic(month: String) async throws -> TrafficSummary {
        let response: TrafficDTO = try await auth.authorized("traffic?month=\(month)")
        return response.domain
    }

    func selectContract(_ contractId: String) async throws {
        // The endpoint returns a contract map (not necessarily a `message` field).
        // Decode it as a generic string map, as the Android client does.
        let _: [String: String] = try await auth.authorized("contracts/select", body: ["contractId": contractId])
    }

    func requestAddOn(_ offerId: String) async throws -> AddOnRequest {
        let response: AddOnRequestDTO = try await auth.authorized("addons/request", body: AddOnRequestPayload(offerId: offerId, confirmed: true))
        return response.domain
    }

    func openSupportTicket(kind: String, description: String) async throws -> String {
        let response: OfflineSupportDTO = try await auth.authorized("support/tickets/open", body: SupportTicketPayload(kind: kind, description: description))
        return response.message
    }

    private func optional<T: Decodable>(_ path: String) async -> T? { try? await auth.authorized(path) }
}
