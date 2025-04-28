import SwiftUI

// MARK - Anatomy Dictionary: Regions
struct AnatomyRegions {
    static let regions = [
        "Abdominal", "Acromial", "Antebrachial", "Antecubital", "Auricle/Otic", "Axillary", "Brachial", "Buccal", "Carpal", "Cervical", "Coxal", "Cranial", "Crural", "Digital/Phalangeal", "Dorsal", "Facial", "Femoral", "Fibular", "Frontal", "Inguinal", "Lumbar", "Mammary", "Manual/Manus", "Mental", "Nasal", "Olecranal", "Oral", "Orbital/Ocular", "Palmar", "Patellar", "Pedal", "Pubic", "Sacral", "Scapular", "Sternal", "Tarsal", "Thoracic", "Umbilical"
    ]
}

struct AnatomyDataSource {
    static let shared = AnatomyDataSource()
    let anatomyTerms: [String: (function: String, latinRoot: String, region: String)]
    
    private init() {
        // Combine all the dictionaries from each region
        anatomyTerms = AnatomyTerms.allAnatomyTerms
    }
}

struct BrowseTab: View {
    let colors = [Color.red, Color.orange, Color.yellow, Color.green, Color.mint, Color.teal, Color.cyan, Color.blue, Color.indigo, Color.purple, Color.pink, Color.gray, Color.brown]
    @State private var selectedTab = 0
    @State private var expandedTerms: [String] = []
    @State private var expandedRegions: Set<String> = []
    @EnvironmentObject var toastSettings: ToastSettings
    @EnvironmentObject var learnedAndStudiedTerms: LearnedAndStudiedTerms
    @State private var expandedTerm: String? = nil
    
    private var expandedTermRegion: String? {
        if let term = expandedTerm, let termInfo = AnatomyDataSource.shared.anatomyTerms[term] {
            return termInfo.region
        }
        return nil
    }
    
    @State private var searchText = ""
    private var filteredTerms: [String: (function: String, latinRoot: String, region: String)] {
        AnatomyDataSource.shared.anatomyTerms.filter { $0.key.lowercased().contains(searchText.lowercased()) }
    }
    
    private var filteredRegions: [String] {
        if searchText.isEmpty {
            return AnatomyRegions.regions
        } else {
            let regions = Set(filteredTerms.values.map { $0.region })
            return AnatomyRegions.regions.filter { regions.contains($0) || $0.lowercased().contains(searchText.lowercased()) }
        }
    }
    
    private var studiedRegions: Set<String> {
        Set(learnedAndStudiedTerms.studiedTerms.compactMap { AnatomyDataSource.shared.anatomyTerms[$0]?.region })
    }
    
    private var learnedRegions: Set<String> {
        Set(learnedAndStudiedTerms.learnedTerms.compactMap { AnatomyDataSource.shared.anatomyTerms[$0]?.region })
    }
    
    private var noResultsFound: Bool {
        return !searchText.isEmpty && filteredRegions.isEmpty
    }
    
    func shouldDisplayTerm(term: String, selectedTab: Int, learnedAndStudiedTerms: LearnedAndStudiedTerms) -> Bool {
        switch selectedTab {
        case 1:
            return learnedAndStudiedTerms.studiedTerms.contains(term)
        case 2:
            return learnedAndStudiedTerms.learnedTerms.contains(term)
        default:
            return true
        }
    }
    
