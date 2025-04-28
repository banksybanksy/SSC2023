import SwiftUI

struct WhatsNewView: View {
    
    let regularIcons: [(key: String, value: (title: String, description: String), color: Color)] = [
        ("heart.text.square", ("Complete Anatomy Guide", "Explore all human organs with a single click."), Color.cyan),
        ("brain", ("Personalized Learning", "Track terms learned and ones still being studied."), Color.pink),
        ("trophy.fill", ("Challenges", "Conquer anatomy by embracing challenges."), Color.yellow)
    ]
    
    @State private var showIcons = false
    @Binding var shouldShow: Bool
    
    var body: some View {
        VStack(spacing: 5) {
            Text("Welcome to Anato")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 50)
                .padding(.bottom, 20)
                .opacity(showIcons ? 1 : 0)
            
            ForEach(regularIcons.indices, id: \.self) { index in
                let icon = regularIcons[index]
                HStack(alignment: .top) {
                    Image(systemName: icon.key)
                        .foregroundColor(icon.color)
                        .font(.system(size: 25))
                        .frame(width: 40, alignment: .center)
                        .padding(.leading, 40)
                        .baselineOffset(4)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(icon.value.title)
                            .font(.headline)
                            .fontWeight(.bold)
                        Text(icon.value.description)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.leading, 10)
                    .padding(.horizontal)
                    Spacer()
                }
                .padding(.vertical, 10)
                .opacity(showIcons ? 1 : 0)
                .animation(.easeInOut(duration: 0.5).delay(0.2 * Double(index + 1)), value: showIcons)
            }
            .padding(.top, 45)
            
            Spacer()
            
            Button(action: {
                shouldShow = false
            }) {
                Text("Continue")
                    .foregroundColor(.white)
                    .fontWeight(.medium)
                    .padding(.horizontal, 125)
                    .padding(.vertical, 20)
                    .background(Color.pink)
                    .cornerRadius(10)
            }
            .opacity(showIcons ? 1 : 0)
            .onAppear {
                withAnimation(Animation.easeInOut(duration: 0.5).delay(0.2)) {
                    self.showIcons = true
                }
            }
            .padding(.bottom)
        }
        .padding()
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                for index in regularIcons.indices {
                    withAnimation(.easeInOut(duration: 0.5).delay(0.2 * Double(index + 1))) {
                        showIcons = true
                    }
                }
                
                withAnimation(.easeInOut(duration: 0.5).delay(0.2 * Double(regularIcons.count + 1))) {
                    showIcons = true
                }
            }
        }
    }
}


struct WhatsNewView_Previews: PreviewProvider {
    static var previews: some View {
        WhatsNewView(shouldShow: .constant(true))
    }
}
