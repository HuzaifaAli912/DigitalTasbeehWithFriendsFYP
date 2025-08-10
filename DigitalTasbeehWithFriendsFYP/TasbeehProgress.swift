import SwiftUI

// MARK: - Models
struct GroupMemberProgress: Identifiable, Codable {
    let id = UUID()
    let Username: String
    let CurrentCount: Int
    let AssignCount: Int
    let Adminid: Int
    let userid: Int
    let rating: Double?
}

struct GroupMemberRating: Codable {
    let groupid: Int
    let userid: Int
    let rating: Double
    let tasbeehid: Int
}

struct TasbeehProgressView: View {
    let groupid: Int
    let userId: Int
    let adminId: Int
    let tasbeehId: Int
    let title: String

    @State private var groupProgress: [GroupMemberProgress] = []
    @State private var achieved: Int = 0
    @State private var goal: Int = 0
    @State private var progressPercent: CGFloat = 0

    @State private var showRatingModal = false
    @State private var selectedUserName = ""
    @State private var selectedUserId: Int?
    @State private var ratingValue = ""
    @State private var ratingError = ""
    @State private var timer: Timer?

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text(title)
                    .font(.title2.bold())
                    .frame(maxWidth: .infinity)

                HStack {
                    Text("\(achieved)/\(goal)")
                        .font(.headline)
                        .frame(width: 60)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(.systemGray5))
                                .frame(height: 25)

                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.blue)
                                .frame(width: progressPercent * geo.size.width, height: 25)
                        }
                    }
                }
                .frame(height: 30)

                Text("Members Progress")
                    .font(.headline)

                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(groupProgress) { member in
                            memberRowView(member: member)
                        }
                    }
                    .padding(.horizontal)
                }

                Spacer()
            }
            .padding()
            .onAppear {
                fetchGroupProgress()
                updateOnlineStatus(true)
                startOnlineStatusTimer()
            }
            .onDisappear {
                updateOnlineStatus(false)
                stopTimer()
            }
            .sheet(isPresented: $showRatingModal) {
                VStack(spacing: 20) {
                    Text(selectedUserName)
                        .font(.title3.bold())
                        .padding(.top)

                    HStack(spacing: 10) {
                        ForEach(1..<6) { index in
                            Image(systemName: index <= Int(ratingValue) ?? 0 ? "star.fill" : "star")
                                .resizable()
                                .frame(width: 30, height: 30)
                                .foregroundColor(.yellow)
                                .onTapGesture {
                                    ratingValue = "\(index)"
                                    ratingError = ""
                                }
                        }
                    }
                    .padding()

                    if !ratingError.isEmpty {
                        Text(ratingError)
                            .foregroundColor(.red)
                            .font(.caption)
                    }

                    Button(action: {
                        submitRating()
                    }) {
                        Text("Submit")
                            .font(.title3.bold())
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(40)
                            .padding(.horizontal)
                    }

                    Spacer()
                }
                .background(Color.white)
                .presentationDetents([.height(300)])
            }
        }
    }

    // MARK: - Member Row View
    @ViewBuilder
    func memberRowView(member: GroupMemberProgress) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(member.Username)
                    .font(.body.bold())

                if let rating = member.rating {
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text(String(format: "%.1f", rating))
                            .font(.caption)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text("\(member.CurrentCount)/\(member.AssignCount)")
                .font(.body)
                .frame(width: 80, alignment: .center)

            if member.userid == member.Adminid {
                Text("Admin")
                    .foregroundColor(.green)
                    .font(.body.bold())
            } else {
                if userId == member.Adminid && member.userid != userId {
                    Button(action: {
                        selectedUserName = member.Username
                        selectedUserId = member.userid
                        ratingValue = ""
                        ratingError = ""
                        showRatingModal = true
                    }) {
                        Text("Rate")
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(Color.green)
                            .clipShape(Capsule())
                    }
                } else {
                    Text("Member")
                        .font(.body)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(Color.blue.opacity(0.2))
        .cornerRadius(12)
    }

    // MARK: - Timer
    func startOnlineStatusTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { _ in
            updateOnlineStatus(true)
        }
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - API: Fetch Progress
    func fetchGroupProgress() {
        let urlString = "http://192.168.137.1/DigitalTasbeehWithFriendsApi/api/Group/TasbeehProgressAndMembersProgress?groupid=\(groupid)&tasbeehid=\(tasbeehId)"
        guard let url = URL(string: urlString) else { return }

        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else { return }
            do {
                let result = try JSONDecoder().decode([GroupMemberProgress].self, from: data)
                DispatchQueue.main.async {
                    groupProgress = result
                    achieved = result.reduce(0) { $0 + $1.CurrentCount }
                    goal = result.reduce(0) { $0 + $1.AssignCount }
                    progressPercent = CGFloat(goal == 0 ? 0 : Double(achieved) / Double(goal))
                }
            } catch {
                print("Decoding error: \(error)")
            }
        }.resume()
    }

    // MARK: - API: Update Online Status
    func updateOnlineStatus(_ online: Bool) {
        let status = online ? "online" : "offline"
        let urlString = "http://192.168.137.1/DigitalTasbeehWithFriendsApi/api/User/UpdateOnlineStatus?UserID=\(userId)&Status=\(status)"
        guard let url = URL(string: urlString) else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        URLSession.shared.dataTask(with: request).resume()
    }

    // MARK: - API: Submit Rating
    func submitRating() {
        guard let uid = selectedUserId,
              let rating = Double(ratingValue),
              rating >= 1, rating <= 5 else {
            ratingError = "Please enter a valid rating between 1 and 5."
            return
        }

        let ratingModel = GroupMemberRating(
            groupid: groupid,
            userid: uid,
            rating: rating,
            tasbeehid: tasbeehId
        )

        // ✅ Debug log
        print("Submitting Rating → \(ratingModel)")

        guard let jsonData = try? JSONEncoder().encode(ratingModel) else {
            print("Failed to encode JSON")
            return
        }

        guard let url = URL(string: "http://192.168.137.1/DigitalTasbeehWithFriendsApi/api/AssignTasbeeh/Rategroupmember") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        // Inside URLSession.shared.dataTask completion in submitRating()
        URLSession.shared.dataTask(with: request) { _, _, error in
            DispatchQueue.main.async {
                if error != nil {
                    ratingError = "Failed to submit. Try again."
                } else {
                    // ✅ Instantly update rating in local array
                    if let index = groupProgress.firstIndex(where: { $0.userid == uid }) {
                        var updatedMember = groupProgress[index]
                        updatedMember = GroupMemberProgress(
                            Username: updatedMember.Username,
                            CurrentCount: updatedMember.CurrentCount,
                            AssignCount: updatedMember.AssignCount,
                            Adminid: updatedMember.Adminid,
                            userid: updatedMember.userid,
                            rating: rating // instantly set the new rating
                        )
                        groupProgress[index] = updatedMember
                    }

                    showRatingModal = false
                    ratingValue = ""
                    // fetchGroupProgress() // ❌ No need to call if you want instant update
                }
            }
        }.resume()

    }
}


// MARK: - Preview
struct TasbeehProgressView_Previews: PreviewProvider {
    static var previews: some View {
        TasbeehProgressView(groupid: 1, userId: 1071, adminId: 100, tasbeehId: 200, title: "Tasbeeh Faitha")
    }
}
