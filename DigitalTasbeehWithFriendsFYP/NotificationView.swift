import SwiftUI

// MARK: - Models

struct Tasbeehname: Codable {
    let title: String
    let id: Int

    enum CodingKeys: String, CodingKey {
        case title = "Title"
        case id = "Id"
    }
}

struct TasbeehRequestNotification: Identifiable, Codable {
    let id: Int
    let groupTitle: String
    let count: Int
    let tasbeehname: Tasbeehname
    let type: String

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case groupTitle = "GroupTitle"
        case count = "Count"
        case tasbeehname = "Tasbeehname"
        case type = "Type"
    }
}

struct MemberLeftNotification: Identifiable, Codable {
    let id: Int
    let userName: String
    let tasbeehTitle: String
    let groupName: String
    let reason: String

    enum CodingKeys: String, CodingKey {
        case id = "ID"
        case userName = "User_Name"
        case tasbeehTitle = "Tasbeeh_Title"
        case groupName = "Group_Name"
        case reason = "Reason"
    }
}

// MARK: - View

struct NotificationView: View {
    let userId: Int

    @State private var tasbeehRequests: [TasbeehRequestNotification] = []
    @State private var memberLeftNotifications: [MemberLeftNotification] = []

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Tasbeeh Request Notifications
                ForEach(tasbeehRequests) { notif in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Label("New Tasbeeh Request", systemImage: "bell.fill")
                                .font(.headline)
                                .foregroundColor(.blue)
                            Spacer()
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                        }

                        Text("\(notif.groupTitle) sent you a request to read \(notif.tasbeehname.title) (count: \(notif.count))")
                            .font(.subheadline)
                            .foregroundColor(.primary)

                        HStack(spacing: 20) {
                            Button(action: {
                                // Accept action
                            }) {
                                Image(systemName: "checkmark.circle.fill")
                                    .resizable()
                                    .frame(width: 35, height: 35)
                                    .foregroundColor(.green)
                            }

                            Button(action: {
                                // Reject action
                            }) {
                                Image(systemName: "nosign")
                                    .resizable()
                                    .frame(width: 35, height: 35)
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: .gray.opacity(0.3), radius: 4, x: 0, y: 2)
                    .padding(.horizontal)
                }

                // Group Member Left Notifications
                ForEach(memberLeftNotifications) { notif in
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Group Member Left", systemImage: "person.2.slash")
                            .font(.headline)
                            .foregroundColor(.blue)

                        Text("User '\(notif.userName)' has left the tasbeeh '\(notif.tasbeehTitle)' in group '\(notif.groupName)'. Reason: \(notif.reason)")
                            .font(.subheadline)
                            .foregroundColor(.primary)

                        Button(action: {
                            // Reassign action
                        }) {
                            Text("Reassign")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: .gray.opacity(0.3), radius: 4, x: 0, y: 2)
                    .padding(.horizontal)
                }
            }
            .padding(.top)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            fetchTasbeehRequests()
            fetchMemberLeftNotifications()
        }
    }

    // MARK: - API Calls

    func fetchTasbeehRequests() {
        guard let url = URL(string: "http://192.168.137.1/DigitalTasbeehWithFriendsApi/api/User/Showallrequest?userId=\(userId)") else { return }

        URLSession.shared.dataTask(with: url) { data, _, error in
            if let data = data {
                do {
                    let raw = try JSONSerialization.jsonObject(with: data)
                    print("🔵 Tasbeeh Raw JSON:", raw)

                    let decoded = try JSONDecoder().decode([TasbeehRequestNotification].self, from: data)
                    DispatchQueue.main.async {
                        self.tasbeehRequests = decoded
                    }
                } catch {
                    print("❌ Tasbeeh Decode Error:", error)
                }
            }
        }.resume()
    }

    func fetchMemberLeftNotifications() {
        guard let url = URL(string: "http://192.168.137.1/DigitalTasbeehWithFriendsApi/api/User/Allleavegroupmember?userId=\(userId)") else { return }

        URLSession.shared.dataTask(with: url) { data, _, error in
            if let data = data {
                do {
                    let raw = try JSONSerialization.jsonObject(with: data)
                    print("🟣 Left Raw JSON:", raw)

                    let decoded = try JSONDecoder().decode([MemberLeftNotification].self, from: data)
                    DispatchQueue.main.async {
                        self.memberLeftNotifications = decoded
                    }
                } catch {
                    print("❌ Left Decode Error:", error)
                }
            }
        }.resume()
    }
}

// MARK: - Preview

struct NotificationView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationView(userId: 1)
    }
}