    @State private var toast: Toast?
    @State private var showToast: Bool = false
    @State private var toastMessage = ""
    @State private var toastType: ToastType = .none
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                ScrollView {
                    VStack {
                        // Picker for selecting term display mode
                        Picker(selection: self.$selectedTab, label: Text("")) {
                            Text("All").tag(0)
                            Text("Still Studying").tag(1)
                            Text("Learned").tag(2)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.bottom, 10)
                        .padding(.horizontal, 20)
                        .padding(.top, 30)
                        
                        VStack {
                            // Search bar for filtering terms
                            SearchBar(text: $searchText)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 10)
                            
                            // Display a message if no results are found
                            if noResultsFound {
                                Text("Looks like we've hit a nerve.")
                                    .foregroundColor(.primary)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .padding(.top, 100)
                                    .padding(.bottom, 10)
                                Text("Try a different term or region to explore.")
                            }
                            
                            // Display terms based on the selected tab and search query
                            ForEach(filteredRegions.filter { regionName in
                                switch selectedTab {
                                case 1:
                                    return studiedRegions.contains(regionName)
                                case 2:
                                    return learnedRegions.contains(regionName)
                                default:
                                    return true
                                }
                            }, id: \.self) { regionName in
                                let terms = AnatomyDataSource.shared.anatomyTerms.filter { $0.value.region == regionName && ($0.key.lowercased().contains(searchText.lowercased()) || searchText.isEmpty) }
                                
                                let isRegionExpanded = Binding<Bool>(
                                    get: { expandedRegions.contains(regionName) },
                                    set: { newValue in
                                        if newValue {
                                            expandedRegions.insert(regionName)
                                        } else {
                                            expandedRegions.remove(regionName)
                                        }
                                    }
                                )
                                
                                SectionView(
                                    regionName: regionName,
                                    color: colors[AnatomyRegions.regions.firstIndex(where: { $0 == regionName })! % colors.count],
                                    isExpanded: isRegionExpanded,
                                    selectedTab: self.$selectedTab,
                                    content: {
                                        VStack(alignment: .leading) {
                                            if isRegionExpanded.wrappedValue {
                                                ForEach(terms.keys.sorted(), id: \.self) { term in
                                                    if shouldDisplayTerm(term: term, selectedTab: selectedTab, learnedAndStudiedTerms: learnedAndStudiedTerms) {
                                                        TermView(term: term, termInfo: terms[term]!, selectedTab: $selectedTab, expandedTerms: $expandedTerms)
                                                        
                                                            .environmentObject(learnedAndStudiedTerms)
                                                            .allowsHitTesting(shouldDisplayTerm(term: term, selectedTab: selectedTab, learnedAndStudiedTerms: learnedAndStudiedTerms))
                                                        
                                                    }
                                                }
                                            }
                                        }.padding(.top)
                                    }
                                )
                                .padding(.horizontal, 20)
                                .padding(.bottom, 5)
                            }
                        }
                        .navigationBarHidden(false)
                        .navigationTitle("Browse")
                    }
                }}
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(
                VStack {
                    Spacer()
                    if showToast, let toast = toast {
                        ToastAlert(toast: $toast)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .animation(.easeInOut(duration: 0.5), value: showToast)
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    withAnimation {
                                        showToast = false
                                    }
                                }
                            }
                    }
                }
            )
        }
        .navigationBarHidden(false)
        .navigationTitle("Browse")
    }
}

struct SectionView<Content: View>: View {
    let regionName: String
    let color: Color
    @Binding var isExpanded: Bool
    @Binding var selectedTab: Int
    let content: Content
    
    init(regionName: String, color: Color, isExpanded: Binding<Bool>, selectedTab: Binding<Int>, @ViewBuilder content: () -> Content) {
        self.regionName = regionName
        self.color = color
        self._isExpanded = isExpanded
        self._selectedTab = selectedTab
        self.content = content()
    }
    
    var body: some View {
        VStack {
            HStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .frame(width: 40, height: 40)
                    .foregroundColor(color)
                    .overlay(
                        Text(regionName.prefix(1))
                            .foregroundColor(.white)
                            .font(.title3)
                    )
                
                Text(regionName)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                ZStack {
                    Group {
                        if isExpanded {
                            Image(systemName: "chevron.up")
                            .frame(width: 13, height: 8, alignment: .center)
                        } else {
                            Image(systemName: "chevron.down")
                            .frame(width: 13, height: 8, alignment: .center)
                        }
                    }
                    .frame(width: 13, height: 8, alignment: .center)
                    .foregroundColor(Color(.systemGray))
                }
                .frame(width: 20, height: 13)
                .animation(.spring(response: 0.4, dampingFraction: 0.85, blendDuration: 0))
            }
            .onTapGesture {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85, blendDuration: 0)) {
                    isExpanded.toggle()
                }
            }
            
            
            if isExpanded {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color)
                    .frame(height: 1)
                    .padding(.horizontal)
                    .padding(.top, 5)
                    .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.3)))
                
                content
                    .padding(.horizontal, 10)
                    .animation(.spring(response: 0.4, dampingFraction: 0.85, blendDuration: 0), value: isExpanded)
            }
        }
        .padding(.vertical, 5)
    }
}

struct SearchBar: UIViewRepresentable {
    @Binding var text: String
    
    class Coordinator: NSObject, UISearchBarDelegate {
        @Binding var text: String
        
        init(text: Binding<String>) {
            _text = text
        }
        
        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            text = searchText
        }
    }
    
    func makeCoordinator() -> SearchBar.Coordinator {
        return Coordinator(text: $text)
    }
    
    func makeUIView(context: Context) -> UISearchBar {
        let searchBar = UISearchBar(frame: .zero)
        searchBar.delegate = context.coordinator
        searchBar.searchBarStyle = .minimal
        searchBar.placeholder = "Search"
        return searchBar
    }
    
    func updateUIView(_ uiView: UISearchBar, context: Context) {
        uiView.text = text
    }
}

struct TermDetails: Identifiable {
    let id = UUID()
    let title: String
    let function: String
    let latinRoot: String
    let region: String
}

extension Color {
    static func customToolbarIconColor(colorScheme: ColorScheme) -> Color {
        return colorScheme == .dark ? Color.white : Color.black
    }
}

class ToastSettings: ObservableObject {
    @Published var showToast: Bool = false
    @Published var toast: Toast? = nil
}

