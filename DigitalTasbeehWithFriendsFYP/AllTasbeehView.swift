import SwiftUI

// MARK: - Custom Error Model
struct AlertError: Identifiable {
    var id = UUID()
    var message: String
}

// MARK: - Tasbeeh Model
struct TasbeehItem: Identifiable, Codable {
    let id: Int
    let title: String
    let type: String
    

    enum CodingKeys: String, CodingKey {
        case id = "ID"  // Mapping "ID" from API response to "id" in the model
        case title = "Tasbeeh_Title"
        case type = "Type"
    }
}

// MARK: - All Tasbeeh View
struct AllTasbeehView: View {
    let userId: Int
    
    @State private var tasbeehs: [TasbeehItem] = []
    @State private var showCreateView = false
    @State private var isLoading = false // Track loading state
    @State private var alertError: AlertError? // Show error message if any

    var body: some View {
        NavigationStack {
            VStack {
                Text("All Tasbeeh")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)

                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                        .padding()
                }

                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(tasbeehs) { tasbeeh in
                            HStack {
                                
                                
                                VStack(alignment: .leading) {
                                    Text(tasbeeh.title)
                                        .font(.headline)
                                        .foregroundColor(.black)
                                    Text(tasbeeh.type)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }

                                Spacer()
                                

                                Button(action: {
                                    deleteTasbeeh(id: tasbeeh.id)
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                            }
                            .padding()
                            .background(Color.blue.opacity(0.3))
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                }

                Spacer()

                HStack {
                    Spacer()
                    NavigationLink(destination: CreateTasbeehView(userId: userId)) {
                        Image(systemName: "plus")
                            .font(.title)
                            .foregroundColor(.white)
                            .frame(width: 55, height: 55)
                            .background(Color.blue)
                            .clipShape(Circle())
                            .shadow(radius: 5)
                            .padding()
                    }
                }
                
            }
            .onAppear {
                fetchTasbeehs()
            }
            .alert(item: $alertError) { error in
                Alert(title: Text("Error"), message: Text(error.message), dismissButton: .default(Text("OK")))
            }
        }
        Button(action: {
            // TODO: API call to submit tasbeeh
            print("Merging Tasbeeh with title: \(tasbeehs)")
        }) {
            Text("Merge")
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(30)
                .padding(.horizontal)
        }

        Spacer()
    }

    // MARK: - Fetch Tasbeehs
    func fetchTasbeehs() {
        isLoading = true
        alertError = nil
        guard let url = URL(string: "http://192.168.137.1/DigitalTasbeehWithFriendsApi/api/CreateTasbeeh/Alltasbeeh?userid=\(userId)") else {
            print("❌ Invalid URL")
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data else {
                DispatchQueue.main.async {
                    self.alertError = AlertError(message: "No data received")
                }
                return
            }

            // Log the raw response to see the actual data
            if let jsonStr = String(data: data, encoding: .utf8) {
                print("📦 Raw Response: \(jsonStr)")
            }

            do {
                let decoded = try JSONDecoder().decode([TasbeehItem].self, from: data)
                DispatchQueue.main.async {
                    self.tasbeehs = decoded
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.alertError = AlertError(message: "❌ JSON decode error: \(error)")
                    self.isLoading = false
                }
            }
        }.resume()
    }

    // MARK: - Delete Tasbeeh
    func deleteTasbeeh(id: Int) {
        isLoading = true
        alertError = nil
        guard let url = URL(string: "http://192.168.137.1/DigitalTasbeehWithFriendsApi/api/CreateTasbeeh/Deletetasbeeh?userid=\(userId)&tabseehid=\(id)") else {
            print("❌ Invalid delete URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET" // Use GET for the delete request since the API expects it

        URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.alertError = AlertError(message: "Network error: \(error.localizedDescription)")
                    self.isLoading = false
                }
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                print("❌ HTTP Status Code: \(httpResponse.statusCode)")
                if httpResponse.statusCode == 200 {
                    DispatchQueue.main.async {
                        self.tasbeehs.removeAll { $0.id == id } // Remove from UI
                        self.isLoading = false
                    }
                } else {
                    DispatchQueue.main.async {
                        self.alertError = AlertError(message: "Failed to delete the Tasbeeh. Status Code: \(httpResponse.statusCode)")
                        self.isLoading = false
                    }
                }
            }
        }.resume()
    }
    //make compoumd tasbeeh or merge
    func createTasbeeh(title: String, count: Int, type: String) {
        let url = URL(string: "http://192.168.137.1/DigitalTasbeehWithFriendsApi/api/User/CreateCompoundTasbeeh")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let tasbeeh = [
            "Tasbeeh_Title": title,
            "Count": count,
            "Type": type
        ] as [String : Any]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: tasbeeh)
        } catch {
            print("❌ JSON Error:", error)
            return
        }

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                print("❌ API Error:", error.localizedDescription)
            } else {
                print("✅ Tasbeeh Created")
            }
        }.resume()
    }
}

// MARK: - Preview
struct AllTasbeehView_Previews: PreviewProvider {
    static var previews: some View {
        AllTasbeehView(userId: 1)
    }
}

