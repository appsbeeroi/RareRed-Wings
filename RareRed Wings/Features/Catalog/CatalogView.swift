import SwiftUI

struct CatalogMainView: View {
    
    @EnvironmentObject private var appRouter: AppRouter
    @EnvironmentObject private var tabbarService: TabbarService
    @State private var searchText: String = ""
    @FocusState private var isSearchFocused: Bool
    @State private var isKeyboardVisible: Bool = false
    @State private var selectedBirdId: Int? = nil
    
    @State private var favoritesIDS: [Int] = []
        
    private var filteredBirds: [RareBird] {
        var dataSource = RareBird.seed
        
        for id in favoritesIDS {
            if let index = dataSource.firstIndex(where: { $0.id == id }) {
                dataSource[index].isFavorite = true
            }
        }
        
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return dataSource }
        return dataSource.filter { bird in
            bird.commonName.lowercased().contains(query.lowercased())
        }
    }
    
    var body: some View {
        @ObservedObject var appRouter = appRouter
        
        NavigationStack(path: $appRouter.catalogRoute) {
            ZStack(alignment: .center) {
                BackGroundView()
                
                VStack(alignment: .center, spacing: 8) {
                    Text("Catalog of rare birds")
                        .font(.customFont(font: .regular, size: 32))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    
                    HStack(alignment: .center, spacing: 8) {
                        Image("searchIcon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24, alignment: .center)
                            .foregroundColor(.customLightBrown)
                        
                        TextField("Search by name", text: $searchText)
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                            .focused($isSearchFocused)
                            .font(.customFont(font: .regular, size: 20))
                            .foregroundStyle(.customBlack)
                        
                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                                isSearchFocused = false
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.customLightBrown)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 4)
                    .background(Color(hex: "90B45A"))
                    .cornerRadius(20)
                    .overlay(content: {
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color(hex: "E1F8BD"), lineWidth: 1)
                    })
                    .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 2)
                    
                    if filteredBirds.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "multiply")
                                .font(.system(size: 120, weight: .medium))
                                .foregroundStyle(.customLightGray)
                            
                            Text("There are no\nsearched birds")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundStyle(.customBlack)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .overlay(content: {
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(.white, lineWidth: 1)
                        })
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    } else {
                        ScrollView(showsIndicators: false) {
                            LazyVStack(alignment: .leading, spacing: 12) {
                                ForEach(filteredBirds) { bird in
                                    RareBirdCard(bird: bird, favoritesIDS: favoritesIDS) {
                                        selectedBirdId = bird.id
                                        appRouter.catalogRoute.append(.detail)
                                    }
                                }
                            }
                            .padding(.horizontal, 3)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, isKeyboardVisible ? 4 : AppConfig.adaptiveTabbarBottomPadding)
            }
            .onAppear {
                loadIDS()
                tabbarService.isTabbarVisible = true
            }
            .contentShape(Rectangle())
            .onTapGesture {
                isSearchFocused = false
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
                isKeyboardVisible = true
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                isKeyboardVisible = false
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .navigationDestination(for: CatalogScreen.self) { screen in
                switch screen {
                case .main: CatalogMainView()
                case .detail:
                    if let id = selectedBirdId {
                        RareBirdDetailView(birdId: id)
                    }
                }
            }
        }
    }
    
    private func loadIDS() {
        let userDefaults = UserDefaults.standard
        let key = "IDs"
        
        if let data = userDefaults.data(forKey: key),
           let model = try? JSONDecoder().decode(IDSModel.self, from: data) {
            self.favoritesIDS = model.ids
        }
    }
}

struct IDSModel: Codable {
    var id: UUID
    var ids: [Int]
    
    init() {
        self.id = UUID()
        self.ids = []
    }
}

struct RareBirdCard: View {
    let bird: RareBird
    var favoritesIDS: [Int]

    var onTap: (() -> Void)? = nil
    
    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Image(bird.imageFileName)
                .resizable()
                .scaledToFill()
                .frame(width: 80, height: 80)
                .clipShape(Circle())
                .overlay(
                    ZStack {
                        Circle().stroke(Color.black.opacity(0.05), lineWidth: 1)
                    }
                )
                .background(
                    Circle().fill(Color.white)
                )
            
            VStack(alignment: .leading, spacing: 0) {
                Text(bird.commonName)
                    .font(.customFont(font: .regular, size: 20))
                    .foregroundColor(.customBlack)
                    .lineLimit(1)
                
                Text(bird.conservationStatus)
                    .font(.customFont(font: .regular, size: 13))
                    .foregroundColor(.black)
                    .lineLimit(1)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .stroke(Color.black, lineWidth: 1)
                    )
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .padding(.trailing, 4)
            
