import SwiftUI

struct VersionTwo: View {
    @State private var roadScaleEffect = 1.0
    @State private var isRotating = false
    @State private var loaderScale = 1.0
    
    var body: some View {
        ZStack {
            Image("bg_main2")
                .resizable()
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                Image("road_image")
                    .resizable()
                    .scaledToFit()
                    .padding(.horizontal, 60)
                    .scaleEffect(roadScaleEffect)
                    .animation(.bouncy(duration: 0.45).repeatForever(), value: roadScaleEffect)
                
                Spacer()
                
                ZStack {
                    Image("loader_center")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 59)
                    
                    Image("loader_border")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 156)
                        .scaleEffect(loaderScale)
                        .rotationEffect(.degrees(isRotating ? 360 : 0))
                        .onAppear {
                            withAnimation(.linear(duration: 1.05).repeatForever(autoreverses: false)) {
                                isRotating = true
                            }
                            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                                loaderScale = 1.18
                            }
                        }
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            roadScaleEffect = 1.4
        }
    }
}

#Preview {
    VersionTwo()
}
