import SwiftUI

struct BackButtonView: View {
    
    var onTap: (() -> Void)? = nil
    
    var body: some View {
        Button {
            onTap?()
        } label: {
            HStack(alignment: .center, spacing: 4) {
                Image("backButton")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32, alignment: .center)
                Text("Back")
                    .font(.customFont(font: .regular, size: 16))
                    .foregroundStyle(.customBlack)
                    .baselineOffset(-4)
            }
        }
        .buttonStyle(.plain)
    }
}
