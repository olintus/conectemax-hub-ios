import Foundation

struct Hub { let name: String; let plan: String; let status: String; let notice: String; let modules: [HubModule] }
struct HubModule: Identifiable { let id: String; let title: String; let subtitle: String; let category: String; let icon: String; let items: [HubItem] }
struct HubItem: Identifiable { var id: String { title }; let title: String; let detail: String; let action: String }
@MainActor protocol HubRepository { func load() async throws -> Hub }
