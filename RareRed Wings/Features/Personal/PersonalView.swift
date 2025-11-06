import SwiftUI

struct PersonalMainView: View {
    
    @EnvironmentObject private var appRouter: AppRouter
    @EnvironmentObject private var observationService: ObservationService
    @EnvironmentObject private var tabbarService: TabbarService
    
    var body: some View {
        @ObservedObject var appRouter = appRouter
        
        NavigationStack(path: $appRouter.personalRoute) {
            ZStack(alignment: .center) {
                BackGroundView()
                
                VStack(alignment: .center, spacing: 16) {
                    VStack(alignment: .center, spacing: -32) {
                        Text("Personal observation")
                            .font(.customFont(font: .regular, size: 32))
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                        Text("diary")
                            .font(.customFont(font: .regular, size: 32))
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                    }
                    
                    if observationService.hasObservations {
                        ScrollView(showsIndicators: false) {
                            LazyVStack(alignment: .leading, spacing: 12) {
                                ForEach(observationService.observations) { observation in
                                    PersonalObservationCard(observation: observation)
                                        .overlay(content: {
                                            RoundedRectangle(cornerRadius: 20)
                                                .stroke(Color(hex: "E1F8BD"), lineWidth: 1)
                                        })
                                        .onTapGesture {
                                            observationService.selectedObservation = observation
                                            appRouter.personalRoute.append(.observationDetail)
                                        }
                                }
                            }
                            .padding(.top, 3)
                        }
                    } else {
                        Spacer()
                        
                        VStack(alignment: .center, spacing: 16) {
                            RoundedRectangle(cornerRadius: 35)
                                .fill(Color(hex: "90B45A"))
                                .frame(maxWidth: 300, maxHeight: 300, alignment: .center)
                                .overlay(
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 35)
                                            .stroke(Color(hex: "E1F8BD"), lineWidth: 1)
                                        VStack(spacing: 32) {
                                            Image(systemName: "xmark")
                                                .font(.system(size: 64, weight: .heavy))
                                                .foregroundStyle(.orange)
                                            Text("There's nothing here yet..")
                                                .font(.customFont(font: .regular, size: 20))
                                                .foregroundStyle(.customBlack)
                                        }
                                    }
                                )
                        }
                        
                        Spacer()
                    }
                    
                    Button {
                        observationService.selectedObservation = nil
                        appRouter.personalRoute.append(.addObservation)
                    } label: {
                        Text("Add Bird")
                            .font(.customFont(font: .regular, size: 25))
                            .foregroundStyle(.customBlack)
                            .frame(maxWidth: .infinity, minHeight: 64)
                            .background(.customLightOrange)
                            .clipShape(Capsule())
                            .baselineOffset(-2)
                    }
                    .padding(.bottom, AppConfig.adaptiveTabbarBottomPadding + 4)
                }
                .padding(.horizontal)
            }
            .onAppear {
                tabbarService.isTabbarVisible = true
            }
            .navigationDestination(for: PersonalScreen.self) { screen in
                switch screen {
                case .main:
                    PersonalMainView()
                case .addObservation:
                    AddObservationView()
                case .observationDetail:
                    if let selected = observationService.selectedObservation {
                        PersonalObservationDetailView(observation: selected)
                    }
                }
            }
        }
    }
}

struct PersonalObservationCard: View {
    let observation: PersonalObservation
    @State private var loadedImage: UIImage? = nil
    
    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            if let loadedImage = loadedImage {
                Image(uiImage: loadedImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
                    .overlay(
                        Circle().stroke(Color.black.opacity(0.05), lineWidth: 1)
                    )
                    .background(
                        Circle().fill(Color.white)
                    )
            } else {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "camera.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.gray)
                }
                .overlay(
                    Circle().stroke(Color.black.opacity(0.05), lineWidth: 1)
                )
            }
            
            VStack(alignment: .leading, spacing: 0) {
                Text(observation.title)
                    .font(.customFont(font: .regular, size: 20))
                    .foregroundColor(.customBlack)
                    .lineLimit(1)
                
                Text(observation.location)
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
            .padding(.trailing, 4)
            
            Spacer(minLength: 0)
        }
        .padding(8)
        .background(Color(hex: "90B45A"))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        .onAppear {
            loadImageFromDocuments()
        }
    }
    
    // MARK: - Image Loading
    
    private func loadImageFromDocuments() {
        guard let imageFileName = observation.imageFileName,
              let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        let fileURL = documentsPath.appendingPathComponent(imageFileName)
        
        if let data = try? Data(contentsOf: fileURL),
           let image = UIImage(data: data) {
            loadedImage = image
        }
    }
}

