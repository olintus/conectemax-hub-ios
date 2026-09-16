import XCTest
@testable import ConecteMaxHub

@MainActor final class SessionTests: XCTestCase {
    func testMissingSessionDoesNotMakeNetworkRequest() async throws {
        let store = MemoryStore()
        let auth = DemoAPIAuthRepository(api: APIClient(baseURL: URL(string: "https://unused.invalid")!), store: store)
        let restored = try await auth.restore()
        XCTAssertFalse(restored)
    }
    func testHubContractDecodesToDomain() throws {
        let data = Data(#"{"name":"Test","plan":"Fibra","status":"Online","notice":"Demo","modules":[{"id":"wifi","title":"Wi-Fi","subtitle":"Pontos","category":"city","icon":"wifi","items":[{"title":"Praça","detail":"Demo","action":"Ver"}]}]}"#.utf8)
        let hub = try JSONDecoder().decode(HubDTO.self, from: data).domain
        XCTAssertEqual(hub.modules.first?.items.first?.title, "Praça")
    }
}
private final class MemoryStore: SessionStore {
    var token: String?
    func read() throws -> String? { token }
    func write(_ token: String) throws { self.token = token }
    func clear() throws { token = nil }
}
