import Foundation

struct HubDTO: Decodable {
    let name: String; let plan: String; let status: String; let notice: String; let modules: [ModuleDTO]
    var domain: Hub { Hub(name: name, plan: plan, status: status, notice: notice, modules: modules.map(\.domain)) }
}
struct ModuleDTO: Decodable {
    let id: String; let title: String; let subtitle: String; let category: String; let icon: String; let items: [ItemDTO]
    var domain: HubModule { HubModule(id: id, title: title, subtitle: subtitle, category: category, icon: icon, items: items.map { HubItem(title: $0.title, detail: $0.detail, action: $0.action) }) }
}
struct ItemDTO: Decodable { let title: String; let detail: String; let action: String }
@MainActor final class DemoAPIHubRepository: HubRepository {
    let auth: DemoAPIAuthRepository
    init(auth: DemoAPIAuthRepository) { self.auth = auth }
    func load() async throws -> Hub { let dto: HubDTO = try await auth.authorized("hub"); return dto.domain }
}
