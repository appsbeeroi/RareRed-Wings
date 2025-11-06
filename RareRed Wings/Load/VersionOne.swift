import SwiftUI

struct VersionOne: View {
    @State private var chickenPosition: Int = 0
    @State private var isJumping: Bool = false
    @State private var showWinWindow: Bool = false
    @State private var idleTimer: Timer?
    @State private var lastJumpTime: Date = Date()
    @State private var hasJumped: Bool = false
    @State private var lastAllowedJumpTime: Date = Date()
    let platformPositions: [CGFloat] = [150, 280, 410, 540, 670]
    let platformCount = 5
    let minimumJumpInterval: TimeInterval = 1.3
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Image("bg_main")
                    .resizable()
                    .ignoresSafeArea()
                
                ZStack {
                    ForEach(0..<platformCount, id: \.self) { index in
                        Image("platform")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 26)
                            .position(x: geometry.size.width / 2, y: geometry.size.height - platformPositions[index])
                    }
                    
                    Image("chest")
                        .resizable()
                        .frame(width: 80, height: 80)
                        .position(x: geometry.size.width / 2, y: geometry.size.height - platformPositions[platformCount - 1] - 60)
                    
                    Image("chicken")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 107)
                        .position(x: geometry.size.width / 2, y: geometry.size.height - platformPositions[chickenPosition] - 65)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: chickenPosition)
                }
                
                VStack {
                    Spacer()
                    
                    Button(action: {
                        jumpChicken()
                    }) {
                        Image("btn_jump")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 94)
                    }
                    .disabled(isJumping || showWinWindow)
                    .padding(.bottom, 10)
                }
                
                if showWinWindow {
                    Color.black.opacity(0.7)
                        .ignoresSafeArea()
                        .transition(.opacity)
                    
                    VStack(spacing: 20) {
                        ZStack {
                            Image("window_win")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 352)
                            
                            VStack(spacing: 0) {
                                Spacer()
                                
                                Button(action: {
                                    collectWin()
                                }) {
                                    Image("btn_collect")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 85)
                                }
                                .padding(.bottom, 20)
                            }
                            .frame(height: 352)
                        }
                    }
                    .scaleEffect(showWinWindow ? 1.0 : 0.5)
                    .opacity(showWinWindow ? 1.0 : 0.0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: showWinWindow)
                }
            }
        }
        .onAppear {
            startIdleTimer()
        }
        .onDisappear {
            stopIdleTimer()
        }
    }
    
    func jumpChicken() {
        guard !isJumping && chickenPosition < platformCount - 1 else { return }
        
        let currentTime = Date()
        let timeSinceLastJump = currentTime.timeIntervalSince(lastAllowedJumpTime)
        
        guard timeSinceLastJump >= minimumJumpInterval else { return }
        
        isJumping = true
        hasJumped = true
        lastJumpTime = currentTime
        lastAllowedJumpTime = currentTime
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            chickenPosition += 1
            if chickenPosition == platformCount - 1 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showWinWindow = true
                    stopIdleTimer()
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isJumping = false
            }
        }
    }
    
    func collectWin() {
        NotificationCenter.default.post(name: .loaderActionTriggered, object: nil)
    }
    
    func startIdleTimer() {
        guard idleTimer == nil else { return }
        
        lastJumpTime = Date()
        
        idleTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [self] _ in
            let timeSinceLastJump = Date().timeIntervalSince(lastJumpTime)
            
            let idleTimeThreshold: TimeInterval = hasJumped ? 3.0 : 5.0
            
            if timeSinceLastJump >= idleTimeThreshold && !showWinWindow {
                showWinWindow = true
                stopIdleTimer()
            }
        }
        if let timer = idleTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }
    
    func stopIdleTimer() {
        idleTimer?.invalidate()
        idleTimer = nil
    }
}

#Preview {
    VersionOne()
}
