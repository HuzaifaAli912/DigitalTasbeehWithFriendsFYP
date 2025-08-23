import SwiftUI

// ======================================================
// 1) NEW WRAPPER: Fetch existing members, then show your
//    AddingMemberView exactly as-is (unchanged).
// ======================================================

struct AddingMemberScreen: View {
    // Inputs same as your view
    let groupId: Int
    let userId: Int

    // --- Config ---
    private let base = "http://192.168.137.1/DigitalTasbeehWithFriendsApi"
    /// Adjust this path if needed to match your backend route.
    /// In your React code it was: config.url + "Allgroupmember?groupid=..."
    /// Here I’ve used a likely REST path under /api/Group:
    private let existingMembersPath = "/api/Group/Allgroupmember"

    @State private var existingIds: [Int] = []
    @State private var loading = true
    @State private var errorText: String?

    var body: some View {
        Group {
            if loading {
                ProgressView("Loading group members…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let err = errorText {
                VStack(spacing: 10) {
                    Text(err).foregroundStyle(.red)
                    Button("Retry") { fetchExistingMembers() }
                        .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // 👉 Your original view, unchanged, now receives existingMemberIds
                AddingMemberView(groupId: groupId, userId: userId, existingMemberIds: existingIds)
            }
        }
        .onAppear { fetchExistingMembers() }
        .navigationTitle("Add Members")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func fetchExistingMembers() {
        loading = true
        errorText = nil

        guard let url = URL(string: "\(base)\(existingMembersPath)?groupid=\(groupId)") else {
            loading = false
            errorText = "Bad Allgroupmember URL"
            return
        }

        URLSession.shared.dataTask(with: url) { data, resp, err in
            DispatchQueue.main.async {
                self.loading = false
                if let err = err {
                    self.errorText = "Network error: \(err.localizedDescription)"
                    return
                }
                guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                    let code = (resp as? HTTPURLResponse)?.statusCode ?? 0
                    self.errorText = "Failed (HTTP \(code)) to load group members."
                    return
                }
                guard let data = data else {
                    self.errorText = "No data received."
                    return
                }
                do {
                    // Expecting array of objects with Members_id (like your React)
                    struct ExistingGroupMember: Decodable { let Members_id: Int }
                    let members = try JSONDecoder().decode([ExistingGroupMember].self, from: data)
                    self.existingIds = members.map { $0.Members_id }
                } catch {
                    self.errorText = "Parse error: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
}

// Preview for wrapper (mocking just to see UI)
struct AddingMemberScreen_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            AddingMemberScreen(groupId: 12, userId: 10)
        }
    }
}


// ======================================================
// 2) YOUR ORIGINAL VIEW (UNCHANGED)
//    (Just pasted exactly as you provided)
// ======================================================

/// Add members into an existing group by picking from AllUser list.
/// Reuses your existing `FriendModel` and `AlertError`.
struct AddingMemberView: View {
    // From parent
    let groupId: Int
    let userId: Int

    /// Pass the members that are **already** in this group so they show with "Already in group".
    /// If you don't have them, pass `[]` and everyone (except current user) will be selectable.
    var existingMemberIds: [Int] = []

    // MARK: - State
    @State private var allUsers: [FriendModel] = []
    @State private var selectedIds: Set<Int> = []
    @State private var searchText: String = ""
    @State private var isLoading = false
    @State private var isSubmitting = false
    @State private var alertError: AlertError?

    // MARK: - Config
    private let base = "http://192.168.137.1/DigitalTasbeehWithFriendsApi"

    var body: some View {
        VStack(spacing: 0) {
            // Search + Select all
            VStack(spacing: 10) {
                TextField("Search users…", text: $searchText)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)

                HStack {
                    Button(action: toggleSelectAll) {
                        let selectableIDs = Set(filteredUsers.filter { !isAlreadyInGroup($0.id) }
                            .map { $0.id })
                        let allSelected = !selectableIDs.isEmpty && selectableIDs.isSubset(of: selectedIds)
                        Label(allSelected ? "Unselect All" : "Select All",
                              systemImage: allSelected ? "checkmark.square" : "square")
                    }
                    .disabled(filteredUsers.filter { !isAlreadyInGroup($0.id) }.isEmpty)

                    Spacer()
                    Text("\(selectedIds.count) selected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding([.horizontal, .top])

            Divider().padding(.bottom, 8)

            // List
            Group {
                if isLoading {
                    VStack(spacing: 8) {
                        ProgressView()
                        Text("Loading users…").foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filteredUsers.isEmpty {
                    VStack(spacing: 6) {
                        Image(systemName: "person.3")
                            .font(.system(size: 36))
                            .foregroundColor(.gray)
                        Text("No users to show.")
                            .font(.headline)
                        Text("Try a different search.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(filteredUsers) { user in
                            RowView(
                                name: user.name,
                                isAlready: isAlreadyInGroup(user.id),
                                isChecked: selectedIds.contains(user.id),
                                onToggle: { toggle(user.id) }
                            )
                        }
                    }
                    .listStyle(.insetGrouped)
                    .refreshable { fetchAllUsers() }
                }
            }

            // Bottom bar
            VStack {
                Button(action: submitAdd) {
                    HStack {
                        if isSubmitting { ProgressView().padding(.trailing, 8) }
                        Image(systemName: "person.badge.plus")
                        Text("Add").fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(canSubmit ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(!canSubmit || isSubmitting)
                .padding([.horizontal, .vertical])
            }
            .background(.ultraThinMaterial)
        }
        .navigationTitle("Add Members")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { fetchAllUsers() }
        .alert(item: $alertError) { e in
            Alert(title: Text("Message"), message: Text(e.message), dismissButton: .default(Text("OK")))
        }
    }

    // MARK: - Derived

    /// Include everyone except the current user (existing members stay visible with label)
    private var visibleUsers: [FriendModel] {
        let exclude = Set([userId])
        var seen = Set<Int>()
        return allUsers.filter { u in
            guard !exclude.contains(u.id) else { return false }
            return seen.insert(u.id).inserted
        }
    }

    private var filteredUsers: [FriendModel] {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return visibleUsers }
        let q = searchText.lowercased()
        return visibleUsers.filter { $0.name.lowercased().contains(q) }
    }

    private var canSubmit: Bool { !selectedIds.isEmpty && !isLoading }

    private func isAlreadyInGroup(_ id: Int) -> Bool {
        existingMemberIds.contains(id)
    }

    // MARK: - Actions

    private func toggle(_ id: Int) {
        // ignore taps for those already in group
        guard !isAlreadyInGroup(id) else { return }
        if selectedIds.contains(id) { selectedIds.remove(id) } else { selectedIds.insert(id) }
    }

    private func toggleSelectAll() {
        let selectable = filteredUsers.filter { !isAlreadyInGroup($0.id) }.map { $0.id }
        let set = Set(selectable)
        if set.isSubset(of: selectedIds) {
            selectedIds.subtract(set)
        } else {
            selectedIds.formUnion(set)
        }
    }

    // MARK: - Networking

    /// Fetch all users exactly like your previous screen
    private func fetchAllUsers() {
        isLoading = true
        alertError = nil

        guard let url = URL(string: "\(base)/api/User/AllUser") else {
            isLoading = false
            alertError = AlertError(message: "Bad AllUser URL")
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, err in
            DispatchQueue.main.async {
                self.isLoading = false
                if let err = err {
                    self.alertError = AlertError(message: "Network error: \(err.localizedDescription)")
                    return
                }
                guard let data = data else {
                    self.alertError = AlertError(message: "No data received.")
                    return
                }
                do {
                    let decoded = try JSONDecoder().decode([FriendModel].self, from: data)
                    self.allUsers = decoded
                } catch {
                    self.alertError = AlertError(message: "Members load failed: \(error.localizedDescription)")
                }
            }
        }.resume()
    }

    /// Submit selected IDs to backend to add them into the group.
    /// Keeps the same API format you’re already using: [Int] in the body.
    private func submitAdd() {
        guard canSubmit else { return }
        isSubmitting = true
        alertError = nil

        guard let url = URL(string: "\(base)/api/Group/GroupMembers?groupid=\(groupId)") else {
            isSubmitting = false
            alertError = AlertError(message: "Bad AddMembers URL")
            return
        }

        let ids = Array(selectedIds)
        guard let body = try? JSONEncoder().encode(ids) else {
            isSubmitting = false
            alertError = AlertError(message: "Encoding error.")
            return
        }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = body

        URLSession.shared.dataTask(with: req) { data, resp, err in
            DispatchQueue.main.async {
                self.isSubmitting = false

                if let err = err {
                    self.alertError = AlertError(message: "Add failed: \(err.localizedDescription)")
                    return
                }
                guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                    let code = (resp as? HTTPURLResponse)?.statusCode ?? 0
                    let txt = String(data: data ?? Data(), encoding: .utf8) ?? ""
                    self.alertError = AlertError(message: "Add failed (HTTP \(code)): \(txt)")
                    return
                }

                // Success — clear selection; optionally you could append them to existingMemberIds
                self.alertError = AlertError(message: "✅ Members added successfully.")
                self.selectedIds.removeAll()
            }
        }.resume()
    }
}

// MARK: - Row
private struct RowView: View {
    let name: String
    let isAlready: Bool
    let isChecked: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: { if !isAlready { onToggle() } }) {
            HStack(spacing: 12) {
                // Checkbox or lock state
                if isAlready {
                    Image(systemName: "person.fill.checkmark")
                        .foregroundColor(.green)
                        .imageScale(.large)
                } else {
                    Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                        .imageScale(.large)
                        .foregroundColor(isChecked ? .accentColor : .secondary)
                }

                Text(name).fontWeight(.semibold)
                Spacer()

                if isAlready {
                    Text("Already in group")
                        .font(.caption)
                        .italic()
                        .foregroundColor(.green)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview (mock data to verify UI quickly)
struct AddingMemberView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            AddingMemberScreen(groupId: 12, userId: 10)
        }
    }
}