struct TermView: View {
    let term: String
    let termInfo: (function: String, latinRoot: String, region: String)
    @Binding var selectedTab: Int
    @Binding var expandedTerms: [String]
    @EnvironmentObject var learnedAndStudiedTerms: LearnedAndStudiedTerms
    @Environment(\.colorScheme) var colorScheme
    @State private var showToast: Bool = false
    @State private var toast: Toast?
    @State private var learnedSelected: Bool = false
    @State private var studiedSelected: Bool = false
    
    var isExpanded: Bool {
        return expandedTerms.contains(term)
    }
    
    private func updateToolbarSelection() {
        learnedSelected = learnedAndStudiedTerms.learnedTerms.contains(term)
        studiedSelected = learnedAndStudiedTerms.studiedTerms.contains(term)
    }
    
    
    // Add a new function to handle button clicks
    private func buttonClick(type: ToastType) {
        switch type {
        case .move:
            if !learnedSelected { // Check if not already selected
                if learnedAndStudiedTerms.studiedTerms.contains(term) {
                    learnedAndStudiedTerms.studiedTerms.remove(term)
                }
                learnedAndStudiedTerms.learnedTerms.insert(term)
                withAnimation {
                    self.toast = Toast(message: "Added to Learned", toastType: .move, boldWords: ["Learned"])
                    self.showToast = true
                }
                learnedSelected = true
                studiedSelected = false
            }
        case .study:
            if !studiedSelected { // Check if not already selected
                if learnedAndStudiedTerms.learnedTerms.contains(term) {
                    learnedAndStudiedTerms.learnedTerms.remove(term)
                }
                learnedAndStudiedTerms.studiedTerms.insert(term)
                withAnimation {
                    self.toast = Toast(message: "Added to Still Studying", toastType: .study, boldWords: ["Still Studying"])
                    self.showToast = true
                }
                studiedSelected = true
                learnedSelected = false
            }
        default:
            break
        }
    }
    
    var body: some View {
        VStack {
            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemGray4))
                    .frame(width: 365, height: 40)
                
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text(term)
                            .fontWeight(.bold)
                        Spacer()
                        Group {
                            if isExpanded {
                                Image(systemName: "chevron.up")
                                    .frame(width: 13, height: 8, alignment: .center)
                            } else {
                                Image(systemName: "chevron.down")
                                    .frame(width: 13, height: 8, alignment: .center)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75, blendDuration: 0)) {
                            if isExpanded {
                                expandedTerms.removeAll(where: { $0 == term })
                            } else {
                                expandedTerms.append(term)
                            }
                            updateToolbarSelection()
                        }
                    }
                }
                
                if isExpanded {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.systemGray5))
                        .frame(width: 365, height: 300)
                        .padding(.top, 50)
                        .overlay(
                            GeometryReader { geometry in
                                VStack {
                                    ScrollView(.vertical, showsIndicators: false) {
                                        VStack(alignment: .center, spacing: 10) {
                                            Text("Region: \(termInfo.region)")
                                                .font(.headline)
                                            Text("Latin Root: \(termInfo.latinRoot)")
                                                .font(.headline)
                                            Text("Function: \(termInfo.function)")
                                                .font(.body)
                                                .multilineTextAlignment(.center)
                                            Spacer()
                                        }
                                        .padding(20)
                                        
                                        HStack {
                                            Spacer()
                                            Button(action: {
                                                buttonClick(type: .move)
                                            }) {
                                                Label("Learned", systemImage: learnedSelected ? "checkmark.circle.fill" : "checkmark.circle")
                                                    .font(.system(size: 14, weight: .semibold))
                                            }
                                            .buttonStyle(BorderlessButtonStyle())
                                            .foregroundColor(Color.customToolbarIconColor(colorScheme: colorScheme))
                                            
                                            Spacer()
                                            Spacer()
                                            Spacer()
                                            
                                            Button(action: {
                                                buttonClick(type: .study)
                                            }) {
                                                Label("Still Studying", systemImage: studiedSelected ? "book.fill" : "book")
                                                    .font(.system(size: 14, weight: .semibold))
                                            }
                                            .buttonStyle(BorderlessButtonStyle())
                                            .foregroundColor(Color.customToolbarIconColor(colorScheme: colorScheme))
                                            Spacer()
                                        }
                                        
                                        .padding(.top, 215)
                                        .padding(.bottom)
                                        .foregroundColor(.black)
                                        
                                    }
                                    .padding(20)
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                                .padding(.top, 30)
                            }
                        )
                        .transition(AnyTransition.opacity.animation(.spring(response: 0.5, dampingFraction: 0.75, blendDuration: 0)))
                        .zIndex(1)
                    
                }
            }
        }
        .overlay(
            Group {
                if showToast, let toast = toast {
                    ToastAlert(toast: $toast)
                        .padding()
                        .onDisappear {
                            self.toast = nil
                            self.showToast = false
                        }
                }
            }
        )
        .onAppear {
            updateToolbarSelection()
        }
        .onChange(of: showToast) { newValue in
            if newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation {
                        self.showToast = false
                    }
                }
            }
        }
    }
}
