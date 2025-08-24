import SwiftUI

struct ManuallyContributionView: View {
    let userId: Int
    let groupId: Int
    let tasbeehId: Int
    let goal: Int
    let endDate: String?
    
    let schedule: String
    let leaverId: Int?

    @State private var groupMembers: [GroupMember] = []
    @State private var counts: [String] = []
    @State private var groupTitle: String = ""
    @State private var selectedCount: [String: String] = [:]
    @State private var showAlert = false
    @State private var alertMessage = ""

    struct GroupMember: Identifiable, Decodable {
        let id: Int
        let memberName: String
        let adminUserId: Int         // <- decode Admin as Int
        let groupId: Int
        let groupTitle: String

        // derive a Bool for convenience
        var isAdmin: Bool { id == adminUserId }

        enum CodingKeys: String, CodingKey {
            case id = "Memberid"
            case memberName = "Memmber"
            case adminUserId = "Admin"
            case groupId = "Groupid"
            case groupTitle = "GroupTitle"
        }
    }

    var body: some View {
        NavigationStack {
            VStack {
                Text(groupTitle)
                    .font(.largeTitle)
                    .bold()
                    .padding()

                Text("Group Members: \(groupMembers.count)")
                    .font(.title2)
                    .padding(.bottom)

                List(groupMembers) { member in
                    HStack {
                        Text(member.memberName)
                            .font(.body)
                        if member.isAdmin {
                            Text("Admin")
                                .foregroundColor(.green)
                        }

                        Spacer()

                        TextField("Enter Count", text: Binding(
                            get: { selectedCount["\(member.id)"] ?? "" },
                            set: { selectedCount["\(member.id)"] = $0 }
                        ))
                        .keyboardType(.numberPad)
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                        .frame(width: 120)
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(.plain)

                Button(action: {
                    assignTasbeeh()
                }) {
                    Text("Assign Tasbeeh")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(15)
                }
                .padding()

                Spacer()
            }
            .onAppear { getGroupMembers() }
            .navigationTitle("Manually Contribution")
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }

    // MARK: - API: Get Members
    func getGroupMembers() {
        let urlString = "http://192.168.137.1/DigitalTasbeehWithFriendsApi/api/Request/ShowGroupm?groupid=\(groupId)"
        guard let url = URL(string: urlString) else { return }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data {
                // For debugging
                print("Received data: \(String(data: data, encoding: .utf8) ?? "")")
                do {
                    let decoded = try JSONDecoder().decode([GroupMember].self, from: data)
                    DispatchQueue.main.async {
                        self.groupMembers = decoded
                        self.groupTitle = decoded.first?.groupTitle ?? "Group"
                        self.counts = Array(repeating: "", count: decoded.count)
                        // Optional: init selectedCount to "0"
                        for m in decoded { self.selectedCount["\(m.id)"] = self.selectedCount["\(m.id)"] ?? "" }
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.alertMessage = "Failed to decode group members: \(error.localizedDescription)"
                        self.showAlert = true
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.alertMessage = "No data received from the API."
                    self.showAlert = true
                }
            }
        }.resume()
    }

    // MARK: - API: Assign Tasbeeh header record
    func assignTasbeeh() {
        // Validate total (your current logic checks sum vs goal)
        let numericCounts = selectedCount.values.compactMap { Int($0) }
        let total = numericCounts.reduce(0, +)
        if total > goal {
            alertMessage = "One or more users have a count greater than the goal. Please adjust the values."
            showAlert = true
            return
        }

        let assignTasbeehObject: [String: Any] = [
            "Group_id": groupId,
            "Tasbeeh_id": tasbeehId,
            "Goal": goal,
            "End_date": endDate ?? "",
            "schedule": schedule,
            
        ]

        postRequest(urlString: "http://192.168.137.1/DigitalTasbeehWithFriendsApi/api/AssignTasbeeh/AssignTasbeeh",
                    payload: assignTasbeehObject) { result in
            if result {
                distributeTasbeehManually()
            } else {
                self.alertMessage = "Failed to create tasbeeh."
                self.showAlert = true
            }
        }
    }

    // MARK: - API: Distribute with aligned arrays
    func distributeTasbeehManually() {
        let memberIds = groupMembers.map { $0.id }
        // build counts array aligned with the same order as memberIds
        let countsArray = groupMembers.map { Int(selectedCount["\($0.id)"] ?? "0") ?? 0 }

        let formData: [String: Any] = [
            "groupid": groupId,
            "tasbeehid": tasbeehId,
            "id": memberIds,
            "count": countsArray
        ]

        postRequest(urlString: "http://192.168.137.1/DigitalTasbeehWithFriendsApi/api/Request/DistributeTasbeehManually",
                    payload: formData) { result in
            if result {
                print("Tasbeeh assigned and distributed successfully")
                // You can navigate back or show success if you want
            } else {
                self.alertMessage = "Failed to distribute tasbeeh."
                self.showAlert = true
            }
        }
    }

    // MARK: - POST helper
    func postRequest(urlString: String, payload: [String: Any], completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: urlString),
              let jsonData = try? JSONSerialization.data(withJSONObject: payload) else {
            completion(false)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("POST error:", error.localizedDescription)
                DispatchQueue.main.async { completion(false) }
                return
            }
            if let http = response as? HTTPURLResponse {
                print("POST status:", http.statusCode)
            }
            DispatchQueue.main.async { completion(data != nil) }
        }.resume()
    }
}

struct ManuallyContributionView_Previews: PreviewProvider {
    static var previews: some View {
        ManuallyContributionView(
            userId: 1,
            groupId: 3123,
            tasbeehId: 1,
            goal: 90,
            endDate: "2025/12/31",
            
            schedule: "Daily",
            leaverId: nil
        )
        .previewDevice("iPhone 14 Pro")
    }
}

