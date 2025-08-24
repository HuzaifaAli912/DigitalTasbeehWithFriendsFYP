import SwiftUI

struct AlertError: Identifiable {
    var id = UUID()
    var message: String
}

struct TasbeehItem: Identifiable, Codable, Equatable {
    let id: Int
    let title: String
    let type: String
    var isFavorite: Bool   // ✅ added
    var purpose: String?   // NEW: Add Purpose field

    enum CodingKeys: String, CodingKey {
        case id = "ID"
        case title = "Tasbeeh_Title"
        case type = "Type"
        case isFavorite = "IsFavorite"      // primary backend key
        case isFavoriteLower = "isFavorite" // decode-only fallback
        case isFavouriteUK   = "IsFavourite" // decode-only fallback
        case purpose = "purpose" // NEW: Ensure "purpose" key matches API response (lowercase)
    }

    // Robust Decodable
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id    = try c.decode(Int.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        type  = (try? c.decode(String.self, forKey: .type)) ?? ""
        purpose = try? c.decode(String.self, forKey: .purpose)  // NEW: Decode Purpose

        func decodeBool(for key: CodingKeys) -> Bool? {
            if let b = try? c.decode(Bool.self, forKey: key) { return b }
            if let i = try? c.decode(Int.self, forKey: key)   { return i != 0 }
            if let s = try? c.decode(String.self, forKey: key) {
                let v = s.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                return v == "true" || v == "1" || v == "yes"
            }
            return nil
        }
        isFavorite = decodeBool(for: .isFavorite)
                  ?? decodeBool(for: .isFavoriteLower)
                  ?? decodeBool(for: .isFavouriteUK)
                  ?? false
    }

    // Custom Encodable (so extra decode-only keys don't break Encodable)
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(title, forKey: .title)
        try c.encode(type, forKey: .type)
        try c.encode(isFavorite, forKey: .isFavorite)
        try c.encode(purpose, forKey: .purpose)  // NEW: Encode Purpose
    }

    // Keep Equatable stable by id (so selection isn't affected by isFavorite changes)
    static func == (lhs: TasbeehItem, rhs: TasbeehItem) -> Bool { lhs.id == rhs.id }
}

struct CompoundTasbeehLink: Codable {
    let Tasbeeh_id: Int
    let Existing_Tasbeehid: Int
}

struct CreateCompoundTitlePayload: Codable {
    let Tasbeeh_Title: String
    let User_id: Int
    let tasbeehType: String

    enum CodingKeys: String, CodingKey {
        case Tasbeeh_Title
        case User_id
        case tasbeehType = "Type"
    }
}

// ✅ Simple filter enum for the segmented control
enum TasbeehFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case favourite = "Favourite"
    var id: String { rawValue }
}

struct AllTasbeehView: View {
    let userId: Int

    @State private var tasbeehs: [TasbeehItem] = []
    @State private var searchText: String = ""
    @State private var isLoading = false
    @State private var alertError: AlertError?

    @State private var isCompoundMode = false
    @State private var selectedTasbeehs: [TasbeehItem] = []
    @State private var compoundTitle: String = ""

    // Favorite toggle busy flag (per id)
    @State private var favBusyId: Int? = nil

    // ✅ Current tab (All / Favourite)
    @State private var filterTab: TasbeehFilter = .all

    var body: some View {
        NavigationStack {
            VStack {
                if isCompoundMode {
                    HStack {
                        Button(action: cancelCompoundMode) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                                .font(.title2)
                        }

                        TextField("Enter compound title", text: $compoundTitle)
                            .textFieldStyle(.roundedBorder)
                            .padding(.horizontal)

                        Button(action: createCompoundTasbeeh) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.title2)
                        }
                    }
                    .padding(.horizontal)
                }

                TextField("Search Tasbeeh...", text: $searchText)
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding([.horizontal, .top])

