import SwiftUI
import Combine

final class TabbarService: ObservableObject {
    
    static let shared = TabbarService()
    
    private init() {}
    
    @Published var isTabbarVisible: Bool = true
}