// MARK: - Preview

#Preview("LightEN") {
    PersonalObservationCard(
        observation: PersonalObservation(
            title: "Common Loon",
            location: "Lake near forest",
            notes: "Beautiful bird with distinctive calls",
            date: Date(),
            weather: .clear,
            habitat: .water
        )
    )
    .padding()
}

import PhotosUI

struct AddObservationView: View {
    @EnvironmentObject private var appRouter: AppRouter
    @EnvironmentObject private var observationService: ObservationService
    @EnvironmentObject private var tabbarService: TabbarService
    
    @State private var title: String = ""
    @State private var location: String = ""
    @State private var notes: String = ""
    @State private var selectedDate: Date = Date()
    @State private var selectedWeather: WeatherCondition? = nil
    @State private var selectedHabitat: HabitatType? = nil
    @State private var selectedImage: PhotosPickerItem? = nil
    @State private var imageData: Data? = nil
    @FocusState private var isEditing: Bool
    
    @State private var isEditMode: Bool = false
    
    private var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        selectedWeather != nil &&
        selectedHabitat != nil
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            BackGroundView()
            
            ScrollView {
                VStack(alignment: .center, spacing: 20) {
                    
                    PhotosPicker(selection: $selectedImage, matching: .images) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "90B45A"))
                                .frame(width: 120, height: 120)
                                .overlay {
                                    Circle()
                                        .stroke(Color(hex: "E1F8BD"), lineWidth: 1)
                                }
                            
