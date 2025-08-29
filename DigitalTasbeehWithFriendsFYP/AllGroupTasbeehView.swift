import SwiftUI
import Combine

// MARK: - Push updates from Counter
extension Notification.Name {
    static let tasbeehProgressDidChange = Notification.Name("tasbeehProgressDidChange")
}


// MARK: - Model
struct GroupTasbeehItem: Identifiable, Codable {
    let id: Int
    let title: String
    let goal: Int
    var achieved: Int
    var remaining: Int?
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
struct TasbeehRating: Codable {
    let groupid: Int
    let userid: Int
    let rating: Double
    let tasbeehid: Int
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

    // UPDATE feature states
    @State private var showUpdateSheet = false
    @State private var selectedTasbeeh: GroupTasbeehItem?
    @State private var newGoalText: String = ""
    @State private var isSavingUpdate = false




//Rating

 @State private var showRatingModal = false
    @State private var selectedUserName = ""
    @State private var ratingValue = ""
    @State private var ratingno = ""
    @State private var ratingnu = ""
    
    @State private var ratingError = ""
    @State private var timer: Timer?











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
                            VStack(alignment: .leading, spacing: 8) {

                                // Title row acts as OPEN (Counter) navigation
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
                                    HStack {
                                        Text(t.title)
                                            .font(.headline)
                                            .foregroundColor(.white)
                                            .padding(.vertical, 6)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.white.opacity(0.9))

                                    }
                                    .padding(.horizontal, 8)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.blue)
                                    .cornerRadius(6)
                                }
                                .buttonStyle(.plain)

                                // Counts
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
                                }

                                // UPDATE button (only new addition)
                                HStack {
                                    Spacer()
                                    Button {
                                        selectedTasbeeh = t
                                        newGoalText = String(t.goal)
                                        showUpdateSheet = true
                                    } label: {
                                        Label("Update", systemImage: "square.and.pencil")
                                            .font(.subheadline).bold()
                                    }
                                    .buttonStyle(.bordered)
                                }
                                .padding(.top, 4)

                            }
                            
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(radius: 1)
                            .padding(.horizontal)
                            Button(action: {
                        
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








.sheet(isPresented: $showRatingModal) {
                VStack(spacing: 20) {
                    Text(selectedUserName)
                        .font(.title3.bold())
                        .padding(.top)

                    VStack(spacing: 10) {
                        ForEach(1..<2) { index in
//                            Image(systemName: index <= Int(ratingValue) ?? 0 ? "star.fill" : "star")
//                               Text("ease of reading")
//                                .frame(width: 400, height: 30)
//                                .foregroundColor(.black)
//                                Spacer()
//
//                              Text("Effectiveness")
//                                .frame(width: 400, height: 20)
//                                .foregroundColor(.black)
//                                Spacer()
//
                            
                            Section(header: Text("Effectiveness")) {
                                TextField("Enter Rating", text: $ratingValue)
                                    .keyboardType(.numberPad)
                            }
                            Section(header: Text("Ease of Reading")) {
                                TextField("Enter Rating", text: $ratingno)
                                    .keyboardType(.numberPad)
                            }
                            Section(header: Text("Spirtual Immpact")) {
                                TextField("Enter Rating", text: $ratingnu)
                                    .keyboardType(.numberPad)
                            }
//                              Text("SPirtual impact")
//
//                                .frame(width: 400, height: 30)
//                                .foregroundColor(.black)
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






















            // UPDATE Sheet
            .sheet(isPresented: $showUpdateSheet) {
                VStack(spacing: 16) {
                    Text("Update Tasbeeh Goal")
                        .font(.title3).bold()

                    if let sel = selectedTasbeeh {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Title: \(sel.title)")
                            Text("Current Goal: \(sel.goal)")
                            Text("Achieved: \(sel.achieved)")
                            Text("Remaining: \(max(0, sel.goal - sel.achieved))")
                                .foregroundColor(.gray)
                        }

                        TextField("New Goal (e.g., 100)", text: $newGoalText)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)

                        HStack {
                            Button("Cancel") {
                                showUpdateSheet = false
                            }
                            .buttonStyle(.bordered)

                            Spacer()

                            Button {
                                guard let newGoal = Int(newGoalText.trimmingCharacters(in: .whitespaces)),
                                      newGoal > 0 else {
                                    alertError = AlertError(message: "Please enter a valid number (> 0).")
                                    return
                                }
                                // Optional rule if required:
                                // if newGoal < sel.achieved {
                                //     alertError = AlertError(message: "New goal cannot be less than achieved.")
                                //     return
                                // }

                                isSavingUpdate = true
                                updateTasbeehGoal(tasbeehId: sel.id, newGoal: newGoal)
                            } label: {
                                if isSavingUpdate {
                                    ProgressView()
                                } else {
                                    Text("Save").bold()
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(isSavingUpdate)
                        }
                    } else {
                        Text("No tasbeeh selected.")
                    }
                }
                .padding()
                .presentationDetents([.fraction(0.5)])
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

    // MARK: - Update Goal API
    private func updateTasbeehGoal(tasbeehId: Int, newGoal: Int) {
        alertError = nil

        guard let url = URL(string: "\(baseURL)/api/Group/UpdateTasbeehGoal") else {
            isSavingUpdate = false
            alertError = AlertError(message: "Invalid URL")
            return
        }

        let body: [String: Any] = [
            "groupid": groupId,
            "tasbeehid": tasbeehId,
            "goal": newGoal
        ]

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])

        URLSession.shared.dataTask(with: req) { data, resp, err in
            DispatchQueue.main.async {
                isSavingUpdate = false

                if let err = err {
                    alertError = AlertError(message: "Network error: \(err.localizedDescription)")
                    return
                }

                if let http = resp as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                    alertError = AlertError(message: "Server error: \(http.statusCode)")
                    return
                }

                // Success → local state update & recompute remaining
                if let idx = tasbeehs.firstIndex(where: { $0.id == tasbeehId }) {
                    let old = tasbeehs[idx]
                    let updated = GroupTasbeehItem(
                        id: old.id,
                        title: old.title,
                        goal: newGoal,
                        achieved: old.achieved,
                        remaining: max(0, newGoal - old.achieved),
                        deadline: old.deadline,
                        schedule: old.schedule
                    )
                    tasbeehs[idx] = updated
                }

                showUpdateSheet = false
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



