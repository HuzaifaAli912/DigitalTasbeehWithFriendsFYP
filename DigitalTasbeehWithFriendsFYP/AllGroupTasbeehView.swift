import SwiftUI

// MARK: - Group Tasbeeh Model
struct GroupTasbeehItem: Identifiable, Codable {
    let id: Int
    let title: String
    let goal: Int
    let achieved: Int
    let remaining: Int
    let deadline: String
    let schedule: String

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case title = "title"
        case goal = "Goal"
        case achieved = "Achieved"
        case remaining = "Remaining"
        case deadline = "deadline"
        case schedule = "day"
    }
}

// MARK: - All Group Tasbeeh View
struct AllGroupTasbeehView: View {
    let groupId: Int
    let userId: Int
    @State private var tasbeehs: [GroupTasbeehItem] = []
    @State private var isLoading = false
    @State private var alertError: AlertError?
    // For showing errors

    var body: some View {
        NavigationStack {
            VStack {
                Text("All Group Tasbeeh")
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
                            VStack(alignment: .leading) {
                                Text(tasbeeh.title)
                                    .font(.headline)
                                    .foregroundColor(.black)

                                HStack {
                                    Text("Goal: \(tasbeeh.goal)")
                                    Text("Achieved: \(tasbeeh.achieved)")
                                    Text("Remaining: \(tasbeeh.remaining)")
                                }
                                .font(.caption)
                                .foregroundColor(.gray)

                                Text("Deadline: \(tasbeeh.deadline)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                
                                Text("Schedule: \(tasbeeh.schedule)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color.blue.opacity(0.3))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                    }
                }

                Spacer()
            }
            .onAppear {
                // Print userId and groupId when the view appears
                print("User ID: \(userId)")
                print("Group ID: \(groupId)")  // Debug print
                fetchGroupTasbeehs()
            }
            .alert(item: $alertError) { error in
                Alert(title: Text("Error"), message: Text(error.message), dismissButton: .default(Text("OK")))
            }
        }
    }

    // MARK: - Fetch Group Tasbeehs
    func fetchGroupTasbeehs() {
        if groupId == 0 {
            self.alertError = AlertError(message: "Invalid Group ID")
            return
        }

        isLoading = true
        alertError = nil
        let urlString = "http://192.168.137.1/DigitalTasbeehWithFriendsApi/api/Group/Tasbeehlogs?groupid=\(groupId)&userid=\(userId)"
        
        guard let url = URL(string: urlString) else {
            print("❌ Invalid URL")
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.alertError = AlertError(message: "Network error: \(error.localizedDescription)")
                    self.isLoading = false
                }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    self.alertError = AlertError(message: "No data received from server")
                    self.isLoading = false
                }
                return
            }

            // Log the raw response to see the actual data
            if let jsonStr = String(data: data, encoding: .utf8) {
                print("📦 Raw Response: \(jsonStr)")
            }

            do {
                let decoded = try JSONDecoder().decode([GroupTasbeehItem].self, from: data)
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
}

// MARK: - Preview for All Group Tasbeeh View
struct AllGroupTasbeehView_Previews: PreviewProvider {
    static var previews: some View {
        AllGroupTasbeehView(groupId: 1, userId: 1)
    }
}

