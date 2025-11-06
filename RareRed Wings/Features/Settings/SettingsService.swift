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
