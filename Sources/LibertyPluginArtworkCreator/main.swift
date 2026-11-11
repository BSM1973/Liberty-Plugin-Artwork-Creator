import SwiftUI
import AppKit
import ImageIO
import UniformTypeIdentifiers

@main
struct LibertyArtworkApp: App {
    var body: some Scene {
        WindowGroup("Liberty Plugin Artwork Creator") { ArtworkView() }
            .defaultSize(width: 920, height: 740)
    }
}

@MainActor
final class ArtworkModel: ObservableObject {
    @Published var original: NSImage?
    @Published var imageURL: URL?
    @Published var message = "Ouvrez un plugin, puis cliquez sur CAPTURER UNE FENÊTRE."
    @Published var busy = false
    @Published var left = 0.0
    @Published var top = 0.0
    @Published var right = 0.0
    @Published var bottom = 0.0

    func capture() {
        guard !busy else { return }
        busy = true
        message = "Sélectionnez la fenêtre du plugin dans l'outil macOS. Échap pour annuler."
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("liberty-capture-\(UUID().uuidString).png")
        DispatchQueue.global(qos: .userInitiated).async {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
            process.arguments = ["-i", "-W", "-x", url.path]
            var result = -1
            do { try process.run(); process.waitUntilExit(); result = Int(process.terminationStatus) }
            catch { result = -1 }
            let image = NSImage(contentsOf: url)
            DispatchQueue.main.async {
                self.busy = false
                if result == 0, let image = image, image.size.width >= 80, image.size.height >= 60 {
                    self.original = image
                    self.imageURL = nil
                    self.left = 0; self.top = 0; self.right = 0; self.bottom = 0
                    self.message = "Capture reçue. Ajustez le recadrage, puis exportez le PNG."
                } else {
                    self.message = "Capture annulée ou indisponible. Vérifiez l'autorisation Enregistrement de l'écran de macOS."
                }
            }
        }
    }

    private func croppedCGImage() -> CGImage? {
        guard let original = original, let tiff = original.tiffRepresentation,
              let source = CGImageSourceCreateWithData(tiff as CFData, nil),
              let cg = CGImageSourceCreateImageAtIndex(source, 0, nil) else { return nil }
        let x = Int(Double(cg.width) * left / 100)
        let y = Int(Double(cg.height) * top / 100)
        let w = cg.width - x - Int(Double(cg.width) * right / 100)
        let h = cg.height - y - Int(Double(cg.height) * bottom / 100)
        guard w >= 80, h >= 60 else { return nil }
        return cg.cropping(to: CGRect(x: x, y: y, width: w, height: h))
    }

    func export() {
        guard let cg = croppedCGImage() else { message = "Recadrage trop important ou image invalide."; return }
        let panel = NSSavePanel()
        panel.title = "Exporter la miniature Liberty"
        panel.nameFieldStringValue = "Liberty-Plugin-Artwork.png"
        panel.allowedContentTypes = [.png]
        panel.canCreateDirectories = true
        guard panel.runModal() == .OK, let url = panel.url else { return }
        guard let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
            message = "Impossible de créer le PNG."; return
        }
        CGImageDestinationAddImage(dest, cg, nil)
        if CGImageDestinationFinalize(dest) {
            imageURL = url
            message = "PNG enregistré. Glissez le fichier depuis le Finder ou le bouton ci-dessous."
        } else { message = "Échec de l'enregistrement PNG." }
    }
}

struct ArtworkView: View {
    @StateObject private var model = ArtworkModel()
    private let bg = Color(red: 0.055, green: 0.095, blue: 0.15)
    private let panel = Color(red: 0.10, green: 0.16, blue: 0.23)
    private let accent = Color(red: 0.30, green: 0.81, blue: 0.85)

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("LIBERTY  /  PLUGIN ARTWORK CREATOR").font(.system(size: 22, weight: .bold, design: .rounded)).foregroundStyle(.white)
                    Text("Capturez les véritables interfaces de vos plugins AU et VST3").foregroundStyle(.gray)
                }
                Spacer()
                Button("CAPTURER UNE FENÊTRE") { model.capture() }.disabled(model.busy).buttonStyle(.borderedProminent).tint(accent)
            }
            ZStack {
                RoundedRectangle(cornerRadius: 12).fill(panel)
                if let image = model.original {
                    GeometryReader { geometry in
                        let iw = image.size.width
                        let ih = image.size.height
                        let scale = min(geometry.size.width / iw, geometry.size.height / ih)
                        let dw = iw * scale
                        let dh = ih * scale
                        let ox = (geometry.size.width - dw) / 2
                        let oy = (geometry.size.height - dh) / 2
                        Image(nsImage: image).resizable().interpolation(.high).scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        Rectangle().stroke(accent, lineWidth: 2)
                            .frame(width: max(0, dw * (1 - (model.left + model.right) / 100)), height: max(0, dh * (1 - (model.top + model.bottom) / 100)))
                            .position(x: ox + dw * (model.left / 100) + dw * (1 - (model.left + model.right) / 100) / 2,
                                      y: oy + dh * (model.top / 100) + dh * (1 - (model.top + model.bottom) / 100) / 2)
                    }.padding(12)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "camera.viewfinder").font(.system(size: 56)).foregroundStyle(accent)
                        Text("Aucune capture").foregroundStyle(.white)
                        Text("Ouvrez Analog Lab V ou un autre plugin avant la capture.").foregroundStyle(.gray)
                    }
                }
            }.frame(minHeight: 340)
            if model.original != nil {
                VStack(alignment: .leading, spacing: 8) {
                    Text("RECADRAGE (% de chaque bord)").font(.caption.bold()).foregroundStyle(accent)
                    HStack(spacing: 18) {
                        cropControl("Gauche", value: $model.left, limit: 100 - model.right - 10)
                        cropControl("Droite", value: $model.right, limit: 100 - model.left - 10)
                    }
                    HStack(spacing: 18) {
                        cropControl("Haut", value: $model.top, limit: 100 - model.bottom - 10)
                        cropControl("Bas", value: $model.bottom, limit: 100 - model.top - 10)
                    }
                }.padding(12).background(panel, in: RoundedRectangle(cornerRadius: 10))
            }
            HStack(spacing: 16) {
                Button("EXPORTER PNG") { model.export() }.disabled(model.original == nil).buttonStyle(.borderedProminent).tint(accent)
                if let url = model.imageURL {
                    Text("GLISSER LE PNG").foregroundStyle(accent).font(.caption.bold())
                        .padding(9).background(panel, in: RoundedRectangle(cornerRadius: 6))
                        .onDrag { NSItemProvider(object: url as NSURL) }
                    Button("AFFICHER DANS LE FINDER") { NSWorkspace.shared.activateFileViewerSelecting([url]) }
                }
                Spacer()
            }
            Text(model.message).font(.callout).foregroundStyle(.white.opacity(0.85)).lineLimit(2)
            Text("Importez le PNG dans Liberty DAW via MINIATURES > IMPORTER PNG. Le dépôt Liberty DAW reste inchangé.")
                .font(.caption).foregroundStyle(.gray)
        }
        .padding(22).background(bg)
        .preferredColorScheme(.dark)
    }

    private func cropControl(_ label: String, value: Binding<Double>, limit: Double) -> some View {
        HStack {
            Text(label).frame(width: 52, alignment: .leading)
            Slider(value: value, in: 0...max(0, min(85, limit)), step: 1)
            Text("\(Int(value.wrappedValue)) %").monospacedDigit().frame(width: 40)
        }.font(.caption).foregroundStyle(.white)
    }
}
