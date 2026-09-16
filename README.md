# iOS nativo

SwiftUI, Observation, NavigationStack, URLSession e Codable. iOS mínimo 17. Não compartilha código com Android. O app usa a API de homologação em `https://api-homolog.conectemax.com.br/`.

Em um Mac com Xcode 16+ e XcodeGen:

```
xcodegen generate
open ConecteMaxHub.xcodeproj
xcodebuild -project ConecteMaxHub.xcodeproj -scheme ConecteMaxHub -destination 'platform=iOS Simulator,name=iPhone 16' test
```

Escolha um Simulator disponível no Mac caso o iPhone 16 não esteja instalado. Configure assinatura e bundle identifier antes de instalar em dispositivo físico.

`App` faz a composição de dependências. `Core` contém tema, URLSession e Keychain. `Features/Auth` e `Features/Hub` separam Domain, Data e Presentation. Access token fica somente em memória; refresh token usa Keychain com `WhenUnlockedThisDeviceOnly`.

APNs requer entitlement, provisioning, consentimento e endpoint de registro de dispositivo em etapa posterior. O protocolo `LocalSessionGate` reserva Face ID/Touch ID para desbloqueio local de sessão.

A geração do projeto e testes Swift exigem macOS; não foram executados no ambiente Windows desta entrega.
