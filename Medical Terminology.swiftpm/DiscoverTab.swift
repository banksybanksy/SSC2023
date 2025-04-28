import SwiftUI
import Combine

enum ToastType {
    case add, remove, none, move, study
}

struct Toast: Identifiable {
    let id: UUID?
    let message: String
    let toastType: ToastType
    let boldWords: [String]
    let timestamp: Date
    
    init(message: String, toastType: ToastType, boldWords: [String] = [], id: UUID? = nil) {
        self.message = message
        self.toastType = toastType
        self.boldWords = boldWords
        self.id = id ?? UUID()
        self.timestamp = Date()
    }
}

struct ToastAlert: View {
    @Binding var toast: Toast?
    @Environment(\.colorScheme) var colorScheme
    
    private var backgroundColor: Color {
        colorScheme == .light ? Color.white.opacity(0.95) : Color(.systemBackground).opacity(0.95)
    }
    
    var body: some View {
        HStack {
            if let toast = toast {
                Text(toast.message)
                    .font(.system(size: 17))
                    .foregroundColor(.primary)
                    .bold()
                    .padding(.vertical, 10)
                    .padding(.horizontal, 15)
                    .background(backgroundColor)
                    .cornerRadius(10)
                    .shadow(radius: 3)
            }
        }
        .padding(.bottom, 10)
    }
}


// Accessible arrays for Learned and Studied
class LearnedAndStudiedTerms: ObservableObject {
    @Published var learnedTerms: Set<String> = []
    @Published var studiedTerms: Set<String> = []
}

struct DiscoverTab: View {
    let anatomyTerms = AnatomyTerms.allAnatomyTerms
    @EnvironmentObject var learnedAndStudiedTerms: LearnedAndStudiedTerms
    let colors = [Color.blue, Color.red, Color.orange, Color.indigo]
    @State private var toasts: [Toast] = []
    @State private var showToast: Bool = false
    @State private var learnMoreTerms: [String] = []
    @State private var dailyDoseInfo: (key: String, value: (function: String, latinRoot: String, region: String))?
    let generateHapticFeedback: () -> Void
    @State private var initialLaunch = true
    @State private var dailyDoseTimer: Timer?
    @State private var isFirstLoad = true
    
    init(generateHapticFeedback: @escaping () -> Void) {
        self.generateHapticFeedback = generateHapticFeedback
        if let dailyDoseKey = UserDefaults.standard.string(forKey: "dailyDoseKey") {
            self._dailyDoseInfo = State(initialValue: (key: dailyDoseKey, value: anatomyTerms[dailyDoseKey, default: (function: "Test function", latinRoot: "Test root", region: "Test region")]))
        }
    }

    
    private func loadLearnMoreTerms() {
        learnMoreTerms = Array(repeating: "", count: 4).map { _ in anatomyTerms.randomElement()?.key ?? "" }
    }
    
    private func updateDailyDose() {
        let newDailyDoseKey = anatomyTerms.randomElement()?.key ?? ""
        UserDefaults.standard.set(newDailyDoseKey, forKey: "dailyDoseKey")
        dailyDoseInfo = (key: newDailyDoseKey, value: anatomyTerms[newDailyDoseKey]!)
    }
    
    private func updateDailyDoseIfNeeded() {
        let now = Date()
        let calendar = Calendar.current
        let currentMidnight = calendar.startOfDay(for: now)
        let lastUpdateKey = "lastDailyDoseUpdate"
        let lastUpdate = UserDefaults.standard.object(forKey: lastUpdateKey) as? Date ?? currentMidnight
        
        if calendar.compare(currentMidnight, to: lastUpdate, toGranularity: .day) == .orderedDescending {
            updateDailyDose()
            UserDefaults.standard.set(currentMidnight, forKey: lastUpdateKey)
        } else {
            if let dailyDoseKey = UserDefaults.standard.string(forKey: "dailyDoseKey") {
                dailyDoseInfo = (key: dailyDoseKey, value: anatomyTerms[dailyDoseKey]!)
            } else {
                updateDailyDose()
            }
        }
    }
    
