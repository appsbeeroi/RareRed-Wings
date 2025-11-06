import SwiftUI

struct AppConfig {
    
    static let tabbarHeight: CGFloat = 96
    static let tabbarBottomPadding: CGFloat = tabbarHeight - 32
    static let tabbarHorizontalPadding: CGFloat = 24
    
    static var isIPhoneSE3rdGeneration: Bool {
        let screenHeight = UIScreen.main.bounds.height
        return screenHeight == 667
    }
    
    static var adaptiveTabbarHeight: CGFloat {
        isIPhoneSE3rdGeneration ? tabbarHeight - 24 : tabbarHeight
    }
    
    static var adaptiveTabbarBottomPadding: CGFloat {
        isIPhoneSE3rdGeneration ? 74 : tabbarBottomPadding
    }
}

