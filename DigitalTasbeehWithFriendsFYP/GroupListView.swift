import SwiftUI

// MARK: - Group Model
struct GroupModel: Codable, Identifiable {
    let id: Int
    let title: String
    enum CodingKeys: String, CodingKey {
        case id = "Groupid"
        case title = "Grouptitle"
    }
}

// MARK: - Single Tasbeeh Model
struct SingleTasbeehModel: Identifiable, Codable {
    let id: Int
    let title: String
    enum CodingKeys: String, CodingKey {
        case id = "ID"
        case title = "Title"
    }
}

// MARK: - Unified Display Model
struct TasbeehModel: Identifiable, Equatable, Hashable {
    let id: Int
    let title: String
    let type: String // "group" or "single"
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

// MARK: - Compound payloads
struct CreateCompoundGroupTitlePayload: Codable {
    let Group_Title: String
    let Admin_id: Int
}
struct ChainGroupLink: Codable {
    let Group_id: Int
    let Existing_Groupid: Int
}

// ✅ NEW: Group member add payload (backend AddRange expects array of these)
struct GroupMemberPayload: Codable {
    let Group_id: Int
    let Members_id: Int
}

// Robust ID decode (backend might return Int OR an object)
private struct IdResponse: Decodable {
    let id: Int?
    let ID: Int?
    let Group_id: Int?
    let GroupId: Int?
    var resolved: Int? { id ?? ID ?? Group_id ?? GroupId }
}

// Tiny alert wrapper
struct SimpleAlert: Identifiable { let id = UUID(); let message: String }

struct GroupListView: View {
    let userId: Int

    @State private var tasbeehList: [TasbeehModel] = []
    @State private var searchText: String = ""
    @State private var navigateToCreate = false

    // Programmatic nav (tag/selection)
    @State private var navigateToGroupId: Int? = nil
    // Tap suppression after long press (to avoid accidental nav)
    @State private var lastLongPressRowId: Int? = nil

    // Compound mode
    @State private var isCompoundMode = false
    @State private var selectedGroups: [TasbeehModel] = []
    @State private var compoundGroupTitle: String = ""
    @State private var isSavingCompound = false
    @State private var alert: SimpleAlert?

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {

                // Title
                Text("All Groups/Single")
                    .font(.title2).bold()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 10)

                // Search Bar
                TextField("Search group or single…", text: $searchText)
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding([.horizontal, .top])