    private func handleLearnedAction(for term: String) {
        generateHapticFeedback()
        
        if learnedAndStudiedTerms.studiedTerms.contains(term) {
            learnedAndStudiedTerms.studiedTerms.remove(term)
        }
        
        learnedAndStudiedTerms.learnedTerms.insert(term)
        
        withAnimation {
            let newToast = Toast(message: "Added to Learned", toastType: .move, boldWords: ["Learned"])
            toasts.append(newToast)
            showToast = true
        }
    }
    
    private func handleStudiedAction(for term: String) {
        generateHapticFeedback()
        
        if learnedAndStudiedTerms.learnedTerms.contains(term) {
            learnedAndStudiedTerms.learnedTerms.remove(term)
        }
        
        learnedAndStudiedTerms.studiedTerms.insert(term)
        
        withAnimation {
            let newToast = Toast(message: "Added to Still Studying", toastType: .move, boldWords: ["Still Studying"])
            toasts.append(newToast)
            showToast = true
        }
    }
    
    private func startDailyDoseTimer() {
        let now = Date()
        let calendar = Calendar.current
        let nextMidnight = calendar.nextDate(after: now, matching: DateComponents(hour: 0), matchingPolicy: .nextTime)!
        let timeInterval = nextMidnight.timeIntervalSince(now)
        
        dailyDoseTimer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false) { _ in
            updateDailyDoseIfNeeded()
            startDailyDoseTimer()
        }
    }
    
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ScrollView {
                    VStack {
                        Text("Daily Dose")
                            .font(.title2)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                            .padding(.top, 30)
                        
                        if let dailyDoseInfo = dailyDoseInfo {
                            let dailyDoseColor = Color.green
                            
                            Flashcard(geometry: geometry,
                                      color: dailyDoseColor,
                                      region: dailyDoseInfo.value.region,
                                      term: dailyDoseInfo.key,
                                      regionLabel: "Region:",
                                      function: dailyDoseInfo.value.function,
                                      latinRoot: dailyDoseInfo.value.latinRoot,
                                      learnedAction: {
                                handleLearnedAction(for: dailyDoseInfo.key)
                            },
                                      studiedAction: {
                                handleStudiedAction(for: dailyDoseInfo.key)
                            })
                            .id(dailyDoseInfo.key)
                            .environmentObject(learnedAndStudiedTerms)
                            .padding(.bottom, 20)
                        }
                        
                        Text("Learn More")
                            .font(.title2)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                        
                        VStack {
                            ForEach(Array(learnMoreTerms.enumerated()), id: \.offset) { index, term in
                                let color = colors[index % colors.count]
                                let termInfo = anatomyTerms[term]!
                                
                                Flashcard(geometry: geometry,
                                          color: color,
                                          region: termInfo.region,
                                          term: term,
                                          regionLabel: "Region:",
                                          function: termInfo.function,
                                          latinRoot: termInfo.latinRoot,
                                          learnedAction: {
                                    handleLearnedAction(for: term)
                                },
                                          studiedAction: {
                                    handleStudiedAction(for: term)
                                })
                                .id(term)
                                .environmentObject(learnedAndStudiedTerms)
                                .padding(.bottom, 20)
                            }
                            Spacer(minLength: 60)
                        }
                    }
                }
                .background(Color("Background"))
                .edgesIgnoringSafeArea(.bottom)
                .navigationBarTitle("Discover")
                .onAppear {
                    if isFirstLoad {
                        updateDailyDoseIfNeeded()
                        loadLearnMoreTerms()
                        startDailyDoseTimer()
                        isFirstLoad = false
                    }
                    
                    if dailyDoseInfo == nil, let dailyDoseKey = UserDefaults.standard.string(forKey: "dailyDoseKey") {
                        dailyDoseInfo = (key: dailyDoseKey, value: anatomyTerms[dailyDoseKey]!)
                    }
                }
            }
            .overlay(
                VStack {
                    Spacer()
                    if showToast, let lastToast = toasts.last {
                        ToastAlert(toast: .constant(lastToast))
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .animation(.easeInOut(duration: 0.5), value: showToast)
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    withAnimation {
                                        showToast = false
                                        if let lastToast = toasts.last {
                                            toasts.removeAll { $0.id == lastToast.id }
                                        }
                                    }
                                }
                            }
                    }
                }
            )
        }
    }
}
     
