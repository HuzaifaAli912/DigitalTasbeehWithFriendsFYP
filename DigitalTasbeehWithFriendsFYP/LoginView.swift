import SwiftUI

struct LoginView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var errorMessage: String = ""
    @State private var isLoggedIn: Bool = false
    @State private var loggedInUser: LoggedInUser?

    var body: some View {
        NavigationStack {
            VStack {
                Text("Hey, Welcome Back")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 50)

                TextField("Enter your email", text: $email)
                    .padding()
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)

                SecureField("Enter your password", text: $password)
                    .padding()
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }

                Button(action: {
                    loginUser(email: email, password: password)
                }) {
                    Text("Login")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                        .padding(.horizontal, 50)
                }

                NavigationLink("Create Account", destination: SignUpView())
                    .font(.title3)
                    .foregroundColor(.blue)
                    .padding()

                // Navigate to HomeView
                NavigationLink(
                    destination: HomeView(user: loggedInUser ?? LoggedInUser(id: 0, username: "User", email: "")),
                    isActive: $isLoggedIn
                ) {
                    EmptyView()
                }
            }
            .padding()
        }
    }

    func loginUser(email: String, password: String) {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedEmail.isEmpty, !trimmedPassword.isEmpty else {
            errorMessage = "Please fill in all fields."
            return
        }

        let baseURL = "http://192.168.137.1/DigitalTasbeehWithFriendsApi/api/user/login"
        let fullURLString = "\(baseURL)?email=\(trimmedEmail)&password=\(trimmedPassword)"

        guard let url = URL(string: fullURLString) else {
            errorMessage = "Invalid URL"
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = "Network error: \(error.localizedDescription)"
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse,
                      let data = data else {
                    self.errorMessage = "Invalid server response."
                    return
                }

                if httpResponse.statusCode == 200 {
                    do {
                        let user = try JSONDecoder().decode(LoggedInUser.self, from: data)
                        self.loggedInUser = user
                        self.isLoggedIn = true
                        self.errorMessage = ""
                    } catch {
                        self.errorMessage = "Failed to parse user data."
                    }
                } else {
                    self.errorMessage = "Invalid credentials or server error."
                }
            }
        }.resume()
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
