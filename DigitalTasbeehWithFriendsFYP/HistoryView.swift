import SwiftUI

// MARK: - Model

struct HistoryItem: Identifiable, Codable {
    let id: Int
    let tasbeehtitle: String
    let type: String
    let groupname: String?
    let assignCount: Int?
    let goal: Int?
    let tasbeehAchived: Int?
    let tasbeehgoal: Int?
    let tasbeebday: String?
    let tasbeehstarttime: String?
    let tasbeehendtime: String?
    let userstarttime: String?
    let userendtime: String?
    let userFlag: Int?
    let tasbeehFlag: Int?
    let startdate: String?  // for single
    let enddate: String?    // for single
    let achieved: Int?      // for single
    let flag: Int?          // for single

    enum CodingKeys: String, CodingKey {
        case tasbeehtitle = "Tasbeehtitle"
        case type, groupname = "Groupname"
        case assignCount = "AssignCount"
        case goal = "Goal"
        case tasbeehAchived = "TasbeehAchived"
        case tasbeehgoal = "Tasbeehgoal"
        case tasbeebday = "Tasbeebday"
        case tasbeehstarttime = "tasbeebstarttime"
        case tasbeehendtime = "tasbeeendtime"
        case userstarttime = "userstarrtime"
        case userendtime = "userendtime"
        case userFlag, tasbeehFlag
        case startdate, enddate, achieved, flag
        case id = "Tasbeehid"
    }
}

// MARK: - ViewModel

class HistoryViewModel: ObservableObject {
    @Published var items: [HistoryItem] = []

    func fetchHistory(for userId: Int) {
        guard let url = URL(string: "http://192.168.137.1/DigitalTasbeehWithFriendsApi/api/User/getallgrouptasbeehhistory?userId=\(userId)") else { return }

        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else {
                print("API error: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            do {
                let decoded = try JSONDecoder().decode([HistoryItem].self, from: data)
                DispatchQueue.main.async {
                    self.items = decoded
                }
            } catch {
                print("Decoding error: \(error)")
            }
        }.resume()
    }
}

// MARK: - Main View

struct HistoryView: View {
    @StateObject private var viewModel = HistoryViewModel()
    var userId: Int

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    ForEach(viewModel.items) { item in
                        HistoryCardView(item: item)
                    }
                }
                .padding()
            }
            .navigationTitle("History")
            .onAppear {
                viewModel.fetchHistory(for: userId)
            }
        }
    }
}

// MARK: - Card View

struct HistoryCardView: View {
    let item: HistoryItem

    var status: String {
        if item.type == "group" {
            return item.userFlag == 3 ? "Completed" : "Leaved"
        } else {
            return item.flag == 3 ? "Completed" : "Leaved"
        }
    }

    var statusColor: Color {
        status == "Completed" ? .green : .orange
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(item.tasbeehtitle)
                    .font(.system(size: 18, weight: .semibold))
                Spacer()
                Text(status)
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(statusColor)
                    .foregroundColor(.white)
                    .cornerRadius(20)
            }

            Text("Type: \(item.type)")
                .foregroundColor(.gray)
                .font(.subheadline)

            if let group = item.groupname {
                Text("Group: \(group)")
                    .foregroundColor(.gray)
                    .font(.subheadline)
            }

            VStack(alignment: .leading, spacing: 8) {
                GroupBox {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("ASSIGNED COUNT")
                            .font(.caption)
                            .foregroundColor(.purple)
                        Text("\(item.assignCount ?? 0) / \(item.assignCount ?? 0)")
                    }
                }

                GroupBox {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("TASBEEH ACHIEVED")
                            .font(.caption)
                            .foregroundColor(.purple)
                        Text("\(item.achieved ?? item.tasbeehAchived ?? 0) / \(item.goal ?? item.tasbeehgoal ?? 0)")
                    }
                }

                GroupBox {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("TIME DETAILS")
                            .font(.caption)
                            .foregroundColor(.purple)
                        Text("Started: \(item.startdate ?? item.tasbeehstarttime ?? "-")")
                            .foregroundColor(.blue)
                        Text("Ended: \(item.enddate ?? item.tasbeehendtime ?? "-")")
                            .foregroundColor(.orange)
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(radius: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(statusColor, lineWidth: 3)
        )
    }
}

// MARK: - Preview

struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryView(userId: 1)
    }
}