// View that displays the anatomy term and associated information
struct Flashcard: View {
    var geometry: GeometryProxy
    var color: Color
    var region: String
    var term: String
    var regionLabel: String
    var function: String
    var latinRoot: String
    var learnedAction: () -> Void
    var studiedAction: () -> Void
    @EnvironmentObject var learnedAndStudiedTerms: LearnedAndStudiedTerms
    
    @State private var showFunction = false
    @State private var learnedSelected = false
    @State private var studiedSelected = false
    
    var body: some View {
        Button(action: {
            generateHapticFeedback(style: .light)
            withAnimation(showFunction ? .interpolatingSpring(mass: 1, stiffness: 100, damping: 10, initialVelocity: 0) : .interpolatingSpring(mass: 1, stiffness: 100, damping: 10, initialVelocity: 0)) {
                showFunction.toggle()
            }
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .foregroundColor(color)
                    .frame(height: showFunction ? 380 : 200)
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                
                VStack {
                    Spacer()
                    
                    if showFunction {
                        functionInfo
                    } else {
                        termAndRegion
                    }
                    
                    Spacer()
                    
                    if showFunction {
                        toolbar.padding(.bottom, 25)
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // View containing the anatomy term and region label
    private var termAndRegion: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .foregroundColor(Color.white.opacity(0.8))
                .frame(width: 285, height: 100)
                .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 5)
            
            VStack(spacing: 5) {
                Text(term)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                Text(regionLabel + " " + region)
                    .font(.body)
                    .foregroundColor(.black)
                    .padding(.bottom, 5)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
            }
        }
    }
    
    // View containing the anatomy term, region label, Latin root, and function information
    private var functionInfo: some View {
        VStack(spacing: 5) {
            Text(term)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
            Text(regionLabel + " " + region)
                .font(.body)
                .foregroundColor(.white)
                .padding(.bottom, 5)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
            Text("Latin Root: \(latinRoot)")
                .font(.body)
                .foregroundColor(.white)
                .padding(.bottom, 5)
            Text("Function: \(function)")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
                .padding(.bottom, 5)
        }
        .padding(.horizontal, 50)
    }
    
    // Haptic Feedback
    func generateHapticFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    // "Learned" and "Still Studying" buttons
    private var toolbar: some View {
        HStack {
            Spacer()
            
            // "Learned" button action
            Button(action: {
                generateHapticFeedback(style: .medium)
                if learnedAndStudiedTerms.studiedTerms.contains(term) {
                    learnedAndStudiedTerms.studiedTerms.remove(term)
                }
                if !learnedAndStudiedTerms.learnedTerms.contains(term) {
                    learnedSelected = true
                    studiedSelected = false
                    learnedAction()
                }
            }) {
                Label("Learned", systemImage: learnedSelected ? "checkmark.circle.fill" : "checkmark.circle")
            }
            Spacer()
            
            // "Still Studying" button action
            Button(action: {
                generateHapticFeedback(style: .medium)
                if learnedAndStudiedTerms.learnedTerms.contains(term) {
                    learnedAndStudiedTerms.learnedTerms.remove(term)
                }
                if !learnedAndStudiedTerms.studiedTerms.contains(term) {
                    studiedSelected = true
                    learnedSelected = false
                    studiedAction()
                }
            }) {
                Label("Still Studying", systemImage: studiedSelected ? "book.fill" : "book")
            }
            Spacer()
        }
        .font(.system(size: 14, weight: .semibold))
        .foregroundColor(.white)
    }
}

// View that displays the region and term for a flashcard
struct WordOverlay: View {
    let region: String 
    let term: String
    let regionLabel: String
    
    var body: some View {
        // Vertical stack containing the term and region labels
        VStack(alignment: .center, spacing: 5) {
            Text(term)
                .font(.system(size: 20, weight: .bold))
                .multilineTextAlignment(.center)
                .lineLimit(nil)
            Text("\(regionLabel) \(region)")
                .font(.system(size: 16))
                .multilineTextAlignment(.center)
                .lineLimit(nil)
        }
        .padding(10)
        .cornerRadius(10)
    }
}

