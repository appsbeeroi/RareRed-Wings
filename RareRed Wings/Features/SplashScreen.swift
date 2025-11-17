import SwiftUI

struct SplashMainView: View {
    
    @EnvironmentObject private var appRouter: AppRouter
    
    var body: some View {
        ZStack(alignment: .center) {
            Image("backGroundSplash")
                .resizable()
                .ignoresSafeArea()
            
            VStack {
                Text("RareRed\nWings")
                    .multilineTextAlignment(.center)
                
                ProgressView()
                    .scaleEffect(1.5)
            }
            .frame(maxHeight: .infinity, alignment: .bottom)
            .padding(.bottom, 120)
            .font(.system(size: 58, weight: .bold, design: .rounded))
        }
        .onReceive(NotificationCenter.default.publisher(for: .splashTransition)) { _ in
            withAnimation {
                appRouter.currentMainScreen = .tabbar
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
