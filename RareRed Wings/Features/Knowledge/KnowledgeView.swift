import SwiftUI

struct KnowledgeMainView: View {
    @EnvironmentObject private var appRouter: AppRouter
    @EnvironmentObject private var tabbarService: TabbarService
    
    @State private var selectedArticle: KnowledgeArticle? = nil
    
    private var articlesByCategory: [ArticleCategory: [KnowledgeArticle]] {
        Dictionary(grouping: KnowledgeArticle.seed) { $0.category }
    }
    
    var body: some View {
        @ObservedObject var appRouter = appRouter
        
        NavigationStack(path: $appRouter.knowledgeRoute) {
            ZStack(alignment: .center) {
                BackGroundView()
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Knowledge section")
                        .font(.customFont(font: .regular, size: 32))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    ScrollView(.vertical) {
                        ForEach(ArticleCategory.allCases, id: \.self) { category in
                            VStack(alignment: .leading, spacing: 0) {
                                Text(category.displayName)
                                    .font(.customFont(font: .regular, size: 18))
                                    .foregroundStyle(.customBlack)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                VStack(spacing: 8) {
                                    ForEach(articlesByCategory[category] ?? []) { article in
                                        KnowledgeArticleCard(article: article) {
                                            selectedArticle = article
                                            appRouter.knowledgeRoute.append(.articleDetail)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.bottom, AppConfig.adaptiveTabbarBottomPadding)
                    }
                    .padding(.horizontal)
                }
                .scrollIndicators(.hidden)
            }
            .onAppear {
                tabbarService.isTabbarVisible = true
            }
            .navigationDestination(for: KnowledgeScreen.self) { screen in
                switch screen {
                case .main:
                    EmptyView()
                case .articleDetail:
                    if let article = selectedArticle {
                        KnowledgeArticleDetailView(article: article)
                    } else {
                        EmptyView()
                    }
                }
            }
        }
    }
}

struct KnowledgeArticleCard: View {
    let article: KnowledgeArticle
    let onTap: (() -> Void)?
    
    init(article: KnowledgeArticle, onTap: (() -> Void)? = nil) {
        self.article = article
        self.onTap = onTap
    }
    
    var body: some View {
        Button(action: {
            onTap?()
        }) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(article.title)
                        .font(.customFont(font: .regular, size: 16))
                        .foregroundStyle(.customBlack)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                    
                    Text(article.subtitle)
                        .font(.customFont(font: .regular, size: 14))
                        .foregroundStyle(.customBlack.opacity(0.6))
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                if article.hasExternalLink {
                    Image(systemName: "link")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.blue)
                        .frame(width: 20, height: 20)
                }
            }
            .padding(.horizontal, 32)
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

struct KnowledgeArticleDetailView: View {
    @EnvironmentObject private var appRouter: AppRouter
    @EnvironmentObject private var tabbarService: TabbarService
    
    let article: KnowledgeArticle
    
    var body: some View {
        ZStack(alignment: .center) {
            BackGroundView()
            
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 20) {
                    Text(article.category.displayName)
                        .font(.customFont(font: .regular, size: 14))
                        .foregroundStyle(.customBlack.opacity(0.6))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Color.white.opacity(0.8)))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(article.title)
                        .font(.customFont(font: .regular, size: 24))
                        .foregroundStyle(.customBlack)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(article.subtitle)
                        .font(.customFont(font: .regular, size: 16))
                        .foregroundStyle(.customBlack.opacity(0.7))
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(article.content)
                        .font(.customFont(font: .regular, size: 16))
                        .foregroundStyle(.customBlack)
                        .multilineTextAlignment(.leading)
                        .lineSpacing(4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if article.hasExternalLink, let link = article.externalURL, let url = URL(string: link) {
                        Button(action: {
                            UIApplication.shared.open(url)
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "link")
                                    .font(.system(size: 16, weight: .medium))
                                Text("Read more online")
                                    .font(.customFont(font: .regular, size: 16))
                            }
                            .foregroundStyle(.blue)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Capsule().fill(Color.blue.opacity(0.1)))
                        }
                        .buttonStyle(.plain)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal)
            }
            .scrollIndicators(.hidden)
        }
        .onAppear {
            tabbarService.isTabbarVisible = false
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                BackButtonView {
                    if !appRouter.knowledgeRoute.isEmpty {
                        appRouter.knowledgeRoute.removeLast()
                    }
                }
            }
        }
    }
}