                            if let imageData, let uiImage = UIImage(data: imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                            } else {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 40))
                                    .foregroundStyle(.gray)
                            }
                        }
                    }
                    .onChange(of: selectedImage) { newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                imageData = data
                            }
                        }
                    }
                    
                    DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .background(Color(hex: "E1F8BD"))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Title")
                                .font(.customFont(font: .regular, size: 16))
                                .foregroundStyle(.customBlack)
                            TextField("Write here..", text: $title)
                                .font(.customFont(font: .regular, size: 16))
                                .padding()
                                .background(Color(hex: "90B45A"))
                                .clipShape(Capsule())
                                .focused($isEditing)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Location")
                                .font(.customFont(font: .regular, size: 16))
                                .foregroundStyle(.customBlack)
                            TextField("Write here..", text: $location)
                                .font(.customFont(font: .regular, size: 16))
                                .padding()
                                .background(Color(hex: "90B45A"))
                                .clipShape(Capsule())
                                .focused($isEditing)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes")
                                .font(.customFont(font: .regular, size: 16))
                                .foregroundStyle(.customBlack)
                            TextField("Write here..", text: $notes, axis: .vertical)
                                .font(.customFont(font: .regular, size: 16))
                                .lineLimit(1...5)
                                .padding()
                                .background(Color(hex: "90B45A"))
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .focused($isEditing)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Weather")
                                .font(.customFont(font: .regular, size: 16))
                                .foregroundStyle(.customBlack)
                            
                            FlowRows(spacing: 8, rowSpacing: 8) {
                                ForEach(WeatherCondition.allCases, id: \.self) { weather in
                                    Button {
                                        selectedWeather = weather
                                    } label: {
                                        HStack(spacing: 6) {
                                            Text(weatherEmoji(weather))
                                            Text(weather.displayName)
                                                .font(.customFont(font: .regular, size: 14))
                                                .foregroundStyle(.customBlack)
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.8)
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background((selectedWeather == weather ? Color.customLightOrange : Color(hex: "90B45A")))
                                        .clipShape(Capsule())
                                        .contentShape(Capsule())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Habitat")
                                .font(.customFont(font: .regular, size: 16))
                                .foregroundStyle(.customBlack)
                            
                            FlowRows(spacing: 8, rowSpacing: 8) {
                                ForEach(HabitatType.allCases, id: \.self) { habitat in
                                    Button {
                                        selectedHabitat = habitat
                                    } label: {
                                        HStack(spacing: 6) {
                                            Text(habitat.emoji)
                                            Text(habitat.displayName)
                                                .font(.customFont(font: .regular, size: 14))
                                                .foregroundStyle(.customBlack)
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.8)
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background((selectedHabitat == habitat ? Color.customLightOrange : Color(hex: "90B45A")))
                                        .clipShape(Capsule())
                                        .contentShape(Capsule())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    
                    Button {
                        saveObservation()
                    } label: {
                        Text("Done")
                            .font(.customFont(font: .regular, size: 26))
                            .foregroundStyle(.customBlack)
                            .frame(maxWidth: .infinity, minHeight: 70)
                            .background(isFormValid ? Color.customLightOrange : Color.customLightGray.opacity(0.6))
                            .clipShape(Capsule())
                    }
                    .disabled(!isFormValid)
                    .padding(.top, 20)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
                .background(
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture { isEditing = false }
                )
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .onAppear {
            tabbarService.isTabbarVisible = false
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                BackButtonView {
                    if !appRouter.personalRoute.isEmpty {
                        appRouter.personalRoute.removeLast()
                    }
                }
            }
        }
        .onAppear {
            if let obs = observationService.selectedObservation {
                if !isEditMode {
                    isEditMode = true
                    title = obs.title
                    location = obs.location
                    notes = obs.notes
                    selectedDate = obs.date
                    selectedWeather = obs.weather
                    selectedHabitat = obs.habitat
                    if let file = obs.imageFileName,
                       let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                        let url = docs.appendingPathComponent(file)
                        if let data = try? Data(contentsOf: url) {
                            imageData = data
                        }
                    }
                }
            }
        }
    }
        
    private func saveObservation() {
        guard isFormValid,
              let weather = selectedWeather,
              let habitat = selectedHabitat else { return }
        
        var newImageFileName: String? = nil
        if let imageData = imageData, selectedImage != nil {
            newImageFileName = saveImageToDocuments(imageData)
        }
        
        if isEditMode, var existing = observationService.selectedObservation {
            existing = PersonalObservation(
                id: existing.id,
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                location: location.trimmingCharacters(in: .whitespacesAndNewlines),
                notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
                date: selectedDate,
                weather: weather,
                habitat: habitat,
                imageFileName: newImageFileName ?? existing.imageFileName
            )
            observationService.updateObservation(existing)
        } else {
            let observation = PersonalObservation(
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                location: location.trimmingCharacters(in: .whitespacesAndNewlines),
                notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
                date: selectedDate,
                weather: weather,
                habitat: habitat,
                imageFileName: newImageFileName
            )
            observationService.addObservation(observation)
        }
        
        if !appRouter.personalRoute.isEmpty {
            appRouter.personalRoute.removeLast()
        }
    }
    
    private func saveImageToDocuments(_ data: Data) -> String? {
        let fileName = "\(UUID().uuidString).jpg"
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let fileURL = documentsPath.appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL)
            return fileName
        } catch {
            print("Error saving image: \(error)")
            return nil
        }
    }
    
    // MARK: - Helpers
    private func weatherEmoji(_ weather: WeatherCondition) -> String {
        switch weather {
        case .clear: return "☀️"
        case .partlyCloudy: return "🌤️"
        case .cloudy: return "☁️"
        case .rain: return "🌧️"
        case .snow: return "❄️"
        case .fog: return "🌫️"
        }
    }
}
struct FlowRows: Layout {
    var spacing: CGFloat = 8
    var rowSpacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var rowHeight: CGFloat = 0
        
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth {
                currentX = 0
                currentY += rowHeight + rowSpacing
                rowHeight = 0
            }
            rowHeight = max(rowHeight, size.height)
            currentX += size.width + spacing
        }
        return CGSize(width: maxWidth, height: currentY + rowHeight)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let maxWidth = bounds.width
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var rowHeight: CGFloat = 0
        
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth {
                currentX = 0
                currentY += rowHeight + rowSpacing
                rowHeight = 0
            }
            let origin = CGPoint(x: bounds.minX + currentX, y: bounds.minY + currentY)
            view.place(at: origin, proposal: ProposedViewSize(width: size.width, height: size.height))
            currentX += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

import SwiftUI

// MARK: - Personal Observation Detail View

struct PersonalObservationDetailView: View {
    @EnvironmentObject private var appRouter: AppRouter
    @EnvironmentObject private var tabbarService: TabbarService
    @EnvironmentObject private var observationService: ObservationService
    @Environment(\.dismiss) private var dismiss
    
    let observation: PersonalObservation
    
    @State private var uiImage: UIImage? = nil
    @State private var showDeleteAlert: Bool = false
    @State private var currentObservation: PersonalObservation
    
    init(observation: PersonalObservation) {
        self.observation = observation
        self._currentObservation = State(initialValue: observation)
    }
    
