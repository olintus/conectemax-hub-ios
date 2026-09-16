import SwiftUI

struct AuthScreen: View {
    @Bindable var model: HubModel
    @State private var cpf = "", password = "", confirmation = "", code = ""
    private var title: String {
        switch model.stage {
        case "password": "Bem-vindo de volta"
        case "otp": "Confirme sua identidade"
        case "enroll": "Crie sua senha"
        case "restore": "Restaurando sua sessão"
        default: "Vamos começar pelo seu CPF"
        }
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text("CONECTE MAX").font(.caption.weight(.bold)).foregroundStyle(HubStyle.blue).padding(.top, 32)
                Text("Seu mundo.\nMais conectado.").font(.largeTitle.bold())
                Text("Conecte Max Hub").font(.title2)
                Text(title).font(.title2.bold()).padding(.top, 16)
                Group {
                    switch model.stage {
                    case "cpf":
                        TextField("CPF", text: $cpf).keyboardType(.numberPad).hubField()
                            .onChange(of: cpf) { _, new in cpf = String(new.filter(\.isNumber).prefix(11)) }
                        Button("Continuar") { model.start(cpf) }.buttonStyle(PrimaryButton()).disabled(cpf.count != 11)
                    case "password":
                        SecureField("Senha", text: $password).textContentType(.password).hubField()
                        Button("Entrar") { model.login(password); password = "" }.buttonStyle(PrimaryButton()).disabled(password.isEmpty)
                    case "otp":
                        Text(model.channel ?? "")
                        TextField("Código de verificação", text: $code).keyboardType(.numberPad).textContentType(.oneTimeCode).hubField()
                            .onChange(of: code) { _, new in code = String(new.filter(\.isNumber).prefix(6)) }
                        Button("Confirmar código") { model.verify(code); code = "" }.buttonStyle(PrimaryButton()).disabled(code.count != 6)
                        Text("Código expirado? Volte ao início para solicitar outro.").font(.caption)
                    case "enroll":
                        Text("Escolha a senha que preferir.").font(.subheadline)
                        SecureField("Nova senha", text: $password).textContentType(.newPassword).hubField()
                        SecureField("Confirme a senha", text: $confirmation).textContentType(.newPassword).hubField()
                        Button("Criar senha e entrar") { model.enroll(password, confirmation); password = ""; confirmation = "" }
                            .buttonStyle(PrimaryButton()).disabled(password.isEmpty || password.count > 128 || password != confirmation)
                    default:
                        if !model.busy { Button("Tentar novamente", action: model.restore).buttonStyle(PrimaryButton()) }
                    }
                }.disabled(model.busy)
                if model.busy { ProgressView().frame(maxWidth: .infinity).accessibilityLabel("Carregando") }
                if let error = model.error { Text(error).foregroundStyle(.red).accessibilityAddTraits(.updatesFrequently) }
                if !["cpf", "restore"].contains(model.stage) { Button("Voltar ao início", action: model.restart).disabled(model.busy) }
            }.padding(28)
        }.background(HubStyle.paper).onChange(of: model.stage) { _, _ in password = ""; confirmation = ""; code = "" }
    }
}