                // Compound composer bar
                if isCompoundMode {
                    HStack(spacing: 8) {
                        Button {
                            cancelCompoundMode()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.red)
                        }

                        TextField("Enter compound group title", text: $compoundGroupTitle)
                            .textFieldStyle(.roundedBorder)

                        Button {
                            createCompoundGroup()
                        } label: {
                            if isSavingCompound {
                                ProgressView()
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                            }
                        }
                        .font(.title2)
                        .foregroundColor(.green)
                        .disabled(isSavingCompound || selectedGroups.isEmpty || compoundGroupTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    .padding(.horizontal)
                    .padding(.top, 6)
                }

                // LIST (virtualized for smooth scrolling)
                ScrollView {
                    LazyVStack(spacing: 15) {
                        if filteredList.isEmpty {
                            Text(searchText.isEmpty ? "No items found." : "No matches for \"\(searchText)\".")
                                .foregroundColor(.gray)
                                .padding(.top, 20)
                        } else {
                            ForEach(filteredList, id: \.self) { item in
                                if item.type == "group" {
                                    ZStack {
                                        // Visible row
                                        GroupItemView(icon: "person.3.fill", title: item.title)
                                            .background(
                                                (isCompoundMode && selectedGroups.contains(where: { $0.id == item.id }))
                                                ? Color.green.opacity(0.25)
                                                : Color.blue.opacity(0.3)
                                            )
                                            .cornerRadius(12)
                                            .contentShape(Rectangle())
                                            .onTapGesture {
                                                // If just long-pressed this row, suppress the immediate tap
                                                if lastLongPressRowId == item.id {
                                                    lastLongPressRowId = nil
                                                    return
                                                }
                                                if isCompoundMode {
                                                    toggleSelect(item)
                                                } else {
                                                    navigateToGroupId = item.id
                                                }
                                            }
                                            .onLongPressGesture(minimumDuration: 0.5, maximumDistance: 18) {
                                                lastLongPressRowId = item.id
                                                if !isCompoundMode { isCompoundMode = true }
                                                if !selectedGroups.contains(where: { $0.id == item.id }) {
                                                    selectedGroups.append(item)
                                                }
                                            }

                                        // Hidden NavigationLink (fires when selection == tag)
                                        NavigationLink(
                                            destination: AllGroupTasbeehView(
                                                groupId: item.id,
                                                userId: userId,
                                                groupName: item.title
                                            ),
                                            tag: item.id,
                                            selection: $navigateToGroupId
                                        ) { EmptyView() }
                                        .frame(width: 0, height: 0)
                                        .hidden()
                                    }
                                } else {
                                    // Singles (no navigation / no compound)
                                    GroupItemView(icon: "person.fill", title: item.title)
                                        .background(Color.blue.opacity(0.3))
                                        .cornerRadius(12)
                                        .contentShape(Rectangle())
                                }
                            }
                        }
                    }
                    .padding(.top, 20)
                    .padding(.horizontal)
                } // ScrollView

                // Selected chain preview
                if isCompoundMode && !selectedGroups.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Selected Groups Chain")
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(selectedGroups.indices, id: \.self) { idx in
                            let g = selectedGroups[idx]
                            HStack {
                                Text(g.title).font(.subheadline)
                                Spacer()
                                Button {
                                    selectedGroups.remove(at: idx)
                                    if selectedGroups.isEmpty { cancelCompoundMode() }
                                } label: {
                                    Image(systemName: "minus.circle").foregroundColor(.red)
                                }
                                if idx > 0 {
                                    Button {
                                        selectedGroups.swapAt(idx, idx - 1)
                                    } label: {
                                        Image(systemName: "arrow.up.circle").foregroundColor(.black)
                                    }
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                            .shadow(radius: 1)
                            .padding(.horizontal)
                        }
                    }
                    .padding(.bottom, 6)
                }

                Spacer()

                // FAB
                HStack {
                    Spacer()
                    Button(action: { self.navigateToCreate = true }) {
                        Image(systemName: "plus")
                            .font(.title)
                            .foregroundColor(.white)
                            .frame(width: 55, height: 55)
                            .background(Color.blue)
                            .clipShape(Circle())
                            .shadow(radius: 5)
                            .padding()
                    }

                    NavigationLink(destination: CreateGroupSingleView(userId: userId), isActive: $navigateToCreate) {
                        EmptyView()
                    }
                }
            }
            .navigationBarBackButtonHidden(false)
            .onAppear { fetchAllTasbeehs() }
            .alert(item: $alert) { a in
                Alert(title: Text("Message"), message: Text(a.message), dismissButton: .default(Text("OK")))
            }
        }
    }

    // MARK: - Filtering
    private var filteredList: [TasbeehModel] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return tasbeehList }
        return tasbeehList.filter { $0.title.lowercased().contains(q) || $0.type.lowercased().contains(q) }
    }

    // MARK: - Selection helpers
    private func toggleSelect(_ item: TasbeehModel) {
        guard item.type == "group" else { return }
        if let idx = selectedGroups.firstIndex(where: { $0.id == item.id }) {
            selectedGroups.remove(at: idx)
            if selectedGroups.isEmpty { cancelCompoundMode() }
        } else {
            selectedGroups.append(item)
        }
    }

    private func cancelCompoundMode() {
        isCompoundMode = false
        selectedGroups.removeAll()
        compoundGroupTitle = ""
        isSavingCompound = false
    }

    // MARK: - Fetch Both Types
    func fetchAllTasbeehs() {
        tasbeehList = []
        let dispatchGroup = DispatchGroup()
        var groupResults: [TasbeehModel] = []
        var singleResults: [TasbeehModel] = []

        dispatchGroup.enter()
        fetchGroups { result in
            groupResults = result
            dispatchGroup.leave()
        }

        dispatchGroup.enter()
        fetchSingles { result in
            singleResults = result
            dispatchGroup.leave()
        }

        dispatchGroup.notify(queue: .main) {
            self.tasbeehList = groupResults + singleResults
        }
    }

    func fetchGroups(completion: @escaping ([TasbeehModel]) -> Void) {
        guard let url = URL(string: "http://192.168.137.1/DigitalTasbeehWithFriendsApi/api/User/GroupTitles?memberId=\(userId)") else {
            completion([])
            return
        }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data,
                  let decoded = try? JSONDecoder().decode([GroupModel].self, from: data) else {
                completion([])
                return
            }
            completion(decoded.map { TasbeehModel(id: $0.id, title: $0.title, type: "group") })
        }.resume()
    }

    func fetchSingles(completion: @escaping ([TasbeehModel]) -> Void) {
        guard let url = URL(string: "http://192.168.137.1/DigitalTasbeehWithFriendsApi/api/Sigle/GetAllSingletasbeehbyid?userid=\(userId)") else {
            completion([])
            return
        }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data,
                  let decoded = try? JSONDecoder().decode([SingleTasbeehModel].self, from: data) else {
                completion([])
                return
            }
            completion(decoded.map { TasbeehModel(id: $0.id, title: $0.title, type: "single") })
        }.resume()
    }

    // ✅ NEW: Add current user as a member of the newly created compound group
    private func addAdminSelfToGroup(groupId: Int, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "http://192.168.137.1/DigitalTasbeehWithFriendsApi/api/Group/GroupMembers") else {
            completion(false)
            return
        }
        // Backend AddRange expects an array
        let body = [GroupMemberPayload(Group_id: groupId, Members_id: userId)]

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            req.httpBody = try JSONEncoder().encode(body)
        } catch {
            completion(false)
            return
        }

        URLSession.shared.dataTask(with: req) { _, resp, err in
            guard err == nil, let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                completion(false)
                return
            }
            completion(true)
        }.resume()
    }

    // MARK: - Compound group creation
    private func createCompoundGroup() {
        let title = compoundGroupTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else {
            alert = SimpleAlert(message: "Please enter compound group title.")
            return
        }
        guard !selectedGroups.isEmpty else {
            alert = SimpleAlert(message: "Select at least one group.")
            return
        }
        isSavingCompound = true

        // Step 1: create new compound group title
        let payload = CreateCompoundGroupTitlePayload(Group_Title: title, Admin_id: userId)
        guard let url = URL(string: "http://192.168.137.1/DigitalTasbeehWithFriendsApi/api/Group/creategrouptitle") else {
            isSavingCompound = false
            alert = SimpleAlert(message: "Invalid URL for title creation.")
            return
        }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            req.httpBody = try JSONEncoder().encode(payload)
        } catch {
            isSavingCompound = false
            alert = SimpleAlert(message: "Encoding error for title.")
            return
        }

        URLSession.shared.dataTask(with: req) { data, resp, err in
            guard err == nil, let data = data else {
                DispatchQueue.main.async {
                    isSavingCompound = false
                    alert = SimpleAlert(message: "Failed to create compound group title.")
                }
                return
            }

            let gid: Int? =
                (try? JSONDecoder().decode(Int.self, from: data)) ??
                (try? JSONDecoder().decode(IdResponse.self, from: data))?.resolved

            guard let newGroupId = gid else {
                DispatchQueue.main.async {
                    isSavingCompound = false
                    let body = String(data: data, encoding: .utf8) ?? ""
                    alert = SimpleAlert(message: "Invalid ID response from server.\n\(body)")
                }
                return
            }

            // Step 2: submit chain links
            submitCompoundGroupChain(newGroupId: newGroupId)
        }.resume()
    }

    private func submitCompoundGroupChain(newGroupId: Int) {
        let links = selectedGroups.map { ChainGroupLink(Group_id: newGroupId, Existing_Groupid: $0.id) }

        guard let url = URL(string: "http://192.168.137.1/DigitalTasbeehWithFriendsApi/api/Group/chaingroup") else {
            DispatchQueue.main.async {
                isSavingCompound = false
                alert = SimpleAlert(message: "Invalid URL for chain submission.")
            }
            return
        }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            req.httpBody = try JSONEncoder().encode(links)
        } catch {
            DispatchQueue.main.async {
                isSavingCompound = false
                alert = SimpleAlert(message: "Encoding error for chain.")
            }
            return
        }

        URLSession.shared.dataTask(with: req) { data, resp, err in
            DispatchQueue.main.async {
                isSavingCompound = false
                if let err = err {
                    alert = SimpleAlert(message: "Chain error: \(err.localizedDescription)")
                    return
                }
                guard let http = resp as? HTTPURLResponse else {
                    alert = SimpleAlert(message: "No HTTP response from server.")
                    return
                }
                if !(200...299).contains(http.statusCode) {
                    let body = String(data: data ?? Data(), encoding: .utf8) ?? ""
                    alert = SimpleAlert(message: "Chain failed (HTTP \(http.statusCode)): \(body)")
                    return
                }

                // ✅ NEW: ensure current user becomes a member so it appears in GroupTitles
                addAdminSelfToGroup(groupId: newGroupId) { _ in
                    DispatchQueue.main.async {
                        alert = SimpleAlert(message: "Compound group created successfully ✅")
                        cancelCompoundMode()
                        fetchAllTasbeehs()
                    }
                }
            }
        }.resume()
    }
}

// MARK: - Reusable Item View
struct GroupItemView: View {
    var icon: String
    var title: String

    var body: some View {
        HStack {
            Image(systemName: icon).foregroundColor(.black)
            Text(title).foregroundColor(.black)
            Spacer()
            Image(systemName: "chevron.right").foregroundColor(.gray)
        }
        .padding()
        .background(Color.blue.opacity(0.3))
        .cornerRadius(12)
        .contentShape(Rectangle())
    }
}

// MARK: - Preview
struct GroupListView_Previews: PreviewProvider {
    static var previews: some View {
        GroupListView(userId: 1)
    }
}

