import SwiftUI

struct ManuallyContributionView: View {
    let userId: Int
    let groupId: Int
    let tasbeehId: Int
    let goal: Int
    let endDate: String?
    let purpose: String
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
        let isAdmin: Bool
        let groupId: Int
        let groupTitle: String

        enum CodingKeys: String, CodingKey {
            case id = "Memberid"
            case memberName = "Memmber"
            case isAdmin = "Admin"
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
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                    }
                    .padding(.vertical)
                }

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
            .onAppear {
                getGroupMembers()
            }
            .navigationTitle("Manually Contribution")
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }

    func getGroupMembers() {
        let urlString = "http://192.168.137.1/DigitalTasbeehWithFriendsApi/api/Request/ShowGroupm?groupid=\(groupId)"
        guard let url = URL(string: urlString) else { return }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data {
                print("Received data: \(String(data: data, encoding: .utf8) ?? "")")
                do {
                    let decoded = try JSONDecoder().decode([GroupMember].self, from: data)
                    DispatchQueue.main.async {
                        self.groupMembers = decoded
                        self.groupTitle = decoded.first?.groupTitle ?? "Group"
                        self.counts = Array(repeating: "", count: decoded.count)
                        print("Decoded Group Members:")
                        for member in decoded {
                            print("Member: \(member.memberName), Admin: \(member.isAdmin), ID: \(member.id)")
                        }
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

    func assignTasbeeh() {
        let numericCounts = selectedCount.values.compactMap { Int($0) }
        let total = numericCounts.reduce(0, +)

        if total > goal {
            alertMessage = "One or more users have a count greater than the goal. Please adjust the values."
            showAlert = true
            return
        }

        let assignTasbeehObject = [
            "Group_id": groupId,
            "Tasbeeh_id": tasbeehId,
            "Goal": goal,
            "End_date": endDate ?? "",
            "schedule": schedule,
            "Purpose": purpose
        ] as [String: Any]

        postRequest(urlString: "http://192.168.137.1/DigitalTasbeehWithFriendsApi/api/AssignTasbeeh/AssignTasbeeh", payload: assignTasbeehObject) { result in
            if result {
                distributeTasbeehManually()
            }
        }
    }

    func distributeTasbeehManually() {
        let groupMembersIds = groupMembers.map { $0.id }
        let formData: [String: Any] = [
            "groupid": groupId,
            "tasbeehid": tasbeehId,
            "id": groupMembersIds,
            "count": selectedCount
        ]

        postRequest(urlString: "http://192.168.137.1/DigitalTasbeehWithFriendsApi/api/Request/DistributeTasbeehManually", payload: formData) { result in
            if result {
                // Go back after successful distribution
                print("Tasbeeh assigned and distributed successfully")
            }
        }
    }

    func postRequest(urlString: String, payload: [String: Any], completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: urlString),
              let jsonData = try? JSONSerialization.data(withJSONObject: payload) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        URLSession.shared.dataTask(with: request) { data, _, _ in
            if let data = data {
                DispatchQueue.main.async {
                    completion(true)
                }
            } else {
                DispatchQueue.main.async {
                    completion(false)
                }
            }
        }.resume()
    }
}

struct ManuallyContributionView_Previews: PreviewProvider {
    static var previews: some View {
        ManuallyContributionView(userId: 1, groupId: 3123, tasbeehId: 1, goal: 90, endDate: "2025/12/31", purpose: "Recite Tasbeeh for blessings", schedule: "Daily", leaverId: nil)
            .previewDevice("iPhone 14 Pro")
    }
}

