import SwiftUI

enum BalooBhaina: String {
    case regular = "BalooBhaina-Regular"
}

extension Font {
    static func customFont(font: BalooBhaina, size: CGFloat) -> SwiftUI.Font {
        .custom(font.rawValue, size: size)
    }
}

