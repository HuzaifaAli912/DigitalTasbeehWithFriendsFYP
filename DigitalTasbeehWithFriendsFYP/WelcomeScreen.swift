import SwiftUI

struct WelcomeView: View {
    @State private var navigateToLogin = false // Flag to navigate to Login Screen
    
    var body: some View {
        NavigationView {
            VStack {
                // Image
                Image("tasbeeh-image") // Add your image to the Assets folder
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .padding(.top, 50)
                
                // Title Text
                Text("Digital Tasbeeh")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 20)
                
                // Subheading Text
                Text("Welcome to Digital Tasbeeh!\nStart counting your blessings with ease and accuracy.")
                    .multilineTextAlignment(.center)
                    .padding()
                    .foregroundColor(.gray)
                
                // Get Started Button with Navigation
                NavigationLink(destination: LoginView(), isActive: $navigateToLogin) {
                    Button(action: {
                        // Trigger navigation to Login Screen
                        navigateToLogin = true
                    }) {
                        Text("Get Started")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(10)
                            .padding(.horizontal, 50)
                    }
                    .padding(.top, 30)
                }

                Spacer()
            }
            .background(Color.white)
            .edgesIgnoringSafeArea(.all) // To make the background cover the entire screen
            .navigationBarHidden(true) // Hide navigation bar in Welcome screen
        }
    }
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView()
    }
}
