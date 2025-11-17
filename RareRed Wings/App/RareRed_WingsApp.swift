import SwiftUI
import Combine

@main
struct RareRed_WingsApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            BlackWindow(rootView: RootView()
                .environmentObject(AppRouter.shared)
                .environmentObject(TabbarService.shared)
                .environmentObject(BirdMarkService.shared)
                .environmentObject(ObservationService.shared)
                .environmentObject(SettingsService.shared)
                .dynamicTypeSize(.large)
                .preferredColorScheme(.light)
                .background(.white), remoteConfigKey: AppConstants.remoteConfigKey)
        }
    }
}

struct AppConstants {
    static let metricsBaseURL = "https://biredbo.com/app/metrics"
    static let salt = "XH9hN1DDywFHLzRToPSdGkyGNoaZfsPZ"
    static let oneSignalAppID = "7e18e0ef-42f6-4d88-945d-c343f8feb6eb"
    static let userDefaultsKey = "rare"
    static let remoteConfigStateKey = "rareRed"
    static let userUUIDKey = "userUUID"
    static let configStrategyKey = "rareRedWingsConfigStrategy"
    
    static let remoteConfigKey = "isRedWingsEnable"
    static let appsFlyerDevKeyConfigKey = "appsflyer_dev_key"
    static let appsFlyerCampaignURLKey = "appsflyer_campaign_url"
    static let loaderVersionConfigKey = "loader_version"
    static let appsFlyerAppID = "6754912456"
    
    static let primaryConfigTimeout: TimeInterval = 10.0
    static let appsFlyerDataTimeout: TimeInterval = 15.0
}

