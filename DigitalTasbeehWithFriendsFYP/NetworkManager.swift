import Foundation

class NetworkManager {
    
    // Login API Call
    func login(email: String, password: String, completion: @escaping (Bool, String) -> ()) {
        guard let url = URL(string: "http://192.168.0.130/DigitalTasbeehWithFriendsApi/api/user/login?email=abdullahayaz131@email.com&password=4446") else {
            completion(false, "Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"  // Assuming login is a GET request
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(false, error.localizedDescription)
                return
            }
            
            if let data = data {
                // Handle data here, for example check if login was successful
                if let jsonResponse = try? JSONDecoder().decode([String: String].self, from: data) {
                    if let status = jsonResponse["status"], status == "success" {
                        completion(true, "Login Successful")
                    } else {
                        completion(false, "Invalid Credentials")
                    }
                } else {
                    completion(false, "Error decoding response")
                }
            }
        }.resume()
    }
}

