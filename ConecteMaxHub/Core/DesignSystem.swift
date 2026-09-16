import SwiftUI

enum HubStyle {
    // Active palette from Site Conecte Max / app/globals.css.
    static let blue = Color(red: 6/255, green: 72/255, blue: 179/255)
    static let orange = Color(red: 255/255, green: 74/255, blue: 22/255)
    static let dark = Color(red: 7/255, green: 30/255, blue: 86/255)
    static let cyan = Color(red: 32/255, green: 167/255, blue: 229/255)
    static let paper = Color(red: 244/255, green: 247/255, blue: 251/255)
    static let ink = Color(red: 24/255, green: 33/255, blue: 66/255)
    static let gray = Color(red: 220/255, green: 230/255, blue: 242/255)
    static let medium = Color(red: 102/255, green: 114/255, blue: 138/255)
}
struct HubCard<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 12) { content }
            .frame(maxWidth: .infinity, alignment: .leading).padding(20)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(HubStyle.gray, lineWidth: 1))
    }
}
struct PrimaryButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.headline).frame(maxWidth: .infinity).padding(16)
            .foregroundStyle(Color.white).background(HubStyle.blue.opacity(configuration.isPressed ? 0.7 : 1), in: RoundedRectangle(cornerRadius: 16))
    }
}
extension View {
    func hubField() -> some View { padding(16).background(Color.white, in: RoundedRectangle(cornerRadius: 12)).overlay(RoundedRectangle(cornerRadius: 12).stroke(HubStyle.gray, lineWidth: 1)).textInputAutocapitalization(.never).autocorrectionDisabled() }
}
