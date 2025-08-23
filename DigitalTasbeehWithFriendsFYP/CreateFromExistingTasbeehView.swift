import SwiftUI

private enum HeaderFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case quran = "Quran"
    case wazifa = "Wazifa"
    case compound = "Compound"   // backend may send "Compund"
    var id: String { rawValue }
}

struct CreateFromExistingTasbeehView: View {
    let userId: Int

    // Inputs
    @State private var newTitle: String = ""

    // Tabs
    @State private var headerFilter: HeaderFilter = .quran
    private let compoundLabels: Set<String> = ["compound","compund","mixed"]

    // Headers (Alltasbeeh)
    @State private var allHeaders: [TasbeehItem] = []
    @State private var isLoadingList = false
    @State private var lastError: String = ""
    @State private var lastPayloadPreview: String = ""

    // Expand / details
    @State private var expanded: Set<Int> = []
    @State private var isLoadingDetails: Set<Int> = []
    @State private var detailsCache: [Int: TasbeehDetailsDTO] = [:]   // tasbeehId -> details

    // Selections (use itemId from DTO)
    @State private var selectedQuranItemIds: Set<Int> = []
    @State private var selectedWazifaItemIds: Set<Int> = []

    // Base URL
    private let base = "http://192.168.137.1/DigitalTasbeehWithFriendsApi"

