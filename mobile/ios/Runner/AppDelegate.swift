import AVFoundation
import CoreImage
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "AtlasVideo") {
      let channel = FlutterMethodChannel(name: "atlas/video", binaryMessenger: registrar.messenger())
      channel.setMethodCallHandler(VideoTools.handle)
    }
  }
}

/// Herramientas de video para la app (canal "atlas/video"):
/// - duracion(path) -> segundos
/// - comprimir(path, salida) -> salida, en MP4 a 720p con sonido
/// - miniatura(path, salida) -> salida, JPG del primer cuadro
/// - marcarFoto(path, salida, logo) -> salida, JPG con la marca de agua
/// Con `logo` en comprimir, el video sale con la marca de agua grabada.
/// Siempre responde (con resultado o con error), para que la app no quede esperando.
enum VideoTools {
  static func handle(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any], let path = args["path"] as? String else {
      return result(FlutterError(code: "args", message: "Falta path", details: nil))
    }
    let asset = AVURLAsset(url: URL(fileURLWithPath: path))
    switch call.method {
    case "duracion":
      result(CMTimeGetSeconds(asset.duration))
    case "comprimir":
      guard let salida = args["salida"] as? String else { return result(FlutterError(code: "args", message: "Falta salida", details: nil)) }
      let logo = (args["logo"] as? String).flatMap { UIImage(contentsOfFile: $0) }
      comprimir(asset, URL(fileURLWithPath: salida), logo, result)
    case "marcarFoto":
      guard let salida = args["salida"] as? String, let logoPath = args["logo"] as? String,
            let logo = UIImage(contentsOfFile: logoPath), let foto = UIImage(contentsOfFile: path)
      else { return result(FlutterError(code: "args", message: "Faltan datos o imágenes", details: nil)) }
      DispatchQueue.global(qos: .userInitiated).async {
        let marcada = Marca.dibujar(sobre: foto, tamano: foto.size, logo: logo)
        do {
          guard let data = marcada.jpegData(compressionQuality: 0.8) else { throw NSError(domain: "jpg", code: 0) }
          try data.write(to: URL(fileURLWithPath: salida))
          DispatchQueue.main.async { result(salida) }
        } catch {
          DispatchQueue.main.async { result(FlutterError(code: "marcarFoto", message: error.localizedDescription, details: nil)) }
        }
      }
    case "miniatura":
      guard let salida = args["salida"] as? String else { return result(FlutterError(code: "args", message: "Falta salida", details: nil)) }
      DispatchQueue.global(qos: .userInitiated).async {
        let gen = AVAssetImageGenerator(asset: asset)
        gen.appliesPreferredTrackTransform = true
        gen.maximumSize = CGSize(width: 1280, height: 1280)
        do {
          let t = CMTime(seconds: min(0.5, CMTimeGetSeconds(asset.duration) / 2), preferredTimescale: 600)
          let img = try gen.copyCGImage(at: t, actualTime: nil)
          guard let data = UIImage(cgImage: img).jpegData(compressionQuality: 0.75) else { throw NSError(domain: "jpg", code: 0) }
          try data.write(to: URL(fileURLWithPath: salida))
          DispatchQueue.main.async { result(salida) }
        } catch {
          DispatchQueue.main.async { result(FlutterError(code: "miniatura", message: error.localizedDescription, details: nil)) }
        }
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private static func comprimir(_ asset: AVURLAsset, _ salida: URL, _ logo: UIImage?, _ result: @escaping FlutterResult) {
    let compatibles = AVAssetExportSession.exportPresets(compatibleWith: asset)
    let preset = compatibles.contains(AVAssetExportPreset1280x720) ? AVAssetExportPreset1280x720 : AVAssetExportPresetHighestQuality
    guard let export = AVAssetExportSession(asset: asset, presetName: preset) else {
      return result(FlutterError(code: "comprimir", message: "No se pudo preparar la compresión", details: nil))
    }
    try? FileManager.default.removeItem(at: salida)
    export.outputURL = salida
    export.outputFileType = .mp4
    export.shouldOptimizeForNetworkUse = true
    // Sin la ubicación GPS ni otros datos del teléfono que graban los iPhone:
    // los videos de autos en venta se publican en la web.
    export.metadataItemFilter = .forSharing()
    if let logo = logo, let pista = asset.tracks(withMediaType: .video).first {
      // Tamaño del video ya girado (los videos verticales vienen con rotación).
      let r = CGRect(origin: .zero, size: pista.naturalSize).applying(pista.preferredTransform)
      let tamano = CGSize(width: abs(r.width), height: abs(r.height))
      let capa = Marca.dibujar(sobre: nil, tamano: tamano, logo: logo)
      if let cg = capa.cgImage {
        let encima = CIImage(cgImage: cg)
        export.videoComposition = AVMutableVideoComposition(asset: asset) { req in
          // sourceImage ya viene orientada; la marca se pone encima en cada cuadro.
          let fuente = req.sourceImage
          let marca = encima.transformed(by: CGAffineTransform(translationX: fuente.extent.minX, y: fuente.extent.minY))
          req.finish(with: marca.composited(over: fuente).cropped(to: fuente.extent), context: nil)
        }
      }
    }
    export.exportAsynchronously {
      DispatchQueue.main.async {
        if export.status == .completed {
          result(salida.path)
        } else {
          result(FlutterError(code: "comprimir", message: export.error?.localizedDescription ?? "Estado \(export.status.rawValue)", details: nil))
        }
      }
    }
  }
}

/// Marca de agua de Atlas Motors: escudo grande y muy tenue al centro (para que
/// recortar no baste) y escudo con "atlasmotors.cl" abajo a la derecha.
enum Marca {
  static func dibujar(sobre foto: UIImage?, tamano: CGSize, logo: UIImage) -> UIImage {
    let formato = UIGraphicsImageRendererFormat()
    formato.scale = 1
    formato.opaque = foto != nil
    return UIGraphicsImageRenderer(size: tamano, format: formato).image { ctx in
      foto?.draw(in: CGRect(origin: .zero, size: tamano))
      let lado = min(tamano.width, tamano.height)
      let proporcion = logo.size.width / logo.size.height

      // Centro: escudo grande al 6 %.
      let hc = lado * 0.6
      let wc = hc * proporcion
      logo.draw(in: CGRect(x: (tamano.width - wc) / 2, y: (tamano.height - hc) / 2, width: wc, height: hc),
                blendMode: .normal, alpha: 0.06)

      // Esquina: escudo + texto sobre una franja oscura semitransparente.
      let h = max(lado * 0.075, 18)
      let fuente = UIFont.systemFont(ofSize: h * 0.42, weight: .bold)
      let texto = NSAttributedString(string: "atlasmotors.cl", attributes: [.font: fuente, .foregroundColor: UIColor.white])
      let tt = texto.size()
      let wl = h * proporcion
      let pad = h * 0.18
      let margen = lado * 0.03
      let ancho = pad + wl + pad * 1.2 + tt.width + pad * 1.6
      let alto = h + pad * 2
      let caja = CGRect(x: tamano.width - margen - ancho, y: tamano.height - margen - alto, width: ancho, height: alto)
      UIColor(white: 0, alpha: 0.38).setFill()
      UIBezierPath(roundedRect: caja, cornerRadius: alto * 0.3).fill()
      logo.draw(in: CGRect(x: caja.minX + pad, y: caja.minY + pad, width: wl, height: h), blendMode: .normal, alpha: 0.95)
      texto.draw(at: CGPoint(x: caja.minX + pad + wl + pad * 1.2, y: caja.midY - tt.height / 2))
      _ = ctx
    }
  }
}
