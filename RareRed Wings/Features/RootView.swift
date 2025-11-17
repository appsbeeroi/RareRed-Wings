import SwiftUI

struct RootView: View {
    
    @EnvironmentObject private var appRouter: AppRouter
    
    var body: some View {
        Group {
            switch appRouter.currentMainScreen {
            case .splash:
                SplashMainView()
            case .tabbar:
                TabbarMainView()
            }
        }
        .onAppear {
            Task {
                await SettingsService.shared.requestAuthorizationIfNeeded()
            }
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
