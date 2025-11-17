import SwiftUI
import Combine

struct TabbarMainView: View {
    
    @EnvironmentObject private var tabbarService: TabbarService
    @State private var selectedTab: AppTabScreen = .catalog
    
    var body: some View {
        ZStack(alignment: .center) {
            Group {
                switch selectedTab {
                case .catalog:
                    CatalogMainView()
                case .personal:
                    PersonalMainView()
                case .history:
                    HistoryMainView()
                case .knowledge:
                    KnowledgeMainView()
                case .settings:
                    SettingsMainView()
                }
            }
            
            if tabbarService.isTabbarVisible {
                VStack(alignment: .center, spacing: 0) {
                    Spacer()
                    TabbarBottomView(selectedTab: $selectedTab)
                }
            }
        }
        .ignoresSafeArea(.all, edges: .bottom)
    }
}

@MainActor
final class AppRouter: ObservableObject {
    
    static let shared = AppRouter()
    private init() {}
    
    @Published var currentMainScreen: AppMainScreen = .splash
    @Published var catalogRoute: [CatalogScreen] = []
    @Published var personalRoute: [PersonalScreen] = []
    @Published var historyRoute: [HistoryScreen] = []
    @Published var knowledgeRoute: [KnowledgeScreen] = []
    @Published var settingsRoute: [SettingsScreen] = []
}

enum AppMainScreen {
    case splash
    case tabbar
}

enum CatalogScreen: Hashable {
    case main
    case detail
}

enum PersonalScreen {
    case main
    case addObservation
    case observationDetail
}

enum HistoryScreen: Hashable {
    case main
    case observationDetail
}

enum KnowledgeScreen: Hashable {
    case main
    case articleDetail
}

enum SettingsScreen {
    case main
}

enum AppTabScreen {
    case catalog
    case personal
    case history
    case knowledge
    case settings
    
    var selectedTabScreenIndex: Int {
        switch self {
        case .catalog:
            return 0
        case .personal:
            return 1
        case .history:
            return 2
        case .knowledge:
            return 3
        case .settings:
            return 4
        }
    }
}

struct TabbarItem {
    let icon: String
}

struct TabbarBottomView: View {
    @Binding var selectedTab: AppTabScreen
    
    private let tabbarItems: [TabbarItem] = [
        TabbarItem(icon: "catalog"),
        TabbarItem(icon: "personal"),
        TabbarItem(icon: "history"),
        TabbarItem(icon: "knowledge"),
        TabbarItem(icon: "settings")
    ]
    
    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            Spacer()
            
            ForEach(tabbarItems.indices, id: \.self) { index in
                VStack(spacing: 0) {
                    Image(tabbarItems[index].icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 63, height: 63, alignment: .center)
                    
                    Spacer()
                }
                .foregroundColor(selectedTab.selectedTabScreenIndex == index
                                 ? .customLightOrange : .customLightGray)
                .onTapGesture {
                    switch index {
                    case 1: selectedTab = .personal
                    case 2: selectedTab = .history
                    case 3: selectedTab = .knowledge
                    case 4: selectedTab = .settings
                    default: selectedTab = .catalog
                    }
                }
            }
            
            Spacer()
        }
        .frame(height: AppConfig.adaptiveTabbarHeight)
        .background(Color(hex: "90B45A"))
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 20, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 20))
    }
}

import SwiftUI
import CryptoKit
import WebKit
import AppTrackingTransparency
import UIKit
import FirebaseCore
import FirebaseRemoteConfig
import OneSignalFramework
import AdSupport
import AppsFlyerLib
import Network


class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    private var lastPermissionCheck: Date?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()
        OneSignal.Debug.setLogLevel(.LL_VERBOSE)
        OneSignal.initialize(AppConstants.oneSignalAppID, withLaunchOptions: launchOptions)
        UNUserNotificationCenter.current().delegate = self
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTrackingAction),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        return true
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        AppsFlyerService.shared.start()
    }
    
    @objc private func handleTrackingAction() {
        if UIApplication.shared.applicationState == .active {
            let now = Date()
            if let last = lastPermissionCheck, now.timeIntervalSince(last) < 2 {
                return
            }
            lastPermissionCheck = now
            AppsFlyerService.shared.start()
            NotificationCenter.default.post(name: .checkTrackingPermission, object: nil)
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
    }
}