    var body: some View {
        VStack(spacing: 0) {
            headerInputsView
            Divider().padding(.vertical, 8)
            listAreaView
            bottomCreateButton
        }
        .navigationTitle("From Existing Tasbeehs")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: fetchHeaders)
    }

    // MARK: - Subviews

    private var headerInputsView: some View {
        VStack(spacing: 10) {
            TextField("Enter new Tasbeeh title", text: $newTitle)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)

            Picker("Filter", selection: $headerFilter) {
                ForEach(HeaderFilter.allCases) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: headerFilter) { _ in
                expanded.removeAll()
                // selection user-intended across tabs? Usually clear on switch:
                selectedQuranItemIds.removeAll()
                selectedWazifaItemIds.removeAll()
            }
        }
        .padding(.horizontal)
        .padding(.top, 12)
    }

    private var listAreaView: some View {
        Group {
            if isLoadingList {
                ProgressView("Loading \(headerFilter.rawValue) tasbeehs...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else if filteredHeaders.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(filteredHeaders) { head in
                            TasbeehHeaderRow(
                                title: head.title,
                                type: normalizedTypeLabel(head.type),
                                isExpanded: expanded.contains(head.id),
                                toggleExpand: { toggleHeader(head.id) },
                                isLoading: isLoadingDetails.contains(head.id),
                                content: AnyView(itemsContent(for: head.id))
                            )
                            .background(Color.gray.opacity(0.06))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }

                        if totalSelectedCount > 0 {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Selected: \(totalSelectedCount) item(s)")
                                Spacer()
                            }
                            .font(.subheadline)
                            .foregroundColor(.green)
                            .padding(.horizontal)
                            .padding(.top, 4)
                        }

                        Spacer(minLength: 80)
                    }
                    .padding(.top, 4)
                }
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 8) {
            if !lastError.isEmpty {
                Text(lastError)
                    .font(.footnote)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            } else {
                Text("No \(headerFilter.rawValue) tasbeehs found.")
                    .foregroundColor(.secondary)
            }

            if !lastPayloadPreview.isEmpty {
                Text(lastPayloadPreview)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(6)
                    .padding(.horizontal)
            }

            Button {
                fetchHeaders()
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var bottomCreateButton: some View {
        VStack {
            Button(action: createNewTasbeeh) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Create New Tasbeeh")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(canCreate ? Color.green : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(!canCreate)
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
        .background(.ultraThinMaterial)
    }

    // MARK: - Helpers

    private func normalizedTypeLabel(_ t: String) -> String {
        let low = t.lowercased()
        return compoundLabels.contains(low) ? "Compound" : (low == "quran" ? "Quran" : (low == "wazifa" ? "Wazifa" : t))
    }

    private var filteredHeaders: [TasbeehItem] {
        switch headerFilter {
        case .all:
            return allHeaders
        case .quran:
            return allHeaders.filter { $0.type.caseInsensitiveCompare("Quran") == .orderedSame }
        case .wazifa:
            return allHeaders.filter { $0.type.caseInsensitiveCompare("Wazifa") == .orderedSame }
        case .compound:
            return allHeaders.filter { compoundLabels.contains($0.type.lowercased()) }
        }
    }

    private var canCreate: Bool {
        guard !newTitle.trimmingCharacters(in: .whitespaces).isEmpty else { return false }
        return !(selectedQuranItemIds.isEmpty && selectedWazifaItemIds.isEmpty)
    }

    private var totalSelectedCount: Int {
        selectedQuranItemIds.count + selectedWazifaItemIds.count
    }

    private func itemsContent(for tasbeehId: Int) -> some View {
        Group {
            if let d = detailsCache[tasbeehId] {
                VStack(alignment: .leading, spacing: 10) {
                    if !d.quranItems.isEmpty {
                        Text("Quran Items").font(.headline)
                        VStack(spacing: 6) {
                            ForEach(d.quranItems) { it in
                                ItemRowQuranDTO(
                                    item: it,
                                    isSelected: selectedQuranItemIds.contains(it.itemId),
                                    toggle: { toggleQuranSelect(it.itemId) }
                                )
                            }
                        }
                    }
                    if !d.wazifaItems.isEmpty {
                        Text("Wazifa Items").font(.headline)
                        VStack(spacing: 6) {
                            ForEach(d.wazifaItems) { it in
                                ItemRowWazifaDTO(
                                    item: it,
                                    isSelected: selectedWazifaItemIds.contains(it.itemId),
                                    toggle: { toggleWazifaSelect(it.itemId) }
                                )
                            }
                        }
                    }
                    if d.quranItems.isEmpty && d.wazifaItems.isEmpty {
                        Text("No linked items found.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 6)
            } else {
                EmptyView()
            }
        }
    }

    // MARK: - Actions

    private func toggleHeader(_ id: Int) {
        if expanded.contains(id) {
            expanded.remove(id)
            return
        }
        expanded.insert(id)

        // Fetch details (WORKS for Quran, Wazifa, Compound)
        if detailsCache[id] == nil {
            fetchDetails(for: id)
        }
    }

    private func toggleQuranSelect(_ itemId: Int) {
        if selectedQuranItemIds.contains(itemId) { selectedQuranItemIds.remove(itemId) }
        else { selectedQuranItemIds.insert(itemId) }
    }

    private func toggleWazifaSelect(_ itemId: Int) {
        if selectedWazifaItemIds.contains(itemId) { selectedWazifaItemIds.remove(itemId) }
        else { selectedWazifaItemIds.insert(itemId) }
    }

    // MARK: - Networking (HEADERS)

    private func fetchHeaders() {
        isLoadingList = true
        lastError = ""
        lastPayloadPreview = ""
        allHeaders.removeAll()

        guard let url = URL(string: "\(base)/api/CreateTasbeeh/Alltasbeeh?userid=\(userId)") else {
            isLoadingList = false
            lastError = "Invalid URL for Alltasbeeh."
            return
        }

        URLSession.shared.dataTask(with: url) { data, resp, err in
            DispatchQueue.main.async {
                defer { isLoadingList = false }

                if let err = err { lastError = "Network error: \(err.localizedDescription)"; return }
                if let http = resp as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                    lastError = "HTTP \(http.statusCode) Alltasbeeh"
                }
                guard let data = data else { lastError = "Empty response."; return }

                lastPayloadPreview = String(data: data, encoding: .utf8)?
                    .prefix(400)
                    .description ?? "Non-UTF8 payload"

                if let list = try? JSONDecoder().decode([TasbeehItem].self, from: data) {
                    allHeaders = list
                    if filteredHeaders.isEmpty { lastError = "Decoded OK, but no \(headerFilter.rawValue) tasbeehs for this user." }
                } else {
                    lastError = "Decode failed for TasbeehItem. Check keys."
                }
            }
        }.resume()
    }

    // MARK: - Networking (DETAILS via TasbeehDetails)

    private func fetchDetails(for tasbeehId: Int) {
        isLoadingDetails.insert(tasbeehId)
        lastError = ""
        lastPayloadPreview = ""

        guard let url = URL(string: "\(base)/api/CreateTasbeeh/TasbeehDetails?tasbeehId=\(tasbeehId)") else {
            isLoadingDetails.remove(tasbeehId)
            lastError = "Bad Details URL"
            return
        }

        URLSession.shared.dataTask(with: url) { data, resp, err in
            DispatchQueue.main.async {
                self.isLoadingDetails.remove(tasbeehId)

                if let err = err { self.lastError = "Details error: \(err.localizedDescription)"; return }
                guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode), let data = data else {
                    let code = (resp as? HTTPURLResponse)?.statusCode ?? 0
                    self.lastError = "Details HTTP \(code)"
                    return
                }

                self.lastPayloadPreview = String(data: data, encoding: .utf8)?
                    .prefix(400)
                    .description ?? ""

                if let dto = try? JSONDecoder().decode(TasbeehDetailsDTO.self, from: data) {
                    self.detailsCache[tasbeehId] = dto
                } else {
                    self.lastError = "Details decode failed."
                    self.detailsCache[tasbeehId] = TasbeehDetailsDTO(
                        tasbeehId: tasbeehId, title: "", userId: userId, type: "", quranItems: [], wazifaItems: []
                    )
                }
            }
        }.resume()
    }

    // MARK: - Create new tasbeeh

    private func createNewTasbeeh() {
        let title = newTitle.trimmingCharacters(in: .whitespaces)
        guard !title.isEmpty else { lastError = "Please enter a title."; return }

        let hasQ = !selectedQuranItemIds.isEmpty
        let hasW = !selectedWazifaItemIds.isEmpty
        guard hasQ || hasW else { lastError = "Please select at least one item."; return }

        // Parent type logic (as per your app flows)
        let parentType: String = (hasQ && hasW) ? "Compund" : (hasQ ? "Quran" : "Wazifa")

        let titleObj: [String: Any] = [
            "Tasbeeh_Title": title,
            "User_id": userId,
            "Type": parentType
        ]

        guard let titleURL = URL(string: "\(base)/api/CreateTasbeeh/createtasbeehtitle"),
              let titleData = try? JSONSerialization.data(withJSONObject: titleObj) else { return }

        var titleReq = URLRequest(url: titleURL)
        titleReq.httpMethod = "POST"
        titleReq.setValue("application/json", forHTTPHeaderField: "Content-Type")
        titleReq.httpBody = titleData

        URLSession.shared.dataTask(with: titleReq) { data, _, _ in
            guard let data = data,
                  let newTasbeehId = try? JSONDecoder().decode(Int.self, from: data) else {
                DispatchQueue.main.async { self.lastError = "Failed to create parent tasbeeh." }
                return
            }

            DispatchQueue.main.async {
                // post Quran items (if any)
                if hasQ {
                    let entries = selectedQuranItemIds.map { CompoundQuranEntry(Tasbeeh_id: newTasbeehId, Quran_Tasbeeh_id: $0) }
                    postCompoundList(url: "\(base)/api/Wazifa/createcoumpoundtasbeeh", body: entries) {
                        // after post success
                    }
                }
                // post Wazifa items (if any)
                if hasW {
                    let entries = selectedWazifaItemIds.map { CompoundWazifaEntry(Wazifa_id: newTasbeehId, wazifa_text_id: $0) }
                    postCompoundList(url: "\(base)/api/Wazifa/Createcompundwazifa", body: entries) {
                        // after post success
                    }
                }

                // reset UI
                self.newTitle = ""
                self.selectedQuranItemIds.removeAll()
                self.selectedWazifaItemIds.removeAll()
                self.expanded.removeAll()
                self.lastPayloadPreview = "✅ New Tasbeeh created from selected items!"
                self.lastError = ""
            }
        }.resume()
    }

    private func postCompoundList<T: Codable>(url: String, body: [T], completion: @escaping () -> Void) {
        guard let url = URL(string: url),
              let data = try? JSONEncoder().encode(body) else { return }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = data

        URLSession.shared.dataTask(with: req) { _, _, _ in
            DispatchQueue.main.async { completion() }
        }.resume()
    }
}

// MARK: - Non-generic header row
private struct TasbeehHeaderRow: View {
    let title: String
    let type: String
    let isExpanded: Bool
    let toggleExpand: () -> Void
    let isLoading: Bool
    let content: AnyView

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: toggleExpand) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title).font(.headline)
                        Label(type, systemImage: "tag")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle")
                        .imageScale(.large)
                        .foregroundColor(.accentColor)
                }
                .padding()
            }

            if isExpanded {
                if isLoading {
                    ProgressView("Loading items...")
                        .padding(.horizontal)
                        .padding(.bottom, 10)
                } else {
                    Divider().padding(.horizontal)
                    content
                        .padding(.horizontal)
                        .padding(.bottom, 10)
                }
            }
        }
    }
}

