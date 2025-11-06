import SwiftUI

struct HistoryMainView: View {
    
    @EnvironmentObject private var appRouter: AppRouter
    @EnvironmentObject private var tabbarService: TabbarService
    @EnvironmentObject private var observationService: ObservationService
    
    @State private var isCalendarPresented: Bool = false
    @State private var selectedDate: Date = Date()
    @State private var selectedObservation: PersonalObservation? = nil
    
    private var uniqueTitles: [String] {
        observationService.observations.map { $0.id.uuidString }
    }
    
    private var observationsForSelectedDate: [PersonalObservation] {
        let cal = Calendar.current
        return observationService.observations.filter { cal.isDate($0.date, inSameDayAs: selectedDate) }
            .sorted(by: { $0.date > $1.date })
    }
    
    private var weeklyCounts: [Int] {
        var counts = Array(repeating: 0, count: 7)
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        for obs in observationService.observations {
            let weekday = calendar.component(.weekday, from: obs.date)
            let index = (weekday + 5) % 7
            counts[index] += 1
        }
        return counts
    }
    
    var body: some View {
        @ObservedObject var appRouter = appRouter
        
        NavigationStack(path: $appRouter.historyRoute) {
            ZStack(alignment: .center) {
                BackGroundView()
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("History and statistics")
                        .font(.customFont(font: .regular, size: 32))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    if observationService.observations.isEmpty {
                        Spacer()
                        
                        VStack(spacing: 16) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 32)
                                    .fill(Color(hex: "E1F8BD"))
                                VStack(spacing: 16) {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 80, weight: .bold))
                                        .foregroundStyle(Color.orange)
                                    Text("There’s nothing here yet..")
                                        .font(.customFont(font: .regular, size: 20))
                                        .foregroundStyle(.customBlack)
                                }
                                .padding(.vertical, 40)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 300)
                            .padding(.horizontal, 32)
                        }
                        
                        Spacer()
                    } else {
                        ScrollView(.vertical) {
                            VStack(alignment: .leading, spacing: 20) {
                                HStack(alignment: .center, spacing: 16) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Unique species")
                                            .font(.customFont(font: .regular, size: 18))
                                            .foregroundStyle(.customBlack)
                                        HStack(spacing: -12) {
                                            ForEach(observationService.observations.prefix(3)) { obs in
                                                PersonalObservationAvatar(imageFileName: obs.imageFileName)
                                            }
                                        }
                                    }
                                    Spacer()
                                    Text("\(uniqueTitles.count)")
                                        .font(.customFont(font: .regular, size: 32))
                                        .foregroundStyle(.customBlack)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 16)
                                .background(Color(hex: "90B45A"))
                                .cornerRadius(20)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color(hex: "E1F8BD"), lineWidth: 1)
                                }
                                
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Activity chart")
                                        .font(.customFont(font: .regular, size: 18))
                                        .foregroundStyle(.customBlack)
                                    FakeLineChart(counts: weeklyCounts)
                                        .frame(height: 140)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 16)
                                .background(Color(hex: "90B45A"))
                                .clipShape(RoundedRectangle(cornerRadius: 28))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 28)
                                        .stroke(Color(hex: "E1F8BD"), lineWidth: 1)
                                }
                                
                                HStack(alignment: .center) {
                                    Text("Chronology of\nobservations")
                                        .font(.customFont(font: .regular, size: 22))
                                        .foregroundStyle(.customBlack)
                                        .lineLimit(2)
                                    Spacer()
                                    Button {
                                        isCalendarPresented = true
                                    } label: {
                                        ZStack {
                                            Circle().fill(Color(hex: "90B45A"))
                                            Image(systemName: "calendar")
                                                .foregroundStyle(.yellow)
                                        }
                                        .frame(width: 44, height: 44)
                                    }
                                    .buttonStyle(.plain)
                                }
                                
                                VStack(spacing: 16) {
                                    if observationsForSelectedDate.isEmpty {
                                        Text("No observations on this date")
                                            .font(.customFont(font: .regular, size: 16))
                                            .foregroundStyle(.customBlack.opacity(0.6))
                                            .frame(maxWidth: .infinity, alignment: .center)
                                    } else {
                                        ForEach(observationsForSelectedDate) { obs in
                                            PersonalHistoryCard(observation: obs) {
                                                selectedObservation = obs
                                                observationService.selectedObservation = obs
                                                appRouter.historyRoute.append(.observationDetail)
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.top, 3)
                            .padding(.bottom, AppConfig.adaptiveTabbarBottomPadding)
                        }
                        .scrollIndicators(.hidden)
                    }
                }
                .padding(.horizontal)
                .sheet(isPresented: $isCalendarPresented) {
                    VStack {
                        DatePicker("", selection: $selectedDate, displayedComponents: [.date])
                            .datePickerStyle(.graphical)
                            .labelsHidden()
                            .padding()
                        Button("Done") { isCalendarPresented = false }
                            .padding(.bottom)
                    }
                    .presentationDetents([.height(420)])
                }
            }
            .onAppear {
                tabbarService.isTabbarVisible = true
            }
            .navigationDestination(for: HistoryScreen.self) { screen in
                switch screen {
                case .main:
                    EmptyView()
                case .observationDetail:
                    if let obs = selectedObservation {
                        PersonalObservationDetailView(observation: obs)
                    }
                }
            }
        }
    }
}