                // Title + Segmented filter
                VStack(spacing: 8) {
                    Text("All Tasbeeh")
                        .font(.title2)
                        .fontWeight(.bold)

                    // ✅ Segmented control: All / Favourite
                    Picker("Filter", selection: $filterTab) {
                        ForEach(TasbeehFilter.allCases) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                }

                if isLoading {
                    ProgressView()
                        .padding()
                }

                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(filteredTasbeehs) { tasbeeh in
                            // Wrap the entire HStack in a NavigationLink to make it tappable
                            NavigationLink(
                                destination: TasbeehDetailsView(tasbeehId: tasbeeh.id)
                            ) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(tasbeeh.title)
                                            .font(.headline)
                                            .foregroundColor(.black)
                                        Text(tasbeeh.type)
                                            .font(.caption)
                                            .foregroundColor(.gray)

                                        // Displaying Purpose (New)
                                        if let purpose = tasbeeh.purpose, !purpose.isEmpty {
                                            Text(purpose)
                                                .font(.subheadline)
                                                .foregroundColor(.blue)
                                        } else {
                                            Text("Purpose: null")
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                        }
                                    }

                                    Spacer()

                                    // Delete (unchanged)
                                    Button(action: {
                                        deleteTasbeeh(id: tasbeeh.id)
                                    }) {
                                        Image(systemName: "trash")
                                            .foregroundColor(.red)
                                    }
                                    .buttonStyle(.plain) // ✅ ensure NavigationLink doesn't steal tap

                                    // Favorite (fixed)
                                    Button(action: {
                                        toggleFavorite(tasbeeh)   // optimistic UI inside
                                    }) {
                                        // read live state by id so it reflects immediately
                                        let isFav = tasbeehs.first(where: { $0.id == tasbeeh.id })?.isFavorite ?? false
                                        Image(systemName: isFav ? "heart.fill" : "heart")
                                            .foregroundColor(isFav ? .red : .white)
                                    }
                                    .buttonStyle(.plain)   // ✅ critical on iOS
                                    .disabled(favBusyId == tasbeeh.id)
                                }
                                .padding()
                                .background(
                                    // ⬅️ FIXED: single-expression ternary (no multi-statement closure)
                                    (selectedTasbeehs.contains(tasbeeh) && isCompoundMode)
                                    ? Color.green.opacity(0.3)
                                    : Color.blue.opacity(0.3)
                                )
                                .cornerRadius(12)
                                .contentShape(Rectangle()) // ✅ clean hit-testing; no behavior change
                                .onTapGesture {
                                    if isCompoundMode {
                                        if selectedTasbeehs.contains(tasbeeh) {
                                            selectedTasbeehs.removeAll { $0 == tasbeeh }
                                        } else {
                                            selectedTasbeehs.append(tasbeeh)
                                        }
                                    }
                                }
                                .onLongPressGesture {
                                    if !isCompoundMode {
                                        isCompoundMode = true
                                        selectedTasbeehs.append(tasbeeh)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                if isCompoundMode && !selectedTasbeehs.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Existing Tasbeeh Chain")
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(selectedTasbeehs.indices, id: \.self) { index in
                            let item = selectedTasbeehs[index]
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(item.title)
                                        .font(.subheadline)
                                    Text(item.type)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }

                                Spacer()

                                Button(action: {
                                    selectedTasbeehs.remove(at: index)
                                }) {
                                    Image(systemName: "minus.circle")
                                        .foregroundColor(.red)
                                }

                                if index > 0 {
                                    Button(action: {
                                        selectedTasbeehs.swapAt(index, index - 1)
                                    }) {
                                        Image(systemName: "arrow.up.circle")
                                            .foregroundColor(.black)
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
                }

                Spacer()

                HStack {
                    Spacer()
                    NavigationLink(destination: CreateTasbeehView(userId: userId)) {
                        Image(systemName: "plus")
                            .font(.title)
                            .foregroundColor(.white)
                            .frame(width: 55, height: 55)
                            .background(Color.blue)
                            .clipShape(Circle())
                            .shadow(radius: 5)
                            .padding()
                    }
                }
            }
            .onAppear {
                fetchTasbeehs()
            }
            .alert(item: $alertError) { error in
                Alert(title: Text("Message"), message: Text(error.message), dismissButton: .default(Text("OK")))
            }
        }
    }

    // ✅ Apply Favourite filter + search
    var filteredTasbeehs: [TasbeehItem] {
        var list = tasbeehs
        if filterTab == .favourite {
            list = list.filter { $0.isFavorite }
        }
        if !searchText.isEmpty {
            let q = searchText.lowercased()
            list = list.filter { $0.title.lowercased().contains(q) || ($0.purpose?.lowercased().contains(q) ?? false) }  // Filter by Purpose
        }
        return list
    }

