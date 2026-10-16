import CoreImage.CIFilterBuiltins
import SwiftUI

struct InviteView: View {
  let roll: Roll
  var inviteURL: URL {
    URL(string: "twentyfour://join/\(roll.id)?code=\(roll.inviteCode)")!
  }
  var body: some View {
    ZStack {
      Theme.paper.ignoresSafeArea()

      VStack(alignment: .leading, spacing: 16) {
        VStack(alignment: .leading, spacing: 4) {
          Text("Invite friends")
            .font(Theme.sans(30))
          Text("to \(roll.name)")
            .metaStyle(10)
        }

        VStack(spacing: 8) {
          if let qr = qrImage(from: inviteURL.absoluteString) {
            Image(uiImage: qr)
              .interpolation(.none)
              .resizable()
              .scaledToFit()
              .frame(width: 180, height: 180)
              .padding(16)
              .background(.white)
              .overlay(Rectangle().stroke(Theme.line, lineWidth: 1))
          }
          Text("Scan with an iPhone camera")
            .metaStyle(9)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)

        Spacer()

        ShareLink(item: inviteURL) {
          Label("Share invite link", systemImage: "square.and.arrow.up")
            .font(Theme.sans(15, .medium))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(Theme.ink)
        }
        .buttonStyle(.plain)
      }
      .padding(24)
      .foregroundStyle(Theme.ink)
    }
  }
  private func qrImage(from text: String) -> UIImage? {
    let filter = CIFilter.qrCodeGenerator()
    filter.message = Data(text.utf8)
    guard let output = filter.outputImage else { return nil }
    guard let cgImage = CIContext().createCGImage(output, from: output.extent) else { return nil }
    return UIImage(cgImage: cgImage)
  }
}
