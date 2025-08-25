import SwiftUI

// MARK: - Alert Model
struct AlertErrorr: Identifiable {
    var id = UUID()
    var message: String
}

// MARK: - Models
struct Surah: Identifiable, Hashable {
    var id: String
    var title: String
    var ayahs: [Int]
}

struct QuranTasbeehItem: Identifiable, Codable {
    var id: Int
    var Sura_name: String
    var Ayah_number_from: Int
    var Ayah_number_to: Int
    var Ayah_text: String

    enum CodingKeys: String, CodingKey {
        case id = "ID"                   // 👈 backend se "ID" aata hai
        case Sura_name                   // matches exact JSON
        case Ayah_number_from
        case Ayah_number_to
        case Ayah_text
    }
}


struct WazifaTextItem: Identifiable, Codable {
    var id: Int
    var text: String
}

struct CompoundQuranEntry: Codable {
    var Tasbeeh_id: Int
    var Quran_Tasbeeh_id: Int
}

struct CompoundWazifaEntry: Codable {
    var Wazifa_id: Int
    var wazifa_text_id: Int
}

// MARK: - View
struct CreateTasbeehView: View {
    let userId: Int

    @State private var tasbeehTitle: String = ""
    @State private var selectedType = "Quran"
    @State private var selectedSurah: Surah? = nil
    @State private var selectedAyahFrom = ""
    @State private var selectedAyahTo = ""
    @State private var wazifaText = ""
    @State private var purpose: String = ""
    @State private var tasbeehId: Int = 0

    @State private var quranItems: [QuranTasbeehItem] = []
    @State private var wazifaItems: [WazifaTextItem] = []
    @State private var compoundQuran: [CompoundQuranEntry] = []
    @State private var compoundWazifa: [CompoundWazifaEntry] = []

    @State private var showAlert = false
    @State private var alertMessage: String = ""

    // Navigation to "Create from Existing Tasbeehs"
    @State private var navigateToCreateFromExisting = false

    let surahData: [Surah] = [
        Surah(id: "1", title: "Al-Fatiha", ayahs: Array(1...7)),
        Surah(id: "2", title: "Al-Baqarah", ayahs: Array(1...286)),
        Surah(id: "3", title: "Al-Imran", ayahs: Array(1...200)),
        Surah(id: "4", title: "An-Nisa", ayahs: Array(1...176)),
        Surah(id: "5", title: "Al-Maidah", ayahs: Array(1...120)),
        Surah(id: "6", title: "Al-Anam", ayahs: Array(1...165)),
        Surah(id: "7", title: "Al-Araf", ayahs: Array(1...206))
    ]

    let typeOptions = ["Quran", "Wazifa"]

