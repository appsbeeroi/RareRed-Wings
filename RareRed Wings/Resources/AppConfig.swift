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
import Combine

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