struct PersonalObservationAvatar: View {
    let imageFileName: String?
    @State private var image: UIImage? = nil
    
    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    Color.white.opacity(0.8)
                    Image(systemName: "photo")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.customBlack.opacity(0.4))
                }
            }
        }
        .frame(width: 40, height: 40)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.white, lineWidth: 3))
        .onAppear(perform: load)
    }
    
    private func load() {
        guard let fileName = imageFileName,
              let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let url = documents.appendingPathComponent(fileName)
        if let data = try? Data(contentsOf: url), let img = UIImage(data: data) {
            image = img
        }
    }
}

struct FakeLineChart: View {
    let counts: [Int]
    
    init(counts: [Int]) {
        self.counts = counts
    }
    
    private var labels: [String] { ["MON","TUE","WED","THU","FRI","SAT","SUN"] }
    
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let safeTopPadding: CGFloat = 8
            let safeBottomPadding: CGFloat = 30
            let verticalOffset: CGFloat = 6
            let chartHeight = max(h - safeTopPadding - safeBottomPadding, 1)
            let maxValue = max(counts.max() ?? 1, 1)
            let points = pointsFor(width: w, height: chartHeight, maxValue: maxValue)
            
            Path { path in
                guard let first = points.first else { return }
                path.move(to: CGPoint(x: first.x, y: first.y + safeTopPadding - verticalOffset))
                let smooth = smoothed(points: points)
                for segment in smooth {
                    path.addCurve(to: CGPoint(x: segment.to.x, y: segment.to.y + safeTopPadding - verticalOffset),
                                  control1: CGPoint(x: segment.c1.x, y: segment.c1.y + safeTopPadding - verticalOffset),
                                  control2: CGPoint(x: segment.c2.x, y: segment.c2.y + safeTopPadding - verticalOffset))
                }
            }
            .strokedPath(.init(lineWidth: 4, lineCap: .round, lineJoin: .round))
            .fill(Color.yellow)
            
            HStack {
                ForEach(labels, id: \.self) { label in
                    Text(label)
                        .font(.customFont(font: .regular, size: 12))
                        .foregroundStyle(.customBlack.opacity(0.7))
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
    }
    
    private func pointsFor(width: CGFloat, height: CGFloat, maxValue: Int) -> [CGPoint] {
        guard counts.count == 7 else { return [] }
        let stepX = width / 6.0
        return counts.enumerated().map { index, value in
            let ratio = CGFloat(value) / CGFloat(maxValue)
            let y = height - ratio * height
            let x = CGFloat(index) * stepX
            return CGPoint(x: x, y: y)
        }
    }
    
    private struct BezierSegment { let c1: CGPoint; let c2: CGPoint; let to: CGPoint }
    
    private func smoothed(points: [CGPoint]) -> [BezierSegment] {
        guard points.count > 1 else { return [] }
        var result: [BezierSegment] = []
        let tension: CGFloat = 0.5
        for i in 0..<(points.count - 1) {
            let p0 = i > 0 ? points[i - 1] : points[i]
            let p1 = points[i]
            let p2 = points[i + 1]
            let p3 = i + 2 < points.count ? points[i + 2] : points[i + 1]
            let d1 = CGPoint(x: (p2.x - p0.x) * tension / 6.0, y: (p2.y - p0.y) * tension / 6.0)
            let c1 = CGPoint(x: p1.x + d1.x, y: p1.y + d1.y)
            let d2 = CGPoint(x: (p3.x - p1.x) * tension / 6.0, y: (p3.y - p1.y) * tension / 6.0)
            let c2 = CGPoint(x: p2.x - d2.x, y: p2.y - d2.y)
            result.append(BezierSegment(c1: c1, c2: c2, to: p2))
        }
        return result
    }
}

private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

struct PersonalHistoryCard: View {
    let observation: PersonalObservation
    let onTap: (() -> Void)?
    
    @State private var loadedImage: UIImage? = nil
    
    init(observation: PersonalObservation, onTap: (() -> Void)? = nil) {
        self.observation = observation
        self.onTap = onTap
    }
    
    var body: some View {
        Button(action: { onTap?() }) {
            HStack(spacing: 12) {
                Group {
                    if let img = loadedImage {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                    } else {
                        ZStack {
                            Color.white.opacity(0.8)
                            Image(systemName: "photo")
                                .font(.system(size: 28, weight: .medium))
                                .foregroundStyle(.customBlack.opacity(0.4))
                        }
                    }
                }
                .frame(width: 80, height: 80)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white, lineWidth: 4))
                
                VStack(alignment: .leading, spacing: -4) {
                    Text(observation.title)
                        .font(.customFont(font: .regular, size: 22))
                        .foregroundStyle(.customBlack)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    
                    HStack(spacing: 8) {
                        Image(systemName: "calendar")
                        Text(dateString)
                            .font(.customFont(font: .regular, size: 14))
                    }
                    .foregroundStyle(.customBlack)
                    
                    HStack(spacing: 8) {
                        Image(systemName: "mappin.and.ellipse")
                        Text(observation.location)
                            .font(.customFont(font: .regular, size: 14))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .foregroundStyle(.customBlack)
                }
                Spacer()
            }
            .padding(.horizontal, 16)
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
        .onAppear(perform: loadImage)
    }
    
    private var dateString: String {
        let f = DateFormatter()
        f.dateFormat = "dd.MM.yyyy"
        return f.string(from: observation.date)
    }
    
    private func loadImage() {
        guard let fileName = observation.imageFileName,
              let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let url = documents.appendingPathComponent(fileName)
        if let data = try? Data(contentsOf: url), let img = UIImage(data: data) {
            loadedImage = img
        }
    }
}
