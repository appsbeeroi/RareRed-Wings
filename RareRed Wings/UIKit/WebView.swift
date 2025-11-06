import SwiftUI
import WebKit

struct WebView: View {
    
    let url: URL
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button("Back") {
                    action()
                }
            }
            .frame(height: 50)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 20)
            .background(.black)
            
            Divider()
            
            WebViewRepresentable(url: url)
        }
    }
}

struct WebViewRepresentable: UIViewRepresentable {
    
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        return WKWebView()
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        uiView.load(request)
    }
}