    func fetchTasbeehs() {
        isLoading = true
        alertError = nil
        guard let url = URL(string: "http://192.168.137.1/DigitalTasbeehWithFriendsApi/api/CreateTasbeeh/Alltasbeeh?userid=\(userId)") else { return }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data else {
                DispatchQueue.main.async {
                    self.alertError = AlertError(message: "No data received")
                    self.isLoading = false
                }
                return
            }

            do {
                let decoded = try JSONDecoder().decode([TasbeehItem].self, from: data)
                DispatchQueue.main.async {
                    self.tasbeehs = decoded
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.alertError = AlertError(message: "Decode error: \(error)")
                    self.isLoading = false
                }
            }
        }.resume()
    }

    func deleteTasbeeh(id: Int) {
        isLoading = true
        alertError = nil
        guard let url = URL(string: "http://192.168.137.1/DigitalTasbeehWithFriendsApi/api/CreateTasbeeh/Deletetasbeeh?userid=\(userId)&tabseehid=\(id)") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        URLSession.shared.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.alertError = AlertError(message: "Delete error: \(error.localizedDescription)")
                    self.isLoading = false
                    return
                }

                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    self.tasbeehs.removeAll { $0.id == id }
                } else {
                    self.alertError = AlertError(message: "Failed to delete Tasbeeh.")
                }
                self.isLoading = false
            }
        }.resume()
    }

    func cancelCompoundMode() {
        isCompoundMode = false
        selectedTasbeehs.removeAll()
        compoundTitle = ""
    }

    // Step 1: Create the compound title
    func createCompoundTasbeeh() {
        guard !compoundTitle.isEmpty else {
            alertError = AlertError(message: "Please enter compound title.")
            return
        }

        let payload = CreateCompoundTitlePayload(Tasbeeh_Title: compoundTitle, User_id: userId, tasbeehType: "Compund")

        guard let url = URL(string: "http://192.168.137.1/DigitalTasbeehWithFriendsApi/api/CreateTasbeeh/createtasbeehtitle") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONEncoder().encode(payload)
        } catch {
            alertError = AlertError(message: "Encoding error")
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async {
                    self.alertError = AlertError(message: "Network error: \(error?.localizedDescription ?? "Unknown")")
                }
                return
            }

            do {
                if let tasbeehId = try JSONDecoder().decode(Int?.self, from: data) {
                    submitCompoundChain(tasbeehId: tasbeehId)
                } else {
                    DispatchQueue.main.async {
                        self.alertError = AlertError(message: "Failed to get Tasbeeh ID.")
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.alertError = AlertError(message: "Decoding error on title creation.")
                }
            }
        }.resume()
    }

    // Step 2: Submit the selected tasbeehs
    func submitCompoundChain(tasbeehId: Int) {
        let chainData = selectedTasbeehs.map {
            CompoundTasbeehLink(Tasbeeh_id: tasbeehId, Existing_Tasbeehid: $0.id)
        }

        guard let url = URL(string: "http://192.168.137.1/DigitalTasbeehWithFriendsApi/api/CreateTasbeeh/chaintasbeeh") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONEncoder().encode(chainData)
        } catch {
            alertError = AlertError(message: "Encoding chain error")
            return
        }

        URLSession.shared.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.alertError = AlertError(message: "Error: \(error.localizedDescription)")
                } else if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    self.alertError = AlertError(message: "Compound Tasbeeh created successfully ✅")
                    self.cancelCompoundMode()
                    self.fetchTasbeehs()
                } else {
                    self.alertError = AlertError(message: "Failed to save compound chain.")
                }
            }
        }.resume()
    }

    // Favorite toggle
    func toggleFavorite(_ tasbeeh: TasbeehItem) {
        guard let idx = tasbeehs.firstIndex(where: { $0.id == tasbeeh.id }) else { return }
        let newValue = !tasbeehs[idx].isFavorite
        let tasbeehId = tasbeeh.id   // ✅ capture only the id

        // ✅ optimistic UI — update immediately (with a tiny animation)
        withAnimation(.easeInOut(duration: 0.12)) {
            tasbeehs[idx].isFavorite = newValue
        }
        favBusyId = tasbeehId

        guard let url = URL(string:
            "http://192.168.137.1/DigitalTasbeehWithFriendsApi/api/CreateTasbeeh/SetFavorite?userid=\(userId)&tasbeehId=\(tasbeehId)&isFavorite=\(newValue)"
        ) else {
            favBusyId = nil
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        URLSession.shared.dataTask(with: request) { data, resp, err in
            DispatchQueue.main.async {
                favBusyId = nil
                if let err = err {
                    // rollback on error
                    if let i = tasbeehs.firstIndex(where: { $0.id == tasbeehId }) {
                        tasbeehs[i].isFavorite.toggle()
                    }
                    alertError = AlertError(message: "Favorite error: \(err.localizedDescription)")
                    return
                }
                guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                    if let i = tasbeehs.firstIndex(where: { $0.id == tasbeehId }) {
                        tasbeehs[i].isFavorite.toggle()
                    }
                    let code = (resp as? HTTPURLResponse)?.statusCode ?? 0
                    let body = String(data: data ?? Data(), encoding: .utf8) ?? ""
                    alertError = AlertError(message: "Favorite failed (HTTP \(code)): \(body)")
                    return
                }
            }
        }.resume()
    }
}

struct AllTasbeehView_Previews: PreviewProvider {
    static var previews: some View {
        AllTasbeehView(userId: 1)
    }
}