// MARK: - Checkbox rows using DTOs
private struct ItemRowQuranDTO: View {
    let item: QuranItemDTO
    let isSelected: Bool
    let toggle: () -> Void

    var body: some View {
        Button(action: toggle) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square").imageScale(.large)
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(item.suraName) [\(item.ayahFrom)-\(item.ayahTo)]").font(.subheadline).bold()
                    Text(item.ayahText).font(.caption).foregroundColor(.secondary).lineLimit(3)
                    Text("Count: \(item.count)").font(.caption2).foregroundColor(.secondary)
                }
                Spacer(minLength: 0)
            }
            .padding(10)
            .background(Color.white.opacity(0.6))
            .cornerRadius(10)
        }
    }
}

private struct ItemRowWazifaDTO: View {
    let item: WazifaItemDTO
    let isSelected: Bool
    let toggle: () -> Void

    var body: some View {
        Button(action: toggle) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square").imageScale(.large)
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.text).font(.subheadline).bold().lineLimit(3)
                    Text("Count: \(item.count)").font(.caption2).foregroundColor(.secondary)
                }
                Spacer(minLength: 0)
            }
            .padding(10)
            .background(Color.white.opacity(0.6))
            .cornerRadius(10)
        }
    }
}

// MARK: - Preview
struct CreateFromExistingTasbeehView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            CreateFromExistingTasbeehView(userId: 1)
        }
    }
}

