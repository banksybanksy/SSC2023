import SwiftUI
import ConfettiSwiftUI

struct ChallengeView: View {
    let colors = [Color.teal]
    let quizTypes = ["Multiple Choice"]
    let anatomyTerms = AnatomyTerms.allAnatomyTerms
    @State private var showQuiz: Bool = false
    @State private var learnedAndStudiedTerms = LearnedAndStudiedTerms()
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ScrollView {
                    VStack {
                        Spacer()
                        
                        VStack(spacing: 30) {
                            NavigationLink("", destination: MultipleChoiceChallenge(anatomyTerms: anatomyTerms, learnedAndStudiedTerms: learnedAndStudiedTerms), isActive: $showQuiz)
                            Quiz(geometry: geometry, color: colors[0], title: "Multiple Choice")
                                .onTapGesture {
                                    showQuiz = true
                                }
                                .frame(width: 390, height: 200)
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer()
                    }
                }
                .navigationBarHidden(false)
                .navigationTitle("Challenges")
            }
        }
        .onChange(of: showQuiz) { newValue in
            if !newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showQuiz = false
                }
            }
        }
    }
}

struct Quiz: View {
    var geometry: GeometryProxy
    var color: Color
    var title: String
    
    var body: some View {
        ZStack {
            color
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.7))
                .frame(width: geometry.size.width * 0.6, height: 100)
                .shadow(radius: 10)
            Text(title)
                .foregroundColor(.black)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
        }
        .cornerRadius(20)
    }
}


