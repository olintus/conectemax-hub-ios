import SwiftUI
import MapKit
import AVKit

struct CityScreen: View {
    let weather: WeatherReading?
    let camera: WeatherCamera?
    var body: some View {
        ScrollView { VStack(alignment: .leading, spacing: 18) {
            ZStack(alignment: .leading) { LinearGradient(colors: [HubStyle.dark, HubStyle.blue], startPoint: .leading, endPoint: .trailing); HStack(spacing: 14) { Image(systemName: "cloud.sun.fill").font(.title).foregroundStyle(.white).frame(width: 54, height: 54).background(.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 16)); VStack(alignment: .leading) { Text("Clima em \(weather?.location ?? "Poço Fundo")").font(.title3.bold()).foregroundStyle(.white); Text("Dados ao vivo da estação local").font(.subheadline).foregroundStyle(.white.opacity(0.80)) } }.padding(20) }.frame(height: 96)
            if let weather { WeatherSummaryCard(weather: weather) } else { EmptyCard(icon: "cloud", text: "Dados da estação indisponíveis no momento.") }
            NavigationLink(value: "weather-details") { CityCard(icon: "thermometer.medium", title: "Clima e estação", subtitle: "Veja todos os dados e a webcam da estação") }.buttonStyle(.plain)
            NavigationLink(value: "wifi-outdoor") { CityCard(icon: "wifi", title: "Wi‑Fi Fora de Casa", subtitle: "Pontos Conecte Wi‑Fi perto de você") }.buttonStyle(.plain)
        }.padding(20) }.navigationTitle("Cidade").navigationBarTitleDisplayMode(.inline)
    }
}

struct WeatherSummaryCard: View {
    let weather: WeatherReading
    var body: some View { HubCard { HStack { VStack(alignment: .leading, spacing: 7) { Text("Agora").font(.caption.bold()).foregroundStyle(HubStyle.medium); Text(weather.temperature.map { metric($0, "°C") } ?? "—").font(.system(size: 40, weight: .bold)).foregroundStyle(HubStyle.ink); Text("Sensação: \(weather.feelsLike.map { metric($0, "°C") } ?? "—")").foregroundStyle(HubStyle.medium) }; Spacer(); VStack(alignment: .leading, spacing: 9) { Label("Umidade \(weather.humidity.map { metric($0, "%") } ?? "—")", systemImage: "humidity"); Label("Vento \(weather.windSpeed.map { metric($0, " km/h") } ?? "—")", systemImage: "wind"); Label("UV \(weather.uv.map { metric($0, "") } ?? "—")", systemImage: "sun.max") }.font(.subheadline).foregroundStyle(HubStyle.medium) } } }
}

struct WeatherDetailsScreen: View {
    let weather: WeatherReading?
    let camera: WeatherCamera?
    var body: some View { ScrollView { VStack(alignment: .leading, spacing: 16) { Text("Clima Poço Fundo").font(.largeTitle.bold()); if let weather { LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) { MetricCard(title: "Temperatura", value: weather.temperature.map { metric($0, "°C") } ?? "—", icon: "thermometer.medium"); MetricCard(title: "Umidade", value: weather.humidity.map { metric($0, "%") } ?? "—", icon: "humidity"); MetricCard(title: "Pressão", value: weather.pressure.map { metric($0, " hPa") } ?? "—", icon: "gauge"); MetricCard(title: "Vento", value: weather.windSpeed.map { metric($0, " km/h") } ?? "—", icon: "wind"); MetricCard(title: "Chuva", value: weather.rainTotal.map { metric($0, " mm") } ?? "—", icon: "cloud.rain"); MetricCard(title: "Radiação", value: weather.radiation.map { metric($0, " W/m²") } ?? "—", icon: "sun.max") } } else { EmptyCard(icon: "cloud", text: "Dados da estação indisponíveis no momento.") }; if let camera, let url = URL(string: camera.hlsURL) { VStack(alignment: .leading, spacing: 10) { HStack { Text(camera.title).font(.title3.bold()); Spacer(); Label("AO VIVO", systemImage: "dot.radiowaves.left.and.right").font(.caption.bold()).foregroundStyle(.green) }; LiveCameraPlayer(url: url).frame(height: 220).clipShape(RoundedRectangle(cornerRadius: 20)) } } }.padding(20) }.navigationTitle("Estação").navigationBarTitleDisplayMode(.inline) }
}

private struct LiveCameraPlayer: UIViewControllerRepresentable {
    let url: URL

    func makeCoordinator() -> Coordinator {
        Coordinator(url: url)
    }

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = context.coordinator.player
        controller.showsPlaybackControls = false
        controller.videoGravity = .resizeAspectFill
        context.coordinator.start()
        return controller
    }

    func updateUIViewController(_ controller: AVPlayerViewController, context: Context) {
        context.coordinator.update(url: url)
    }

    static func dismantleUIViewController(_ uiViewController: AVPlayerViewController, coordinator: Coordinator) {
        coordinator.stop()
    }

    final class Coordinator: NSObject {
        let player = AVPlayer()
        private var currentURL: URL
        private var statusObservation: NSKeyValueObservation?
        private var endObserver: NSObjectProtocol?

        init(url: URL) {
            currentURL = url
            super.init()
            player.actionAtItemEnd = .none
        }

        func start() {
            replaceStream(with: currentURL)
        }

        func update(url: URL) {
            guard url != currentURL else {
                player.play()
                return
            }
            currentURL = url
            replaceStream(with: url)
        }

        func stop() {
            player.pause()
            statusObservation?.invalidate()
            if let endObserver {
                NotificationCenter.default.removeObserver(endObserver)
            }
        }

        private func replaceStream(with url: URL) {
            statusObservation?.invalidate()
            if let endObserver {
                NotificationCenter.default.removeObserver(endObserver)
            }

            let item = AVPlayerItem(url: url)
            player.replaceCurrentItem(with: item)
            statusObservation = item.observe(\.status, options: [.new]) { [weak self] item, _ in
                guard item.status == .readyToPlay else { return }
                DispatchQueue.main.async {
                    self?.player.play()
                }
            }
            endObserver = NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: item, queue: .main) { [weak self] _ in
                self?.player.seek(to: .zero)
                self?.player.play()
            }
            player.play()
        }
    }
}

