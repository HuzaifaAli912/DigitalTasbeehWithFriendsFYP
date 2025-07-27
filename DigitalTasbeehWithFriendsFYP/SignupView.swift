import SwiftUI

struct SignUpView: View {
    @State private var Username = ""
    @State private var Email = ""
    @State private var Password = ""
    @State private var confirmPassword = ""
    @State private var isShowingAlert = false
    @State private var alertMessage = ""

    var body: some View {
        VStack {
            Text("Let's get Started")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 50)

            TextField("Enter your username", text: $Username)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .padding(.top, 20)

            TextField("Enter your email", text: $Email)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .padding(.top, 10)

            SecureField("Enter your password", text: $Password)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.top, 10)

            SecureField("Confirm your password", text: $confirmPassword)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.top, 10)

            Button(action: {
                if self.Password == self.confirmPassword {
                    signUpUser()
                } else {
                    alertMessage = "Passwords do not match!"
                    isShowingAlert = true
                }
            }) {
                Text("Sign Up")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
                    .padding(.top, 20)
            }

            Spacer()
        }
        .padding()
        .alert(isPresented: $isShowingAlert) {
            Alert(title: Text("Sign Up"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .navigationBarHidden(true)
    }

    func signUpUser() {
        guard let url = URL(string: "http://192.168.137.1/DigitalTasbeehWithFriendsApi/api/User/Signup") else {
            alertMessage = "Invalid API URL."
            isShowingAlert = true
            return
        }

        let requestBody: [String: Any] = [
            "Username": Username,
            "Email": Email,
            "Password": Password
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            alertMessage = "Failed to encode request body."
            isShowingAlert = true
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    alertMessage = "Network error: \(error.localizedDescription)"
                    isShowingAlert = true
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    alertMessage = "Invalid server response."
                    isShowingAlert = true
                    return
                }

                if httpResponse.statusCode == 200 {
                    alertMessage = "Sign Up Successful!"
                } else {
                    alertMessage = "Sign Up Failed. Status Code: \(httpResponse.statusCode)"
                }

                isShowingAlert = true
            }
        }.resume()
    }
}

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView()
    }
}
