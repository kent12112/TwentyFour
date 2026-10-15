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
            .font(.system(size: 28, weight: .bold, design: .rounded))
          Text("to \(roll.name)")
            .font(.system(size: 13, design: .rounded))
            .foregroundStyle(Theme.ink.opacity(0.6))
        }

        VStack(spacing: 8) {
          if let qr = qrImage(from: inviteURL.absoluteString) {
            Image(uiImage: qr)
              .interpolation(.none)
              .resizable()
              .scaledToFit()
              .frame(width: 180, height: 180)
              .padding(16)
              .background(.white, in: RoundedRectangle(cornerRadius: 16))
          }
          Text("Scan with an iPhone camera")
            .font(.system(size: 13, design: .rounded))
            .foregroundStyle(Theme.ink.opacity(0.6))
        }
        .frame(maxWidth: .infinity)

        Spacer()

        ShareLink(item: inviteURL) {
          Label("Share invite link", systemImage: "square.and.arrow.up")
            .font(.system(size: 17, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(Theme.ink, in: RoundedRectangle(cornerRadius: 12))
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
