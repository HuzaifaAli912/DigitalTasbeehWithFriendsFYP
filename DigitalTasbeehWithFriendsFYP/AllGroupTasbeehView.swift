import SwiftUI

// MARK: - Group Tasbeeh Item Model
struct GroupTasbeehItem: Identifiable, Codable {
    let id: Int
    let title: String
    let goal: Int
    let achieved: Int
    let remaining: Int?
    let deadline: String?
    let schedule: String?

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

// MARK: - Main View
struct AllGroupTasbeehView: View {
    let groupId: Int
    let userId: Int
    let groupName: String
    let adminId: Int = 100 // ← Replace with dynamic value if needed

    @State private var tasbeehs: [GroupTasbeehItem] = []
    @State private var isLoading = false
    @State private var alertError: AlertError?

    // Navigation
    @State private var goAddMembers = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Top Header
                HStack {
                    Spacer()
                    Text(groupName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    Spacer()

                    // Menu with only Add Members
                    Menu {
                        Button("Add Members") {
                            goAddMembers = true   // navigate
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .rotationEffect(.degrees(90))
                            .font(.title2)
                            .foregroundColor(.black)
                    }
                }
                .padding()

                // Hidden NavigationLink (programmatic)
                NavigationLink(
                    destination: AddingMemberView(
                        groupId: groupId,   // 👈 order: groupId first
                        userId: userId
                    ),
                    isActive: $goAddMembers
                ) { EmptyView() }
                .hidden()

                // Loader
                if isLoading {
                    ProgressView("Loading Tasbeehs...").padding()
                }

                // Tasbeeh List
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(tasbeehs) { tasbeeh in
                            NavigationLink(
                                destination: TasbeehCounterView(
                                    tasbeeh: TasbeehCounterModel(
                                        title: tasbeeh.title,
                                        arabicText: "سُبْحَانَ ٱللَّٰهِ", // Placeholder
                                        currentCount: tasbeeh.achieved,
                                        totalCount: tasbeeh.goal,
                                        // 👇 yeh 4 values MODEL me pass hongi (view par nahi)
                                        tasbeehId: tasbeeh.id,
                                        groupId: groupId,
                                        userId: userId,
                                        adminId: adminId
                                    )
                                )
                            ) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(tasbeeh.title)
                                        .font(.headline)
                                        .padding(.vertical, 6)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .foregroundColor(.white)
                                        .background(Color.blue)
                                        .cornerRadius(6)

                                    HStack {
                                        Text("Goal: \(tasbeeh.goal)")
                                        Spacer()
                                        Text("Achieved: \(tasbeeh.achieved)")
                                        Spacer()
                                        Text("Remaining: \(tasbeeh.remaining ?? 0)")
                                    }
                                    .font(.subheadline)
                                    .foregroundColor(.black)

                                    HStack {
                                        Label("Deadline: \(tasbeeh.deadline ?? "N/A")", systemImage: "calendar")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(radius: 1)
                                .padding(.horizontal)
                            }
                        }
                    }
                }

                Spacer()
            }
            .onAppear { fetchGroupTasbeehs() }
            .alert(item: $alertError) { error in
                Alert(title: Text("Error"), message: Text(error.message), dismissButton: .default(Text("OK")))
            }
        }
    }

    // MARK: - API Fetch
    func fetchGroupTasbeehs() {
        guard groupId > 0 else {
            self.alertError = AlertError(message: "Invalid Group ID.")
            return
        }

        isLoading = true
        alertError = nil

        let urlString = "http://192.168.137.1/DigitalTasbeehWithFriendsApi/api/Group/Tasbeehlogs?groupid=\(groupId)&userid=\(userId)"

        guard let url = URL(string: urlString) else {
            self.alertError = AlertError(message: "Invalid URL.")
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            DispatchQueue.main.async {
                isLoading = false

                if let error = error {
                    self.alertError = AlertError(message: "Network error: \(error.localizedDescription)")
                    return
                }

                guard let data = data else {
                    self.alertError = AlertError(message: "No data received from server.")
                    return
                }

                if let jsonStr = String(data: data, encoding: .utf8) {
                    print("📦 Raw Response: \(jsonStr)")
                }

                do {
                    let decoded = try JSONDecoder().decode([GroupTasbeehItem].self, from: data)
                    self.tasbeehs = decoded
                } catch {
                    self.alertError = AlertError(message: "JSON decode error: \(error.localizedDescription)")
                }
            }
        }.resume()
    }
}

// MARK: - Preview
struct AllGroupTasbeehView_Previews: PreviewProvider {
    static var previews: some View {
        AllGroupTasbeehView(groupId: 1, userId: 1, groupName: "Sample Group")
    }
}

