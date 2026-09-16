import Foundation

struct Hub {
    let name: String
    let plan: String
    let status: String
    let notice: String
    let modules: [HubModule]
    let contracts: [CustomerContract]
    let selectedContractId: String?
    let billing: BillingSummary
    let traffic: TrafficSummary?
    let supportTickets: [SupportTicket]
    let notifications: [AppNotification]
    let addOns: AddOnsSummary
}

struct HubModule: Identifiable { let id: String; let title: String; let subtitle: String; let category: String; let icon: String; let items: [HubItem] }
struct HubItem: Identifiable { var id: String { title }; let title: String; let detail: String; let action: String }

struct CustomerContract: Identifiable {
    let id: String
    let status: String
    let statusLabel: String
    let city: String
    let address: String
    let internet: InternetStatus?
    let services: [ContractService]
}

struct InternetStatus { let online: Bool; let message: String }
struct ContractService: Identifiable { let id: String; let name: String; let category: String }

struct Invoice: Identifiable {
    let id: String
    let contractId: String
    let dueDate: String
    let paidAt: String?
    let amount: Double
    let status: String
    let barcode: String?
    let pix: String?
    let invoiceURL: String?
}

struct BillingSummary { let open: [Invoice]; let paid: [Invoice] }

struct TrafficSummary {
    let contractId: String
    let from: String
    let to: String
    let totalBytes: Double
    let days: [TrafficDay]
}

struct TrafficDay: Identifiable { let date: String; let bytes: Double; var id: String { date } }

struct SupportTicket: Identifiable {
    let id: String
    let protocolNumber: String?
    let description: String
    let reason: String?
    let plan: String?
    let observation: String?
    let status: String
    let createdAt: String
    let scheduledAt: String?
    let closedAt: String?
    let open: Bool
}

struct AppNotification: Identifiable { let id: String; let title: String; let body: String; let sentAt: String }

struct AddOnOffer: Identifiable {
    let id: String
    let title: String
    let price: Double
    let previousPrice: Double?
    let highlights: [String]
}

struct AddOnRequest: Identifiable {
    let id: String
    let contractId: String
    let offerId: String
    let offerTitle: String
    let amount: Double
    let status: String
    let createdAt: String
    let title: String
    let message: String
}

struct AddOnsSummary { let contractId: String?; let offers: [AddOnOffer]; let requests: [AddOnRequest] }

@MainActor protocol HubRepository {
    func load() async throws -> Hub
    func traffic(month: String) async throws -> TrafficSummary
    func selectContract(_ contractId: String) async throws
    func requestAddOn(_ offerId: String) async throws -> AddOnRequest
}
