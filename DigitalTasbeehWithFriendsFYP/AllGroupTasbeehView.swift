import SwiftUI
import Combine

// MARK: - Alert

// MARK: - Push updates from Counter
extension Notification.Name {
    static let tasbeehProgressDidChange = Notification.Name("tasbeehProgressDidChange")
}

// MARK: - Model
struct GroupTasbeehItem: Identifiable, Codable {
    let id: Int
    let title: String
    let goal: Int
    var achieved: Int          // var so we can live-update
    var remaining: Int?        // may be nil from API; we recompute
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

struct AllGroupTasbeehView: View {
    let groupId: Int
    let userId: Int
    let groupName: String
    let adminId: Int = 100 // adjust if you have a real admin id

    @State private var tasbeehs: [GroupTasbeehItem] = []
    @State private var isLoading = false
    @State private var alertError: AlertError?

    @State private var goAddMembers = false

    private let baseURL = "http://192.168.137.1/DigitalTasbeehWithFriendsApi"

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Spacer()
                    Text(groupName)
                        .font(.title2).bold()
                    Spacer()
                    Menu {
                        Button("Add Members") { goAddMembers = true }
                    } label: {
                        Image(systemName: "ellipsis")
                            .rotationEffect(.degrees(90))
                            .font(.title2)
                    }
                }
                .padding()

                // Hidden nav to add members
                NavigationLink(
                    destination: AddingMemberView(groupId: groupId, userId: userId),
                    isActive: $goAddMembers
                ) { EmptyView() }
                .hidden()

                if isLoading { ProgressView("Loading Tasbeehs...").padding() }

                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(tasbeehs) { t in
                            NavigationLink(
                                destination: TasbeehCounterView(
                                    tasbeeh: TasbeehCounterModel(
                                        title: t.title,
                                        arabicText: "سُبْحَانَ ٱللَّٰهِ", // placeholder
                                        currentCount: t.achieved,
                                        totalCount: t.goal,
                                        tasbeehId: t.id,
                                        groupId: groupId,
                                        userId: userId,
                                        adminId: adminId
                                    )
                                )
                            ) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(t.title)
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .padding(.vertical, 6)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color.blue)
                                        .cornerRadius(6)

                                    HStack {
                                        Text("Goal: \(t.goal)")
                                        Spacer()
                                        Text("Achieved: \(t.achieved)")
                                        Spacer()
                                        Text("Remaining: \(t.remaining ?? max(0, t.goal - t.achieved))")
                                    }
                                    .font(.subheadline)

                                    HStack {
                                        Label("Deadline: \(t.deadline ?? "N/A")", systemImage: "calendar")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        Spacer()
                                        Image(systemName: "chevron.right").foregroundColor(.gray)
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
                .refreshable { fetchGroupTasbeehs(force: true) } // pull-to-refresh
            }
            .background(Color(.systemGray6))
            .onAppear { fetchGroupTasbeehs() } // refetch on return
            .onReceive(NotificationCenter.default.publisher(for: .tasbeehProgressDidChange)) { note in
                guard
                    let info = note.userInfo,
                    let changedId = info["tasbeehId"] as? Int,
                    let newAchieved = info["achieved"] as? Int
                else { return }

                if let idx = tasbeehs.firstIndex(where: { $0.id == changedId }) {
                    tasbeehs[idx].achieved = newAchieved
                    tasbeehs[idx].remaining = max(0, tasbeehs[idx].goal - newAchieved)
                }
            }
            .alert(item: $alertError) { e in
                Alert(title: Text("Message"), message: Text(e.message), dismissButton: .default(Text("OK")))
            }
        }
    }

    // MARK: - API
    private func fetchGroupTasbeehs(force: Bool = false) {
        if isLoading && !force { return }
        isLoading = true
        alertError = nil

        // GET /api/Group/Tasbeehlogs?groupid=&userid=
        let urlStr = "\(baseURL)/api/Group/Tasbeehlogs?groupid=\(groupId)&userid=\(userId)"
        guard let url = URL(string: urlStr) else {
            isLoading = false
            alertError = AlertError(message: "Invalid URL")
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, err in
            DispatchQueue.main.async {
                isLoading = false
                if let err = err {
                    alertError = AlertError(message: "Network error: \(err.localizedDescription)")
                    return
                }
                guard let data = data else {
                    alertError = AlertError(message: "No data from server")
                    return
                }

                do {
                    var list = try JSONDecoder().decode([GroupTasbeehItem].self, from: data)
                    for i in list.indices {
                        if list[i].remaining == nil {
                            list[i].remaining = max(0, list[i].goal - list[i].achieved)
                        }
                    }
                    tasbeehs = list
                } catch {
                    alertError = AlertError(message: "Decode error: \(error.localizedDescription)")
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

