import SwiftUI

// MARK: - User Model
struct UserModel: Identifiable, Codable {
    let id: Int
    let name: String
    let status: String

    enum CodingKeys: String, CodingKey {
        case id = "ID"
        case name = "name"
        case status = "Status"
    }
}

// MARK: - View
struct CreateGroupSingleView: View {
    let userId: Int

    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var selectedType: String = "Single"
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var users: [UserModel] = []
    @State private var selectedUserIds: Set<Int> = []

    let tasbeehTypes = ["Single", "Group"]
    var currentUserId: Int { userId }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Enter Group Title")
                        .font(.headline)
                        .padding(.top, 30)

                    TextField("Zakir Group", text: $title)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 20).stroke(Color.gray))

                    Picker("Select Type", selection: $selectedType) {
                        ForEach(tasbeehTypes, id: \.self) { type in
                            Text(type)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 20).stroke(Color.gray))

                    if selectedType == "Group" {
                        Text("Select Members")
                            .font(.headline)
                            .padding(.top, 10)

                        VStack(spacing: 10) {
                            ForEach(users.filter { $0.id != currentUserId }) { user in
                                HStack {
                                    Button(action: {
                                        if selectedUserIds.contains(user.id) {
                                            selectedUserIds.remove(user.id)
                                        } else {
                                            selectedUserIds.insert(user.id)
                                        }
                                    }) {
                                        Image(systemName: selectedUserIds.contains(user.id) ? "checkmark.square.fill" : "square")
                                            .foregroundColor(.blue)
                                            .padding(.trailing, 5)
                                    }

                                    Text(user.name)
                                        .foregroundColor(.primary)

                                    Spacer()

                                    Text(user.status.lowercased() == "online" ? "Online" : "Offline")
                                        .foregroundColor(user.status.lowercased() == "online" ? .green : .gray)
                                        .font(.caption)
                                }
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(10)
                            }
                        }
                        .padding(.bottom)
                    }

                    Spacer()

                    Button(action: {
                        if selectedType == "Single" {
                            createSingle()
                        } else {
                            createGroup()
                        }
                    }) {
                        Text("Create")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(30)
                    }
                }
                .padding()
            }
            .navigationTitle("Create Group/Single")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Response"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .onAppear {
                if selectedType == "Group" {
                    fetchUsers()
                }
            }
            .onChange(of: selectedType) { newType in
                if newType == "Group" {
                    fetchUsers()
                } else {
                    users = []
                    selectedUserIds.removeAll()
                }
            }
        }
    }

    // MARK: - Fetch Users API
    func fetchUsers() {
        guard let url = URL(string: "http://192.168.137.1/DigitalTasbeehWithFriendsApi/api/User/AllUser") else {
            print("❌ Invalid URL")
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                print("❌ Network error: \(error.localizedDescription)")
                return
            }

            if let data = data {
                do {
                    let decoded = try JSONDecoder().decode([UserModel].self, from: data)
                    DispatchQueue.main.async {
                        self.users = decoded
                    }
                } catch {
                    print("❌ JSON Decoding Error: \(error.localizedDescription)")
                }
            }
        }.resume()
    }

    // MARK: - Create Group API (React Native style)
    func createGroup() {
        guard !title.isEmpty else {
            alertMessage = "Please enter a group title."
            showAlert = true
            return
        }

        if selectedUserIds.isEmpty {
            alertMessage = "Please select at least one member."
            showAlert = true
            return
        }

        guard let url = URL(string: "http://192.168.137.1/DigitalTasbeehWithFriendsApi/api/Group/CreateGroup") else {
            alertMessage = "Invalid API URL."
            showAlert = true
            return
        }

        let body: [String: Any] = [
            "Group_Title": title,
            "Admin_id": currentUserId
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            alertMessage = "Invalid request data."
            showAlert = true
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    alertMessage = "Network error: \(error.localizedDescription)"
                    showAlert = true
                }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    alertMessage = "No response from server."
                    showAlert = true
                }
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let createdGroupId = json["ID"] as? Int {
                    print("✅ Group created with ID: \(createdGroupId)")
                    addGroupMembers(groupId: createdGroupId)
                } else {
                    DispatchQueue.main.async {
                        alertMessage = "Group created, but group ID missing in response."
                        showAlert = true
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    alertMessage = "Failed to decode group creation response."
                    showAlert = true
                }
            }
        }.resume()
    }

    // MARK: - Add Group Members
    func addGroupMembers(groupId: Int) {
        var memberData = selectedUserIds.map { id in
            ["Group_id": groupId, "Members_id": id]
        }

        // Include creator
        memberData.append(["Group_id": groupId, "Members_id": currentUserId])

        guard let url = URL(string: "http://192.168.137.1/DigitalTasbeehWithFriendsApi/api/Group/GroupMembers"),
              let jsonData = try? JSONSerialization.data(withJSONObject: memberData) else {
            print("❌ Failed to prepare members request.")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    alertMessage = "Group created but failed to add members: \(error.localizedDescription)"
                } else {
                    alertMessage = "Group and members added successfully!"
                    title = ""
                    selectedUserIds.removeAll()
                    dismiss()
                }
                showAlert = true
            }
        }.resume()
    }

    // MARK: - Create Single Tasbeeh
    func createSingle() {
        guard let url = URL(string: "http://192.168.137.1/DigitalTasbeehWithFriendsApi/api/Sigle/CreateSingletasbeeh") else {
            alertMessage = "Invalid API URL."
            showAlert = true
            return
        }

        let body: [String: Any] = [
            "Title": title,
            "User_id": currentUserId
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            alertMessage = "Invalid request data."
            showAlert = true
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    alertMessage = "Error: \(error.localizedDescription)"
                } else {
                    alertMessage = "Single tasbeeh created successfully!"
                    title = ""
                    dismiss()
                }
                showAlert = true
            }
        }.resume()
    }
}

// MARK: - Preview
struct CreateGroupSingleView_Previews: PreviewProvider {
    static var previews: some View {
        CreateGroupSingleView(userId: 1)
    }
}

