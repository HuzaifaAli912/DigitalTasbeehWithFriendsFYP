import SwiftUI



// MARK: - Model
struct TasbeehCounterModel {
    let title: String
    let arabicText: String
    let currentCount: Int
    let totalCount: Int
    let tasbeehId: Int    // NOTE: this is GroupTasbeeh.ID as per list API
    let groupId: Int
    let userId: Int
    let adminId: Int
}

struct TasbeehCounterView: View {
    let tasbeeh: TasbeehCounterModel
    @State private var count: Int
    @State private var progress: CGFloat
    @State private var showProgressScreen = false
    @State private var isPosting = false
    @State private var lastError: String?

    private let baseURL = "http://192.168.137.1/DigitalTasbeehWithFriendsApi"

    init(tasbeeh: TasbeehCounterModel) {
        self.tasbeeh = tasbeeh
        _count = State(initialValue: tasbeeh.currentCount)
        _progress = State(initialValue: CGFloat(tasbeeh.currentCount) / CGFloat(max(tasbeeh.totalCount, 1)))
    }

    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Spacer()
                Text(tasbeeh.title).font(.title2).bold()
                Spacer()
                Menu {
                    Button("Progress") { showProgressScreen = true }
                    Button(role: .destructive) { /* close tasbeeh flow here */ } label: {
                        Text("Close Tasbeeh")
                    }
                } label: {
                    Image(systemName: "slider.horizontal.3").font(.title2)
                }
            }
            .padding(.horizontal)

            // Navigation to progress page (existing)
            NavigationLink(
                destination: TasbeehProgressView(
                    groupid: tasbeeh.groupId,
                    userId: tasbeeh.userId,
                    adminId: tasbeeh.adminId,
                    tasbeehId: tasbeeh.tasbeehId,
                    title: tasbeeh.title
                ),
                isActive: $showProgressScreen
            ) { EmptyView() }

            // Circular Progress
            VStack {
                ZStack {
                    Circle().stroke(Color.gray.opacity(0.2), lineWidth: 15)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(Color.blue, style: StrokeStyle(lineWidth: 15, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text("\(Int(progress * 100))%").font(.title).bold()
                }
                .frame(width: 140, height: 140)

                Text("\(count) / \(tasbeeh.totalCount)").font(.headline)
            }

            // Progress dots
            HStack(spacing: 12) {
                ForEach(0..<7, id: \.self) { i in
                    Circle()
                        .fill(i < (count * 7 / max(tasbeeh.totalCount, 1)) ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 12, height: 12)
                }
            }

            // Arabic + counts
            HStack(spacing: 10) {
                Text("\(count)")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Circle().fill(Color.blue))

                Text(tasbeeh.arabicText)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 20))

                Text("\(tasbeeh.totalCount)")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Circle().fill(Color.blue))
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(radius: 2)
            .padding(.horizontal)

            Spacer()

            // Count button
            Button(action: onTapCount) {
                VStack {
                    Text("Count").font(.title).bold()
                    if isPosting { Text("Saving…").font(.footnote).opacity(0.8) }
                }
                .frame(maxWidth: .infinity, minHeight: 140)
                .background(Color.blue.opacity(0.9))
                .foregroundColor(.white)
                .cornerRadius(12)
                .padding(.horizontal)
            }
            .disabled(isPosting)

            if let err = lastError {
                Text(err).font(.footnote).foregroundColor(.red).padding(.top, 4)
            }
        }
        .padding(.top)
        .background(Color(.systemGray6))
        .onAppear { resumeFromServer() } // fetch latest when opened
    }

    // MARK: - Actions

    private func onTapCount() {
        guard count < tasbeeh.totalCount else { return }

        // Optimistic UI
        count += 1
        withAnimation { progress = CGFloat(count) / CGFloat(max(tasbeeh.totalCount, 1)) }

        // Call increment API
        incrementOnServer(delta: 1) { serverCurrent, serverTotalAchieved in
            if let serverCurrent = serverCurrent {
                // Trust server for current personal count if it returns
                self.count = serverCurrent
                self.progress = CGFloat(serverTotalAchieved ?? self.count) / CGFloat(max(self.tasbeeh.totalCount, 1))
            }
            // Notify list to live update Achieved (we use personal count if group total not returned)
            NotificationCenter.default.post(
                name: .tasbeehProgressDidChange,
                object: nil,
                userInfo: ["tasbeehId": tasbeeh.tasbeehId, "achieved": serverTotalAchieved ?? self.count]
            )
        }
    }

    // MARK: - Networking

    /// GET your existing "TasbeehProgressAndMembersProgress" to resume current.
    private func resumeFromServer() {
        // Example route: /api/Group/TasbeehProgressAndMembersProgress?groupId=&tasbeehid=
        // NOTE: Your controller signature is (int groupId, int tasbeehid). It returns a list (members progress).
        // We will sum CurrentCount of all active members to compute group Achieved if needed,
        // and also try to find this user's own CurrentCount to resume the counter.

        let urlStr = "\(baseURL)/api/Group/TasbeehProgressAndMembersProgress?groupId=\(tasbeeh.groupId)&tasbeehid=\(tasbeeh.tasbeehId)"
        guard let url = URL(string: urlStr) else { return }

        URLSession.shared.dataTask(with: url) { data, resp, err in
            DispatchQueue.main.async {
                guard err == nil,
                      let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode),
                      let data = data
                else { return }

                // Expecting an array of objects with fields:
                // { CurrentCount, Achieved, userid, ... }
                if let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                    // this user's currentCount
                    let my = arr.first(where: { ($0["userid"] as? Int) == tasbeeh.userId })
                    let myCurrent = (my?["CurrentCount"] as? Int) ?? count

                    // group achieved (prefer controller value if present, else sum)
                    let groupAchieved = arr.compactMap { $0["CurrentCount"] as? Int }.reduce(0, +)

                    self.count = myCurrent
                    self.progress = CGFloat(groupAchieved) / CGFloat(max(self.tasbeeh.totalCount, 1))
                }
            }
        }.resume()
    }

    /// POST your existing "IncremnetInTasbeeh" (spelling as in controller) with query params.
    private func incrementOnServer(delta: Int, done: @escaping (_ serverCurrent: Int?, _ serverGroupAchieved: Int?) -> Void) {
        // TODO: If you changed to POST body version, adjust here accordingly.
        // Current controller shows [HttpGet] IncremnetInTasbeeh(int groupid,int tasbeehid)
        // but we extended it to include userid. We'll call the updated route:

        // /api/Group/IncrementInTasbeeh?groupid=&tasbeehid=&userid=
        let urlStr = "\(baseURL)/api/Group/IncrementInTasbeeh?groupid=\(tasbeeh.groupId)&tasbeehid=\(tasbeeh.tasbeehId)&userid=\(tasbeeh.userId)"
        guard let url = URL(string: urlStr) else { done(nil, nil); return }

        var req = URLRequest(url: url)
        req.httpMethod = "POST" // if your method is [HttpGet], change this to "GET"

        isPosting = true
        lastError = nil

        URLSession.shared.dataTask(with: req) { data, resp, err in
            DispatchQueue.main.async {
                self.isPosting = false

                if let err = err { self.lastError = err.localizedDescription; done(nil, nil); return }
                guard let http = resp as? HTTPURLResponse else { self.lastError = "No response"; done(nil, nil); return }

                guard (200...299).contains(http.statusCode), let data = data else {
                    let txt = String(data: data ?? Data(), encoding: .utf8) ?? "Server error"
                    self.lastError = "HTTP \(http.statusCode): \(txt)"
                    done(nil, nil)
                    return
                }

                // Expecting: { CurrentCount: int, TotalAchieved: int }
                if let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    let current = obj["CurrentCount"] as? Int
                    let total = obj["TotalAchieved"] as? Int
                    done(current, total)
                } else {
                    done(nil, nil)
                }
            }
        }.resume()
    }
}


// MARK: - Preview
struct TasbeehCounterView_Previews: PreviewProvider {
    static var previews: some View {
        TasbeehCounterView(tasbeeh: TasbeehCounterModel(
            title: "Tasbeeh Fatima",
            arabicText: "سُبْحَانَ ٱللَّٰهِ وَبِحَمْدِهِ",
            currentCount: 5,
            totalCount: 33,
            tasbeehId: 200,
            groupId: 1,
            userId: 101,
            adminId: 100
        ))
    }
}
