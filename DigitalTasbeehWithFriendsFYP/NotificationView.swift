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

    // Alerts
    @State private var alertMsg: String? = nil
    @State private var showAlert: Bool = false

    // Per-item busy state (disable Accept/Reject while calling API)
    @State private var busyRequestIds: Set<Int> = []

    // Base URL
    private let base = "http://192.168.137.1/DigitalTasbeehWithFriendsApi"

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
                            if busyRequestIds.contains(notif.id) {
                                ProgressView().scaleEffect(0.9)
                            } else {
                                Image(systemName: "info.circle")
                                    .foregroundColor(.blue)
                            }
                        }

                        Text("\(notif.groupTitle) sent you a request to read \(notif.tasbeehname.title) (count: \(notif.count))")
                            .font(.subheadline)
                            .foregroundColor(.primary)

                        HStack(spacing: 20) {
                            Button(action: { acceptTasbeehRequest(notif) }) {
                                Image(systemName: "checkmark.circle.fill")
                                    .resizable()
                                    .frame(width: 35, height: 35)
                                    .foregroundColor(.green)
                            }
                            .disabled(busyRequestIds.contains(notif.id))

                            Button(action: { rejectTasbeehRequest(notif) }) {
                                Image(systemName: "nosign")
                                    .resizable()
                                    .frame(width: 35, height: 35)
                                    .foregroundColor(.red)
                            }
                            .disabled(busyRequestIds.contains(notif.id))
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
                            // TODO: wire reassign endpoint if needed
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
        .alert("Message", isPresented: $showAlert) {
            Button("OK", role: .cancel) { alertMsg = nil }
        } message: {
            Text(alertMsg ?? "")
        }
    }

    // MARK: - API Calls (Fetch)

    func fetchTasbeehRequests() {
        guard let url = URL(string: "\(base)/api/User/Showallrequest?userId=\(userId)") else { return }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data {
                do {
                    // Debug (optional)
                    // let raw = try JSONSerialization.jsonObject(with: data)
                    // print("🔵 Tasbeeh Raw JSON:", raw)

                    let decoded = try JSONDecoder().decode([TasbeehRequestNotification].self, from: data)
                    DispatchQueue.main.async {
                        self.tasbeehRequests = decoded
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.alertMsg = "Failed to load requests: \(error.localizedDescription)"
                        self.showAlert = true
                    }
                }
            }
        }.resume()
    }

    func fetchMemberLeftNotifications() {
        guard let url = URL(string: "\(base)/api/User/Allleavegroupmember?userId=\(userId)") else { return }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data {
                do {
                    // Debug (optional)
                    // let raw = try JSONSerialization.jsonObject(with: data)
                    // print("🟣 Left Raw JSON:", raw)

                    let decoded = try JSONDecoder().decode([MemberLeftNotification].self, from: data)
                    DispatchQueue.main.async {
                        self.memberLeftNotifications = decoded
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.alertMsg = "Failed to load member-left: \(error.localizedDescription)"
                        self.showAlert = true
                    }
                }
            }
        }.resume()
    }

    // MARK: - API Calls (Actions)

    /// Accept request → call API → on success, remove from list (optimistic UI with rollback)
    func acceptTasbeehRequest(_ notif: TasbeehRequestNotification) {
        guard !busyRequestIds.contains(notif.id) else { return }
        busyRequestIds.insert(notif.id)

        // Optimistic UI
        let oldList = tasbeehRequests
        tasbeehRequests.removeAll { $0.id == notif.id }

        // TODO: If your backend route/param names differ, replace below path:
        let path = "\(base)/api/User/Acceptrequest?userId=\(userId)&requestId=\(notif.id)"
        guard let url = URL(string: path) else {
            busyRequestIds.remove(notif.id)
            return
        }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"

        URLSession.shared.dataTask(with: req) { data, resp, err in
            DispatchQueue.main.async {
                self.busyRequestIds.remove(notif.id)

                if let err = err {
                    self.tasbeehRequests = oldList
                    self.alertMsg = "Accept failed: \(err.localizedDescription)"
                    self.showAlert = true
                    return
                }
                if let http = resp as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                    self.tasbeehRequests = oldList
                    let body = String(data: data ?? Data(), encoding: .utf8) ?? ""
                    self.alertMsg = "Accept HTTP \(http.statusCode): \(body)"
                    self.showAlert = true
                    return
                }

                // Optional: refresh list after success
                // self.fetchTasbeehRequests()
            }
        }.resume()
    }

    /// Reject request → call API → on success, remove from list (optimistic UI with rollback)
    func rejectTasbeehRequest(_ notif: TasbeehRequestNotification) {
        guard !busyRequestIds.contains(notif.id) else { return }
        busyRequestIds.insert(notif.id)

        // Optimistic UI
        let oldList = tasbeehRequests
        tasbeehRequests.removeAll { $0.id == notif.id }

        // TODO: If your backend route/param names differ, replace below path:
        let path = "\(base)/api/User/Rejectrequest?userId=\(userId)&requestId=\(notif.id)"
        guard let url = URL(string: path) else {
            busyRequestIds.remove(notif.id)
            return
        }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"

        URLSession.shared.dataTask(with: req) { data, resp, err in
            DispatchQueue.main.async {
                self.busyRequestIds.remove(notif.id)

                if let err = err {
                    self.tasbeehRequests = oldList
                    self.alertMsg = "Reject failed: \(err.localizedDescription)"
                    self.showAlert = true
                    return
                }
                if let http = resp as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                    self.tasbeehRequests = oldList
                    let body = String(data: data ?? Data(), encoding: .utf8) ?? ""
                    self.alertMsg = "Reject HTTP \(http.statusCode): \(body)"
                    self.showAlert = true
                    return
                }

                // Optional: refresh list after success
                // self.fetchTasbeehRequests()
            }
        }.resume()
    }
}

// MARK: - Preview

struct NotificationView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            NotificationView(userId: 1)
        }
    }
}