// CHALLENGE - Multiple Choice
struct MultipleChoiceChallenge: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedAnswer: Int?
    @State private var score = 0
    @State private var currentQuestion = 0
    @State private var showAnswerResult = false
    @State private var showAlert = false
    @State private var buttonLabel = "Confirm"
    @State private var showQuiz = false
    @State private var answerOptions = [String]()
    @State private var correctAnswerIndex = 0
    @State private var shuffledTerms = [Int]()
    @State private var showResults = false
    @State private var missedTerms: [String] = []
    @State private var showResultsView = false
    @ObservedObject var learnedAndStudiedTerms: LearnedAndStudiedTerms
    @State private var quizId: UUID = UUID() 
    let anatomyTerms: [String: (String, String, String)]
    let maxQuestions: Int
    
    init(anatomyTerms: [String: (String, String, String)], learnedAndStudiedTerms: LearnedAndStudiedTerms, maxQuestions: Int = 5) {
        self.learnedAndStudiedTerms = learnedAndStudiedTerms
        self.anatomyTerms = anatomyTerms
        self.maxQuestions = maxQuestions
        self._shuffledTerms = State(initialValue: Array(0..<anatomyTerms.count).shuffled())
    }
    
    private let correctHaptic = UIImpactFeedbackGenerator(style: .medium)
    private let incorrectHaptic = UINotificationFeedbackGenerator()
    
    var body: some View {
        ZStack {
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
            
            if !showQuiz && !showResultsView {
                QuizCountdown(onFinish: {
                    withAnimation {
                        showQuiz = true
                        answerOptions = getAnswerText()
                    }
                })
            } else if showQuiz {
                createQuizView()
            } else if showResultsView {
                ResultsView(missedTerms: missedTerms, score: score, maxQuestions: maxQuestions, retryAction: {
                    // Reset the state for a new quiz.
                    missedTerms = []
                    score = 0
                    currentQuestion = 0
                    selectedAnswer = nil
                    showAnswerResult = false
                    showAlert = false
                    buttonLabel = "Confirm"
                    showQuiz = false
                    showResultsView = false
                    shuffledTerms = Array(0..<anatomyTerms.count).shuffled()
                }, addToStudyingAction: { term in
                    self.learnedAndStudiedTerms.studiedTerms.insert(term)
                })
            }
        }
    }
    
    func getAnswerText() -> [String] {
        guard !shuffledTerms.isEmpty && currentQuestion < shuffledTerms.count else {
            return []
        }
        
        let correctTermIndex = shuffledTerms[currentQuestion]
        let correctTerm = Array(anatomyTerms.keys)[correctTermIndex]
        
        var incorrectTerms = Array(anatomyTerms.keys).filter { $0 != correctTerm }
        incorrectTerms.shuffle()
        
        let selectedIncorrectTerms = Array(incorrectTerms.prefix(3))
        
        var answers = selectedIncorrectTerms + [correctTerm]
        answers.shuffle()
        
        if let index = answers.firstIndex(of: correctTerm) {
            correctAnswerIndex = index
        }
        
        return answers
    }
    
    func updateAnswerOptions() {
        answerOptions = getAnswerText()
    }
    
    func createQuizView() -> some View {
        VStack {
            Text("Multiple Choice Challenge")
                .font(.system(size: 30, weight: .bold))
                .padding(.bottom, 20)
            
            Spacer()
            
            VStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(UIColor.secondarySystemBackground))
                    Text("\(Array(anatomyTerms.values)[shuffledTerms[currentQuestion]].0)")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 25)
                        .background(RoundedRectangle(cornerRadius: 20)
                            .fill(Color(UIColor.secondarySystemBackground)))
                }
                
                VStack {
                    ForEach(0..<4, id: \.self) { index in
                        Button(action: {
                            if buttonLabel == "Confirm" {
                                self.selectedAnswer = index
                            }
                        }) {
                            Text(answerOptions[index])
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(selectedAnswer == index ? Color.gray.opacity(0.4) : Color(UIColor.secondarySystemBackground))
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.gray, lineWidth: 2)
                                )
                                .foregroundColor(
                                    (buttonLabel != "Confirm" && index == correctAnswerIndex) ? 
                                        .green : 
                                        (selectedAnswer == index ? 
                                         (
                                            buttonLabel != "Confirm" ? 
                                            (
                                                index == correctAnswerIndex ? 
                                                    .green 
                                                : .red
                                            ) 
                                            : .primary
                                         ) 
                                         : .primary
                                        )
                                )
                        }
                        .padding(.bottom, 10)
                    }
                }
                .padding(.top, 10)
                
                Spacer()
                    .frame(height: 20)
            }
            
            VStack {
                ZStack {
                    // Placeholder
                    Text("Correct")
                        .font(.headline)
                        .foregroundColor(.clear)
                    
                    // Actual result
                    if showAnswerResult {
                        if let selected = selectedAnswer {
                            Text(selected == correctAnswerIndex ? "Correct" : "Incorrect")
                                .font(.headline)
                                .foregroundColor(selected == correctAnswerIndex ? .green : .red)
                                .transition(.opacity)
                        }
                    }
                }
                Spacer().frame(height: 20)
            }
            
            Button(action: {
                if buttonLabel == "Confirm" {
                    if let selected = selectedAnswer {
                        if selected == correctAnswerIndex {
                            self.score += 1
                            correctHaptic.impactOccurred()
                        } else {
                            incorrectHaptic.notificationOccurred(.error)
                            let missedTerm = Array(anatomyTerms.keys)[shuffledTerms[currentQuestion]]
                            if !missedTerms.contains(missedTerm) {
                                missedTerms.append(missedTerm)
                            }
                        }
                        self.showAnswerResult = true
                        self.buttonLabel = "Next Question"
                    }
                } else {
                    self.showAnswerResult = false
                    self.currentQuestion += 1
                    
                    if currentQuestion < maxQuestions {
                        self.selectedAnswer = nil
                        self.buttonLabel = "Confirm"
                        answerOptions = getAnswerText()
                    } else {
                        withAnimation {
                            showQuiz = false
                            showResultsView = true
                            currentQuestion = 0
                            shuffledTerms = Array(0..<anatomyTerms.count).shuffled()
                        }
                    }
                }
            }) {
                Text(buttonLabel)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.pink)
                    .foregroundColor(Color.white)
                    .cornerRadius(10)
                    .padding(.top, 5)
            }
            
            Spacer()
        }
        .padding()
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: HStack {
            Button(action: { 
                showAlert = true 
                missedTerms = [] 
            }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.pink)
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Leave Quiz"),
                      message: Text("Are you sure you want to leave the quiz?"),
                      primaryButton: .destructive(Text("Leave")) {
                    presentationMode.wrappedValue.dismiss()
                },
                      secondaryButton: .cancel())
            }
        })
    }
}


