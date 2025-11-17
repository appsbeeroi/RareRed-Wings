import Foundation
import SwiftUI
import UserNotifications
import Combine

@MainActor
final class SettingsService: ObservableObject {
    
    static let shared = SettingsService()
    
    @Published var isCancelled = false
    
    private init() {
        loadSettings()
    }
        
    @Published var isNotificationsEnabled: Bool = false
        
    private let userDefaults = UserDefaults.standard
    private let notificationsKey = "isNotificationsEnabled"
        
    func toggleNotifications() {
        let newValue = !isNotificationsEnabled
        Task { await setNotifications(enabled: newValue) }
    }

    func setNotifications(enabled: Bool) async {
        if enabled {
            let granted = await requestAuthorizationIfNeeded()
            if granted {
                await scheduleDailyReminders()
                await MainActor.run {
                    self.isNotificationsEnabled = true
                    self.saveSettings()
                }
            } else {
                await MainActor.run {
                    self.isNotificationsEnabled = false
                    self.saveSettings()
                    self.isCancelled = true
                }
            }
        } else {
            await cancelDailyReminders()
            await MainActor.run {
                self.isNotificationsEnabled = false
                self.saveSettings()
            }
        }
    }
    
    func openAboutPage() {
        if let url = URL(string: "https://sites.google.com/view/redbookbird/home") {
            UIApplication.shared.open(url)
        }
    }
    
    func openPrivacyPolicy() {
        if let url = URL(string: "https://sites.google.com/view/redbookbird/privacy-policy") {
            UIApplication.shared.open(url)
        }
    }
    
    func importData() {
        print("Import data tapped")
    }
    
    func exportData() {
        print("Export data tapped")
    }
    
    // MARK: - Private Methods
    
    private func loadSettings() {
        isNotificationsEnabled = userDefaults.bool(forKey: notificationsKey)
        if isNotificationsEnabled {
            Task { await scheduleDailyReminders() }
        }
    }
    
    private func saveSettings() {
        userDefaults.set(isNotificationsEnabled, forKey: notificationsKey)
    }

    // MARK: - Notifications
    func requestAuthorizationIfNeeded() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied:
            return false
        case .notDetermined:
            do {
                let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
                return granted
            } catch {
                print("Notifications auth error: \(error)")
                return false
            }
        @unknown default:
            return false
        }
    }
    
    private func scheduleDailyReminders() async {
        let center = UNUserNotificationCenter.current()
        await cancelDailyReminders()
        
        let messages = [
            "Don't forget to log a new bird today!",
            "Check bird info and learn something new.",
            "Mark today's bird sighting in your diary."
        ]
        
        for weekday in 1...7 {
            let content = UNMutableNotificationContent()
            let idx = weekday % messages.count
            content.title = "RedBookBird"
            content.body = messages[idx]
            content.sound = .default
            
            var date = DateComponents()
            date.weekday = weekday
            date.hour = 12
            date.minute = 0
            let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
            let id = "daily_12_weekday_\(weekday)"
            let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
            do { try await center.add(request) } catch { print("schedule error: \(error)") }
        }
    }
    
    private func cancelDailyReminders() async {
        let ids = (1...7).map { "daily_12_weekday_\($0)" }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
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
