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