// Countdown before quiz
struct QuizCountdown: View {
    let onFinish: () -> Void
    @State private var countdown = 3
    @State private var progress: CGFloat = 1
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            VStack {
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.4), lineWidth: 10)
                        .frame(width: 150, height: 150)
                    
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(style: StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round))
                        .foregroundColor(Color.pink)
                        .frame(width: 150, height: 150)
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(countdown)")
                        .font(.system(size: 70))
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
                if countdown > 0 {
                    countdown -= 1
                    withAnimation(.easeOut(duration: 1)) {
                        progress = CGFloat(countdown) / 3
                    }
                } else {
                    timer.invalidate()
                    onFinish()
                }
            }
        }
    }
}

// MARK - Circle
struct CircleProgressView: View {
    var progress: CGFloat
    var color: Color = .cyan
    var lineWidth: CGFloat = 20
    @State private var animationProgress: CGFloat = 0.0
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: lineWidth)
                .opacity(0.3)
                .foregroundColor(color)
            
            Circle()
                .trim(from: 0, to: animationProgress)
                .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                .foregroundColor(color)
                .rotationEffect(Angle(degrees: 270))
                .animation(.linear(duration: 2.0))
            
            Text(String(format: "%.0f%%", progress * 100))
                .font(.system(size: 40))
                .fontWeight(.bold)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.linear(duration: 2.0)) {
                    animationProgress = progress
                }
            }
        }
    }
}

struct ResultsView: View {
    @State private var confettiCounter = 0
    @State private var addedToStudying = false
    @State private var quizId = UUID()
    @State private var buttonScale: CGFloat = 1.0
    var missedTerms: [String]
    var score: Int
    var maxQuestions: Int
    var retryAction: () -> Void
    var addToStudyingAction: (String) -> Void
    
    var body: some View {
        VStack {
            Spacer()
            
            if score == maxQuestions {
                ConfettiView(counter: $confettiCounter)
                    .transition(.scale)
            }
            
            CircleProgressView(progress: CGFloat(score) / CGFloat(maxQuestions))
                .frame(width: 200, height: 200)
                .padding(40)
                .animation(.easeIn)
            
            VStack {
                Text("Missed Terms")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.bottom, 10)
                
                if missedTerms.isEmpty {
                    Text("No missed terms")
                        .font(.headline)
                        .foregroundColor(.secondary)
                } else {
                    ScrollView {
                        VStack(alignment: .center, spacing: 10) {
                            ForEach(missedTerms, id: \.self) { term in
                                Text(term)
                                    .font(.body)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                        }
                    }
                    .frame(height: 150)
                }
                
                Button(action: {
                    print("Add to Studying button was pressed")
                    if !addedToStudying {
                        for term in missedTerms {
                            print("Adding term to studying: \(term)")
                            addToStudyingAction(term)
                        }
                        addedToStudying = true
                        withAnimation(.spring()) {
                            buttonScale = 0.95
                        }
                    } else {
                        print("All terms are already added to studying")
                    }
                }) {
                    HStack {
                        Spacer()
                        if addedToStudying {
                            Image(systemName: "checkmark")
                                .foregroundColor(.white)
                        } else {
                            Text("Add to Studying")
                                .bold()
                                .foregroundColor(.white)
                        }
                        Spacer()
                    }
                }
                .frame(width: 275, height: 44)
                .background(Color.purple)
                .cornerRadius(10)
                .padding(.top, 10)
                .scaleEffect(buttonScale)
                .onTapGesture {
                    withAnimation(.spring()) {
                        buttonScale = 1.0
                    }
                }
                .disabled(addedToStudying)
            }
            .padding()
            .background(Color.gray.opacity(0.2))
            .cornerRadius(20)
            .padding(.horizontal)
            
            Spacer().frame(height: 30)
            
            Button(action: {
                quizId = UUID() // Generate a new UUID
                retryAction()
            }) {
                Text("Retry")
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(Color.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
        .onAppear {
            if score == maxQuestions {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.spring()) {
                        confettiCounter += 1
                    }
                }
            }
        }
        .id(quizId)
    }
}

// MARK - Confetti 
struct ConfettiView: View {
    @Binding var counter: Int
    
    var body: some View {
        ConfettiCannon(counter: $counter, num: 100)
    }
}
