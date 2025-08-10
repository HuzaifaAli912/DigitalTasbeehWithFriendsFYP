import SwiftUI




// MARK: - TasbeehDetail (For displaying individual tasbeeh details)
struct TasbeehDetail: Identifiable, Codable {
    let id: Int
    let Text: String
    let Count: Int
    let TasbeehType: String
}


// MARK: - TasbeehDetails View
struct TasbeehDetails: View {
    let tasbeehId: Int
    @State private var tasbeehDetails: [TasbeehDetail] = []
    @State private var isLoading = false
    @State private var alertError: AlertError?

    var body: some View {
        NavigationStack {
            VStack {
                Text("Tasbeeh Details")
                    .font(.largeTitle)
                    .bold()

                if isLoading {
                    ProgressView()
                        .padding()
                }

                if !isLoading && tasbeehDetails.isEmpty {
                    Text("No details available.")
                        .foregroundColor(.gray)
                        .padding()
                }

                List(tasbeehDetails) { detail in
                    VStack(alignment: .leading) {
                        Text(detail.Text)
                            .font(.headline)
                        Text("Count: \(detail.Count)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                }

                Spacer()
            }
            .onAppear {
                fetchTasbeehDetails()
            }
            .alert(item: $alertError) { error in
                Alert(title: Text("Message"), message: Text(error.message), dismissButton: .default(Text("OK")))
            }
        }
    }

    func fetchTasbeehDetails() {
        isLoading = true
        alertError = nil
        guard let url = URL(string: "http://192.168.137.1/DigitalTasbeehWithFriendsApi/api/Wazifa/Gettasbeehwazifadeatiles?id=\(tasbeehId)") else { return }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data else {
                DispatchQueue.main.async {
                    self.alertError = AlertError(message: "No data received")
                    self.isLoading = false
                }
                return
            }

            do {
                let decoded = try JSONDecoder().decode([TasbeehDetail].self, from: data)
                DispatchQueue.main.async {
                    self.tasbeehDetails = decoded
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.alertError = AlertError(message: "Decode error: \(error)")
                    self.isLoading = false
                }
            }
        }.resume()
    }
}

// MARK: - Preview
struct TasbeehDetails_Previews: PreviewProvider {
    static var previews: some View {
        TasbeehDetails(tasbeehId: 1)
    }
}