struct WifiOutsideScreen: View {
    @State private var position: MapCameraPosition = .region(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: -21.7807, longitude: -45.9665), span: MKCoordinateSpan(latitudeDelta: 0.025, longitudeDelta: 0.025)))
    var body: some View { ScrollView { VStack(alignment: .leading, spacing: 16) { Text("Wi‑Fi Fora de Casa").font(.largeTitle.bold()); Text("Pontos Conecte Wi‑Fi perto de você").foregroundStyle(HubStyle.medium); VStack(alignment: .leading, spacing: 12) { HStack { Label("Pontos no mapa", systemImage: "map").font(.headline); Spacer(); Text("• Você").foregroundStyle(HubStyle.blue) }; Map(position: $position) { ForEach(wifiPoints) { point in Annotation(point.name, coordinate: point.coordinate) { Circle().fill(HubStyle.orange).frame(width: 18, height: 18).overlay(Circle().stroke(.white, lineWidth: 3)) } } }.frame(height: 230).clipShape(RoundedRectangle(cornerRadius: 16)); Text("Marcadores laranja: pontos Wi‑Fi · Azul: sua localização").font(.caption).foregroundStyle(HubStyle.medium) }.padding(16).background(Color(red: 0.90, green: 0.95, blue: 0.91), in: RoundedRectangle(cornerRadius: 22)); Text("Distâncias estimadas a partir da sua localização").font(.headline).foregroundStyle(HubStyle.medium); ForEach(wifiPoints) { point in HubCard { HStack { Image(systemName: "wifi").foregroundStyle(HubStyle.orange).font(.title2).frame(width: 48, height: 48).background(HubStyle.orange.opacity(0.13), in: RoundedRectangle(cornerRadius: 14)); VStack(alignment: .leading) { Text(point.name).font(.headline); Text("Ponto Conecte Wi‑Fi").font(.caption).foregroundStyle(HubStyle.medium) }; Spacer(); Image(systemName: "chevron.right").foregroundStyle(HubStyle.medium) } } } }.padding(20) }.navigationTitle("Wi‑Fi").navigationBarTitleDisplayMode(.inline) }
}

private struct CityCard: View { let icon: String; let title: String; let subtitle: String; var body: some View { HubCard { HStack(spacing: 16) { Image(systemName: icon).font(.title2).foregroundStyle(HubStyle.blue).frame(width: 64, height: 64).background(HubStyle.blue.opacity(0.12), in: RoundedRectangle(cornerRadius: 18)); VStack(alignment: .leading, spacing: 5) { Text(title).font(.title3.bold()); Text(subtitle).font(.subheadline).foregroundStyle(HubStyle.medium) }; Spacer(); Image(systemName: "arrow.right").foregroundStyle(HubStyle.orange) } } } }
private struct MetricCard: View { let title: String; let value: String; let icon: String; var body: some View { VStack(alignment: .leading, spacing: 9) { Image(systemName: icon).foregroundStyle(HubStyle.blue); Text(title).font(.caption).foregroundStyle(HubStyle.medium); Text(value).font(.headline) }.frame(maxWidth: .infinity, alignment: .leading).padding(16).background(.white, in: RoundedRectangle(cornerRadius: 18)) } }
private struct WifiPoint: Identifiable { let name: String; let latitude: Double; let longitude: Double; var id: String { "\(name)-\(latitude)" }; var coordinate: CLLocationCoordinate2D { CLLocationCoordinate2D(latitude: latitude, longitude: longitude) } }
private let wifiPoints = [WifiPoint(name: "Matriz", latitude: -21.7806522, longitude: -45.9656696), WifiPoint(name: "Concha Acústica", latitude: -21.7795851, longitude: -45.9660796), WifiPoint(name: "Bar do Arnaldo", latitude: -21.7763828, longitude: -45.9677316), WifiPoint(name: "Bar do Zé Luiz", latitude: -21.7741765, longitude: -45.9673173), WifiPoint(name: "Bar do Tiãozinho", latitude: -21.7838489, longitude: -45.9688273), WifiPoint(name: "Pracinha da Prefeitura", latitude: -21.7859660, longitude: -45.9660985), WifiPoint(name: "Conecte", latitude: -21.7833431, longitude: -45.9662680), WifiPoint(name: "Praça São Benedito", latitude: -21.7802430, longitude: -45.9632306), WifiPoint(name: "Pracinha da Natus Farma", latitude: -21.7845504, longitude: -45.9665919), WifiPoint(name: "Alves Loja 1", latitude: -21.7824422, longitude: -45.9668738), WifiPoint(name: "Perpétuo Socorro", latitude: -21.7727144, longitude: -45.9668987), WifiPoint(name: "Ponto Conecte Wi‑Fi rural", latitude: -21.6644770, longitude: -45.9114364)]
private func metric(_ value: Double, _ suffix: String) -> String { String(format: value.rounded() == value ? "%.0f%@" : "%.1f%@", value, suffix) }