    var body: some View {
        NavigationStack {
            ScrollView {
                // Hidden NavigationLink for programmatic navigation
                NavigationLink(
                    destination: CreateFromExistingTasbeehView(userId: userId),
                    isActive: $navigateToCreateFromExisting
                ) { EmptyView() }
                .hidden()

                VStack(spacing: 12) {
                    TextField("Enter Tasbeeh Title", text: $tasbeehTitle)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)

                    TextField("Enter Purpose (e.g., Sadaqah Jariyah, Health, Exams)", text: $purpose)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)

                    Picker("Select Type", selection: $selectedType) {
                        ForEach(typeOptions, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())

                    if selectedType == "Quran" {
                        Picker("Select Surah", selection: $selectedSurah) {
                            ForEach(surahData) { surah in
                                Text(surah.title).tag(Optional(surah))
                            }
                        }

                        TextField("Ayah From", text: $selectedAyahFrom)
                            .keyboardType(.numberPad)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)

                        TextField("Ayah To", text: $selectedAyahTo)
                            .keyboardType(.numberPad)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                    } else {
                        TextField("Wazifa Text", text: $wazifaText)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                    }

                    Divider()

                    ForEach(selectedType == "Quran" ? quranItems.map { AnyIdentifiable($0) } : wazifaItems.map { AnyIdentifiable($0) }) { item in
                        VStack(alignment: .leading) {
                            if selectedType == "Quran", let item = item.base as? QuranTasbeehItem {
                                Text("Surah: \(item.Sura_name) [\(item.Ayah_number_from)-\(item.Ayah_number_to)]")
                                Text("Ayah: \(item.Ayah_text)").font(.caption)
                            } else if selectedType == "Wazifa", let item = item.base as? WazifaTextItem {
                                Text("Text: \(item.text)")
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.15))
                        .cornerRadius(10)
                    }

                    Button("Submit Tasbeeh") {
                        submitCompound()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("Create Tasbeeh")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            navigateToCreateFromExisting = true
                        } label: {
                            Label("Create from Existing Tasbeehs", systemImage: "square.stack.3d.down.right")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .imageScale(.large)
                            .accessibilityLabel("More options")
                    }
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Message"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }

    // MARK: - Helper (for safe query encoding)
    private func makeQuery(_ params: [String: String]) -> String {
        params.map { key, value in
            let k = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? key
            let v = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value
            return "\(k)=\(v)"
        }.joined(separator: "&")
    }

    // MARK: - API Methods
    // FIXED: addQuranItem now sends all required params and uses encoded query
    func addQuranItem(tasbeehId: Int) {
        guard let surah = selectedSurah,
              let from = Int(selectedAyahFrom),
              let to = Int(selectedAyahTo)
        else {
            alertMessage = "Please fill all Quran fields"
            showAlert = true
            return
        }

        // Backend needs: surahName, ayahNumberFrom, ayahNumberTo, count, tasbeehId
        let params: [String: String] = [
            "surahName": surah.title,
            "ayahNumberFrom": String(from),
            "ayahNumberTo": String(to),
            "count": "1",                    // REQUIRED by API
            "tasbeehId": String(tasbeehId)   // REQUIRED
        ]
        let query = makeQuery(params)

        let urlString = "http://192.168.137.1/DigitalTasbeehWithFriendsApi/api/CreateTasbeeh/addqurantasbeeh?\(query)"
        guard let url = URL(string: urlString) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        print("🔎 AddQuranTasbeeh URL => \(urlString)")

        URLSession.shared.dataTask(with: request) { data, resp, _ in
            DispatchQueue.main.async {
                guard let http = resp as? HTTPURLResponse else {
                    self.alertMessage = "No server response"
                    self.showAlert = true
                    return
                }
                guard (200...299).contains(http.statusCode), let data = data else {
                    let text = String(data: data ?? Data(), encoding: .utf8) ?? "Unknown server error"
                    self.alertMessage = "HTTP \(http.statusCode): \(text)"
                    self.showAlert = true
                    return
                }

                // Backend returns a LIST of Quran_Tasbeeh
                if let items = try? JSONDecoder().decode([QuranTasbeehItem].self, from: data) {
                    self.quranItems.append(contentsOf: items)
                    self.compoundQuran.append(contentsOf: items.map {
                        CompoundQuranEntry(Tasbeeh_id: tasbeehId, Quran_Tasbeeh_id: $0.id)
                    })
                    self.alertMessage = "✅ Quran item added & linked"
                    self.showAlert = true
                } else {
                    self.alertMessage = "Decode error (Quran response)"
                    self.showAlert = true
                }
            }
        }.resume()
    }

    func addWazifaItem(tasbeehId: Int) {
        guard !wazifaText.isEmpty else {
            alertMessage = "Please fill Wazifa text"
            showAlert = true
            return
        }

        let body: [String: Any] = [
            "text": wazifaText,
            "tasbeehId": tasbeehId
        ]

        guard let url = URL(string: "http://192.168.137.1/DigitalTasbeehWithFriendsApi/api/Wazifa/Addwazifatext"),
              let data = try? JSONSerialization.data(withJSONObject: body)
        else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = data

        URLSession.shared.dataTask(with: request) { data, resp, _ in
            DispatchQueue.main.async {
                guard let http = resp as? HTTPURLResponse else {
                    self.alertMessage = "No server response"
                    self.showAlert = true
                    return
                }
                guard (200...299).contains(http.statusCode), let data = data,
                      let item = try? JSONDecoder().decode(WazifaTextItem.self, from: data) else {
                    let text = String(data: data ?? Data(), encoding: .utf8) ?? "Unknown server error"
                    self.alertMessage = "HTTP \(http.statusCode): \(text)"
                    self.showAlert = true
                    return
                }

                self.wazifaItems.append(item)
                self.compoundWazifa.append(CompoundWazifaEntry(Wazifa_id: tasbeehId, wazifa_text_id: item.id))
                self.alertMessage = "✅ Wazifa item added & linked"
                self.showAlert = true
            }
        }.resume()
    }

    func submitCompound() {
        // Validate title first
        guard !tasbeehTitle.isEmpty else {
            alertMessage = "Please enter title before submission"
            showAlert = true
            return
        }

        // Conditional validation based on selectedType (Quran or Wazifa)
        if selectedType == "Quran" {
            guard selectedSurah != nil,
                  !selectedAyahFrom.isEmpty,
                  !selectedAyahTo.isEmpty else {
                alertMessage = "Please fill all Quran fields"
                showAlert = true
                return
            }
        } else if selectedType == "Wazifa" {
            guard !wazifaText.isEmpty else {
                alertMessage = "Please fill Wazifa text"
                showAlert = true
                return
            }
        }

        // Proceed to create the Tasbeeh
        let titleObj: [String: Any] = [
            "Tasbeeh_Title": tasbeehTitle,
            "User_id": userId,
            "Type": selectedType,
            "Purpose": purpose
        ]

        guard let titleURL = URL(string: "http://192.168.137.1/DigitalTasbeehWithFriendsApi/api/CreateTasbeeh/createtasbeehtitle"),
              let titleData = try? JSONSerialization.data(withJSONObject: titleObj)
        else { return }

        var request = URLRequest(url: titleURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = titleData

        URLSession.shared.dataTask(with: request) { data, resp, _ in
            DispatchQueue.main.async {
                guard let http = resp as? HTTPURLResponse else {
                    self.alertMessage = "No server response"
                    self.showAlert = true
                    return
                }
                guard (200...299).contains(http.statusCode), let data = data,
                      let id = try? JSONDecoder().decode(Int.self, from: data) else {
                    let text = String(data: data ?? Data(), encoding: .utf8) ?? "Unknown server error"
                    self.alertMessage = "HTTP \(http.statusCode): \(text)"
                    self.showAlert = true
                    return
                }

                self.tasbeehId = id
                if self.selectedType == "Quran" {
                    self.addQuranItem(tasbeehId: id)
                } else {
                    self.addWazifaItem(tasbeehId: id)
                }
            }
        }.resume()
    }

    func postCompoundList<T: Codable>(urlPath: String, list: [T]) {
        guard let url = URL(string: "http://192.168.137.1/DigitalTasbeehWithFriendsApi/api/Wazifa/\(urlPath)"),
              let data = try? JSONEncoder().encode(list)
        else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = data

        URLSession.shared.dataTask(with: request) { _, _, _ in
            DispatchQueue.main.async {
                alertMessage = "✅ Compound Tasbeeh Created!"
                showAlert = true
            }
        }.resume()
    }
}

// MARK: - Preview
struct CreateTasbeehView_Previews: PreviewProvider {
    static var previews: some View {
        CreateTasbeehView(userId: 1)
    }
}

// MARK: - Type Eraser
struct AnyIdentifiable: Identifiable {
    let id = UUID()
    let base: Any
    init<T: Identifiable>(_ base: T) { self.base = base }
}

