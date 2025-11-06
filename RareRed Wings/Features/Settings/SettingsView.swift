import SwiftUI

struct SettingsMainView: View {
    
    @EnvironmentObject private var settingsService: SettingsService
    @EnvironmentObject private var tabbarService: TabbarService
    
    @State private var urlString: String?
    
    @State private var isShowRemoveAlert = false
    
    var body: some View {
        ZStack(alignment: .center) {
            BackGroundView()
            
            VStack(alignment: .leading, spacing: 20) {
                Text("Settings")
                    .font(.customFont(font: .regular, size: 32))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .frame(maxWidth: .infinity, alignment: .center)
                
                VStack(spacing: 12) {
                    SettingsRowView(
                        title: "Notifications",
                        trailingContent: AnyView(
                            ToggleContent(
                                isOn: $settingsService.isNotificationsEnabled
                            ) { newValue in
                                Task { await settingsService.setNotifications(enabled: newValue) }
                            }
                        )
                    )
                    
                    SettingsRowView(
                        title: "Remove all the data",
                        action: {
                            isShowRemoveAlert.toggle()
                        },
                        trailingContent: AnyView(Image(systemName: "multiply").foregroundStyle(.red))
                    )
                    
                    SettingsRowView(
                        title: "About the application",
                        action: {
                            tabbarService.isTabbarVisible = false
                            urlString = "https://sites.google.com/view/rarered-wings/home"
                        },
                        trailingContent: AnyView(ChevronContent())
                    )
                    
                    SettingsRowView(
                        title: "Privacy Policy",
                        action: {
                            tabbarService.isTabbarVisible = false
                            urlString = "https://sites.google.com/view/rarered-wings/privacy-policy"
                        },
                        trailingContent: AnyView(ChevronContent())
                    )
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            
            if let urlString,
               let url = URL(string: urlString) {
                WebView(url: url) {
                    self.urlString = nil
                    tabbarService.isTabbarVisible = true
                }
                .ignoresSafeArea(edges: [.bottom])
            }
        }
        .alert("Are you sure you want to delete all the data?", isPresented: $isShowRemoveAlert) {
            Button("Yes", role: .destructive) {
                ObservationService.shared.removeAll()
            }
        }
        .alert("The permission denied. Open Settings?", isPresented: $settingsService.isCancelled) {
            Button("Yes") {
                openSettings()
            }
            
            Button("Cancel") {}
        }
        .onAppear {
            tabbarService.isTabbarVisible = true
        }
    }
    
    private func openSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
        if UIApplication.shared.canOpenURL(settingsURL) {
            UIApplication.shared.open(settingsURL)
        }
    }
}

struct SettingsRowView: View {
    let title: String
    let action: (() -> Void)?
    let trailingContent: AnyView?
    
    init(title: String, action: (() -> Void)? = nil, trailingContent: AnyView? = nil) {
        self.title = title
        self.action = action
        self.trailingContent = trailingContent
    }
    
    var body: some View {
        Button(action: {
            action?()
        }) {
            HStack(spacing: 12) {
                Text(title)
                    .font(.customFont(font: .regular, size: 20))
                    .foregroundStyle(.customBlack)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                if let trailingContent = trailingContent {
                    trailingContent
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(hex: "90B45A"))
            .cornerRadius(20)
            .overlay(content: {
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color(hex: "E1F8BD"), lineWidth: 1)
            })
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(.plain)
    }
}

struct ToggleContent: View {
    @Binding var isOn: Bool
    let onChange: (Bool) -> Void
    
    var body: some View {
        Toggle("", isOn: $isOn)
            .toggleStyle(SwitchToggleStyle(tint: .yellow))
            .onChange(of: isOn) { value in
                onChange(value)
            }
    }
}

struct ChevronContent: View {
    var body: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(.yellow)
    }
}

