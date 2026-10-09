import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit

enum FilmProcessor {
  private static let context = CIContext()

  static func process(_ data: Data) -> Data? {
    guard let input = CIImage(data: data, options: [.applyOrientationProperty: true]) else { return nil }
    
    let longSide = max(input.extent.width, input.extent.height)
    let scale = min(1, 1600 / longSide)

    let resize = CIFilter.lanczosScaleTransform()
    resize.inputImage = input
    resize.scale = Float(scale)
    resize.aspectRatio = 1

    let warm = CIFilter.temperatureAndTint()
    warm.inputImage = resize.outputImage
    warm.neutral = CIVector(x: 6500, y: 0)
    warm.targetNeutral = CIVector(x: 5200, y:10)

    let color = CIFilter.colorControls()
    color.inputImage = warm.outputImage
    color.contrast = 0.9
    color.saturation = 0.9

    let vignette = CIFilter.vignette()
    vignette.inputImage = color.outputImage
    vignette.intensity = 1.0
    vignette.radius = 2.0

    guard let vignetted = vignette.outputImage else { return nil }
    let shift = CGAffineTransform(translationX: .random(in: 0...1000), y: .random(in: 0...1000))
    let noise = CIFilter.randomGenerator().outputImage!.transformed(by: shift)

    let tone = CIFilter.colorMatrix()
    tone.inputImage = noise
    tone.rVector = CIVector(x: 0.12, y: 0, z: 0, w: 0)
    tone.gVector = CIVector(x: 0.12, y: 0, z: 0, w: 0)
    tone.bVector = CIVector(x: 0.12, y: 0, z: 0, w: 0)
    tone.aVector = CIVector(x: 0, y: 0, z: 0, w: 0)
    tone.biasVector = CIVector(x: 0.44, y: 0.44, z: 0.44, w: 1)

    
    let grain = CIFilter.softLightBlendMode()
    grain.inputImage = tone.outputImage?.cropped(to: vignetted.extent)
    grain.backgroundImage = vignetted

    guard let output = grain.outputImage else {return nil}
    
    guard let cqImage = context.createCGImage(output, from: output.extent) else { return nil }
    let size = CGSize(width: cqImage.width, height: cqImage.height)

    let format = UIGraphicsImageRendererFormat()
    format.scale = 1
    let renderer = UIGraphicsImageRenderer(size: size, format: format)

    let stamped = renderer.image { _ in 
      UIImage(cgImage: cqImage).draw(at: .zero)

      let formatter = DateFormatter()
      formatter.dateFormat = "''yy MM dd"
      let text = formatter.string(from: Date()) as NSString

      let attributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.monospacedDigitSystemFont(ofSize: size.width * 0.035, weight: .semibold),
        .foregroundColor: UIColor(red: 1, green: 0.55, blue: 0.15, alpha: 0.9)
      ]
      let textSize = text.size(withAttributes: attributes)
      let margin = size.width * 0.04
      let point = CGPoint(x: size.width - textSize.width - margin , y: size.height - textSize.height - margin)
      text.draw(at: point, withAttributes: attributes)
    }
    return stamped.jpegData(compressionQuality: 0.85)
  }
}