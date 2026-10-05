import SwiftUI
import CoreImage.CIFilterBuiltins

struct InviteView: View {
  let roll: Roll
  var inviteURL: URL {
    URL(string: "twentyfour://join/\(roll.id)?code=\(roll.inviteCode)")!
  }
  var body: some View {
    VStack(spacing: 16) {
      if let qr = qrImage(from: inviteURL.absoluteString) {
        Image(uiImage: qr)
          .interpolation(.none)
          .resizable()
          .scaledToFit()
          .frame(width: 220, height: 220)
      }
      Text(inviteURL.absoluteString)
      ShareLink(item: inviteURL)
    }
  }
  private func qrImage(from text: String) -> UIImage? {
    let filter = CIFilter.qrCodeGenerator()
    filter.message = Data(text.utf8)
    guard let output = filter.outputImage else {return nil}
    guard let cgImage = CIContext().createCGImage(output, from: output.extent) else {return nil}
    return UIImage(cgImage: cgImage)
  }
}