    var body: some View {
        ZStack(alignment: .center) {
            BackGroundView()
            
            VStack {
                // Картинка
                imageHeader
                
                ScrollView(.vertical) {
                    VStack(alignment: .leading, spacing: 16) {
                        // Локация
                        HStack(spacing: 8) {
                            Image(systemName: "mappin.and.ellipse")
                            Text(currentObservation.location)
                                .font(.customFont(font: .regular, size: 18))
                                .foregroundStyle(.customBlack)
                        }
                        
                        // Дата
                        HStack(spacing: 8) {
                            Image(systemName: "calendar")
                            Text(dateString)
                                .font(.customFont(font: .regular, size: 18))
                                .foregroundStyle(.customBlack)
                        }
                        
                        // Погода/местность чипы
                        HStack(spacing: 12) {
                            HStack(spacing: 6) {
                                Text(weatherEmoji(currentObservation.weather))
                                Text(currentObservation.weather.displayName)
                                    .font(.customFont(font: .regular, size: 14))
                                    .foregroundStyle(.customBlack)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.customLightOrange.opacity(0.25))
                            .clipShape(Capsule())
                            
                            HStack(spacing: 6) {
                                Text(currentObservation.habitat.emoji)
                                Text(currentObservation.habitat.displayName)
                                    .font(.customFont(font: .regular, size: 14))
                                    .foregroundStyle(.customBlack)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.customLightOrange.opacity(0.25))
                            .clipShape(Capsule())
                        }
                        
                        // Notes
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Notes")
                                .font(.customFont(font: .regular, size: 16))
                                .foregroundStyle(.customBlack.opacity(0.5))
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text(currentObservation.notes)
                                .font(.customFont(font: .regular, size: 20))
                                .foregroundStyle(.customBlack)
                        }
                    }
                    .padding()
                    .background(Color(hex: "90B45A"))
                    .cornerRadius(20)
                    .overlay {
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(Color(hex:"E1F8BD"), lineWidth: 1)
                    }
                }
                .scrollIndicators(.hidden)
            }
            .padding(.horizontal)
        }
        .onAppear {
            tabbarService.isTabbarVisible = false
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                BackButtonView {
                    // Универсальный возврат через dismiss
                    dismiss()
                }
            }
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    // Edit -> push AddObservationView с предзаполненными данными
                    observationService.selectedObservation = currentObservation
                    appRouter.personalRoute.append(.addObservation)
                } label: {
                    Image("edit")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32, height: 32, alignment: .center)
                }
                .buttonStyle(.plain)
                
                Button { showDeleteAlert = true } label: {
                    Image("deleteView")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32, height: 32, alignment: .center)
                }
                .buttonStyle(.plain)
            }
        }
        .alert("Delete", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                observationService.removeObservation(currentObservation)
                dismiss()
            }
        } message: {
            Text("Are you sure you want to remove this bird?")
        }
        .onAppear(perform: loadImage)
        .onReceive(observationService.$observations) { _ in
            // Обновляем данные при изменении в ObservationService
            if let updated = observationService.observations.first(where: { $0.id == currentObservation.id }) {
                currentObservation = updated
                loadImage()
            }
        }
    }
    
    private var imageHeader: some View {
        Group {
            if let uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 260)
                    .padding(.horizontal)
                    .clipped()
                    .cornerRadius(25)
            } else {
                Rectangle()
                    .fill(Color.white.opacity(0.6))
                    .frame(height: 260)
            }
        }
    }
    
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter.string(from: currentObservation.date)
    }
    
    private func loadImage() {
        guard let fileName = currentObservation.imageFileName,
              let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let url = documents.appendingPathComponent(fileName)
        if let data = try? Data(contentsOf: url), let img = UIImage(data: data) {
            uiImage = img
        }
    }
    
    // MARK: - Helpers
    private func weatherEmoji(_ weather: WeatherCondition) -> String {
        switch weather {
        case .clear: return "☀️"
        case .partlyCloudy: return "🌤️"
        case .cloudy: return "☁️"
        case .rain: return "🌧️"
        case .snow: return "❄️"
        case .fog: return "🌫️"
        }
    }
}

// MARK: - Preview

#Preview("LightEN") {
    NavigationStack {
        PersonalObservationDetailView(
            observation: PersonalObservation(
                title: "Syrian Starling",
                location: "Forest near Lake Como, Italy",
                notes: "Today I spotted an ",
                date: Date(),
                weather: .clear,
                habitat: .forest,
                imageFileName: nil
            )
        )
        .environmentObject(AppRouter.shared)
        .environmentObject(TabbarService.shared)
        .environmentObject(ObservationService.shared)
    }
}


