import SwiftUI
import Combine

final class TabbarService: ObservableObject {
    
    static let shared = TabbarService()
    
    private init() {}
    
    @Published var isTabbarVisible: Bool = true
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