            Spacer(minLength: 0)
            
            let isFavorite = favoritesIDS.contains(bird.id)
            
            if isFavorite {
                ZStack {
                    Circle()
                        .frame(width: 32, height: 32)
                        .foregroundStyle(.customLightGray)
                    
                    Image(systemName: isFavorite ? "heart.fill" : "hear")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.yellow)
                }
            }
        }
        .padding(8)
        .frame(maxHeight: 100)
        .background(Color(hex: "90B45A"))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        .cornerRadius(20)
        .contentShape(Rectangle())
        .overlay(content: {
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color(hex: "E1F8BD"), lineWidth: 1)
        })
        .opacity(1)
        .onTapGesture { onTap?() }
    }
}


struct RareBirdDetailView: View {
    @EnvironmentObject private var appRouter: AppRouter
    @EnvironmentObject private var tabbarService: TabbarService
    @EnvironmentObject private var markService: BirdMarkService
    
    let birdId: Int
    
    private var bird: RareBird? {
        RareBird.seed.first { $0.id == birdId }
    }
    
    @State private var favoritesIDS: [Int] = []
    
    @State private var isMarkOverlayVisible: Bool = false
    @State private var pendingSelection: BirdMarkStatus = .none
    
    var body: some View {
        ZStack(alignment: .center) {
            BackGroundView()
            
            if let bird {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .center) {
                        Image(bird.imageFileName)
                            .resizable()
                            .scaledToFill()
                            .padding(.horizontal)
                            .padding(.horizontal)
                            .cornerRadius(20)
                        
                        VStack(alignment: .leading) {
                            Text(bird.commonName)
                                .font(.customFont(font: .regular, size: 36))
                                .foregroundStyle(.customBlack)
                                .lineLimit(2)
                                .minimumScaleFactor(0.5)
                                .lineSpacing(0)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            HStack(spacing: 8) {
                                Text("Vulnerable")
                                    .font(.customFont(font: .regular, size: 16))
                                    .foregroundStyle(.customBlack)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Capsule().fill(Color.yellow))
                                
                                let current = markService.status(forKey: bird.imageFileName)
                                if current != .none {
                                    HStack(spacing: 6) {
                                        Image(current == .met ? "selected" : "unselected")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 22, height: 22)
                                        Text(current == .met ? "Met" : "Want to find")
                                            .font(.customFont(font: .regular, size: 16))
                                            .foregroundStyle(.customBlack)
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Capsule().fill(Color.white))
                                    .onTapGesture { showMarkOverlay(with: current) }
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 0) {
                                Text("Description")
                                    .font(.customFont(font: .regular, size: 16))
                                    .foregroundStyle(.customBlack.opacity(0.5))
                                Text(bird.summary)
                                    .font(.customFont(font: .regular, size: 20))
                                    .foregroundStyle(.customBlack)
                                    .lineSpacing(0)
                            }
                            .padding(.top, 16)
                            
                            VStack(alignment: .leading, spacing: 0) {
                                Text("Range")
                                    .font(.customFont(font: .regular, size: 16))
                                    .foregroundStyle(.customBlack.opacity(0.5))
                                Text(bird.habitat)
                                    .font(.customFont(font: .regular, size: 20))
                                    .foregroundStyle(.customBlack)
                                    .lineSpacing(0)
                            }
                            .padding(.top, 16)
                        }
                        
                        Button {
                            showMarkOverlay(with: .none)
                        } label: {
                            Text("Mark as")
                                .font(.customFont(font: .regular, size: 25))
                                .foregroundStyle(.customBlack)
                                .frame(maxWidth: .infinity, minHeight: 64)
                                .background(isMarkButtonEnabled ? Color.customLightOrange : Color.customLightGray.opacity(0.6))
                                .clipShape(Capsule())
                                .padding(.horizontal)
                        }
                        .disabled(!isMarkButtonEnabled)
                    }
                    .padding(.top, 20)
                }
                .padding(.horizontal)
            } else {
                Text("Bird not found")
                    .font(.customFont(font: .regular, size: 20))
                    .foregroundStyle(.customBlack)
            }
        }
        .onAppear {
            loadIDS()
            tabbarService.isTabbarVisible = false
        }
        .overlay(
            Group {
                if isMarkOverlayVisible, let bird {
                    ZStack(alignment: .center) {
                        Color.black.opacity(0.35)
                            .ignoresSafeArea()
                            .onTapGesture { isMarkOverlayVisible = false }
                        
                        VStack(alignment: .center, spacing: 4) {
                            HStack {
                                Spacer()
                                Button {
                                    isMarkOverlayVisible = false
                                } label: {
                                    Image(systemName: "xmark")
                                        .foregroundStyle(.customBlack)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.top, 6)
                            
                            Text("Mark as")
                                .font(.customFont(font: .regular, size: 22))
                                .foregroundStyle(.customBlack)
                            
                            HStack(spacing: 12) {
                                markOption(status: .met, title: "Met")
                                markOption(status: .wantToFind, title: "Want to find")
                            }
                            .padding(.horizontal)
                            
                            Button {
                                confirmSelection(for: bird.id)
                            } label: {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundStyle(pendingSelection == .none ? .gray : .yellow)
                            }
                            .buttonStyle(.plain)
                            .padding(.bottom, 8)
                        }
                        .padding(16)
                        .frame(maxWidth: 320)
                        .background(Color(hex: "90B45A"))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: .black.opacity(0.2), radius: 18, x: 0, y: 8)
                        .onAppear {
                            pendingSelection = markService.status(forKey: bird.imageFileName)
                        }
                    }
                }
            }
        )
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                BackButtonView {
                    if !appRouter.catalogRoute.isEmpty {
                        appRouter.catalogRoute.removeLast()
                    }
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    changeStatus()
                } label: {
                    HStack(alignment: .center, spacing: 4) {
                        Circle()
                            .frame(width: 32, height: 32, alignment: .center)
                            .foregroundStyle(.white)
                            .overlay {
                                let isFavorite = favoritesIDS.contains(bird?.id ?? 0)
                                
                                Image(systemName: isFavorite ? "heart.fill" : "heart")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(.yellow)
                            }
                    }
                }
            }
        }
    }
    
    private func loadIDS() {
        let userDefaults = UserDefaults.standard
        let key = "IDs"
        
        if let data = userDefaults.data(forKey: key),
           let model = try? JSONDecoder().decode(IDSModel.self, from: data) {
            self.favoritesIDS = model.ids
        }
    }
    
    private func changeStatus() {
        let userDefaults = UserDefaults.standard
        let key = "IDs"
        
        if let data = userDefaults.data(forKey: key),
           var model = try? JSONDecoder().decode(IDSModel.self, from: data) {
            if let historyIDIndex = model.ids.firstIndex(where: { $0 == birdId }),
               let favoritesIndex = favoritesIDS.firstIndex(where: { $0 == birdId }) {
                model.ids.remove(at: historyIDIndex)
                favoritesIDS.remove(at: historyIDIndex)
                let data = try? JSONEncoder().encode(model)
                userDefaults.set(data, forKey: key)
            } else {
                favoritesIDS.append(birdId)
                model.ids.append(birdId)
                let data = try? JSONEncoder().encode(model)
                userDefaults.set(data, forKey: key)
            }
        } else {
            var newModel = IDSModel()
            newModel.ids.append(birdId)
            let data = try? JSONEncoder().encode(newModel)
            userDefaults.set(data, forKey: key)
            favoritesIDS.append(birdId)
        }
    }
}

extension RareBirdDetailView {
    private var isMarkButtonEnabled: Bool {
        guard let bird else { return false }
        return markService.status(forKey: bird.imageFileName) == .none
    }
    
    private func showMarkOverlay(with preselect: BirdMarkStatus) {
        pendingSelection = preselect == .none ? .met : preselect
        isMarkOverlayVisible = true
    }
    
    private func confirmSelection(for birdId: Int) {
        guard pendingSelection != .none else { return }
        if let bird { markService.setStatus(pendingSelection, forKey: bird.imageFileName) }
        isMarkOverlayVisible = false
    }
    
    @ViewBuilder
    private func markOption(status: BirdMarkStatus, title: String) -> some View {
        let isSelected = pendingSelection == status
        VStack(spacing: 8) {
            Image(status == .met ? "selected" : "unselected")
                .resizable()
                .scaledToFit()
                .frame(width: 92, height: 92)
            Text(title)
                .font(.customFont(font: .regular, size: 14))
                .foregroundStyle(.customBlack)
        }
        .padding(12)
        .frame(width: 150, height: 150)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isSelected ? Color.customLightOrange : Color.clear, lineWidth: 3)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .onTapGesture { pendingSelection = status }
    }
}
