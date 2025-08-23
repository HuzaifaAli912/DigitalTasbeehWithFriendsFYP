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
    var Count: Int
}

struct WazifaTextItem: Identifiable, Codable {
    var id: Int
    var text: String
    var count: Int
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
    @State private var count: String = ""
    @State private var selectedSurah: Surah? = nil
    @State private var selectedAyahFrom = ""
    @State private var selectedAyahTo = ""
    @State private var wazifaText = ""

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

                        TextField("Count", text: $count)
                            .keyboardType(.numberPad)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)

                        // Buttons commented out as in your original code
                        // Button("Add Quran Tasbeeh") { addQuranItem() }
                        // .buttonStyle(.borderedProminent)

                    } else {
                        TextField("Wazifa Text", text: $wazifaText)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)

                        TextField("Count", text: $count)
                            .keyboardType(.numberPad)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)

                        // Button("Add Wazifa Tasbeeh") { addWazifaItem() }
                        // .buttonStyle(.borderedProminent)
                    }

                    Divider()

                    ForEach(selectedType == "Quran" ? quranItems.map { AnyIdentifiable($0) } : wazifaItems.map { AnyIdentifiable($0) }) { item in
                        VStack(alignment: .leading) {
                            if selectedType == "Quran", let item = item.base as? QuranTasbeehItem {
                                Text("Surah: \(item.Sura_name) [\(item.Ayah_number_from)-\(item.Ayah_number_to)]")
                                Text("Count: \(item.Count)").font(.subheadline)
                                Text("Ayah: \(item.Ayah_text)").font(.caption)
                            } else if selectedType == "Wazifa", let item = item.base as? WazifaTextItem {
                                Text("Text: \(item.text)")
                                Text("Count: \(item.count)").font(.subheadline)
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
                ToolbarItem(placement: .navigationBarTrailing) {   // ✅ FIXED: was .topBarTrailing
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

    // MARK: - API Methods
    func addQuranItem() {
        guard let surah = selectedSurah,
              let from = Int(selectedAyahFrom),
              let to = Int(selectedAyahTo),
              let cnt = Int(count)
        else {
            alertMessage = "Please fill all Quran fields"
            showAlert = true
            return
        }

        let params = [
            "surahName": surah.title,
            "ayahNumberFrom": "\(from)",
            "ayahNumberTo": "\(to)",
            "count": "\(cnt)"
        ]
        let query = params.map { "\($0.key)=\($0.value)" }.joined(separator: "&")

        guard let url = URL(string: "http://192.168.137.1/DigitalTasbeehWithFriendsApi/api/CreateTasbeeh/addqurantasbeeh?\(query)") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        URLSession.shared.dataTask(with: request) { data, _, _ in
            if let data = data,
               let items = try? JSONDecoder().decode([QuranTasbeehItem].self, from: data) {
                DispatchQueue.main.async {
                    self.quranItems.append(contentsOf: items)
                    self.compoundQuran.append(contentsOf: items.map { CompoundQuranEntry(Tasbeeh_id: 0, Quran_Tasbeeh_id: $0.id) })
                }
            }
        }.resume()
    }

    func addWazifaItem() {
        guard !wazifaText.isEmpty, let cnt = Int(count) else {
            alertMessage = "Please fill Wazifa text and count"
            showAlert = true
            return
        }

        let body = ["text": wazifaText, "count": cnt] as [String : Any]
        guard let url = URL(string: "http://192.168.137.1/DigitalTasbeehWithFriendsApi/api/Wazifa/Addwazifatext"),
              let data = try? JSONSerialization.data(withJSONObject: body)
        else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = data

        URLSession.shared.dataTask(with: request) { data, _, _ in
            if let data = data,
               let item = try? JSONDecoder().decode(WazifaTextItem.self, from: data) {
                DispatchQueue.main.async {
                    self.wazifaItems.append(item)
                    self.compoundWazifa.append(CompoundWazifaEntry(Wazifa_id: 0, wazifa_text_id: item.id))
                }
            }
        }.resume()
    }

    func submitCompound() {
        guard !tasbeehTitle.isEmpty else {
            alertMessage = "Please enter title before submission"
            showAlert = true
            return
        }

        let titleObj = [
            "Tasbeeh_Title": tasbeehTitle,
            "User_id": userId,
            "Type": selectedType
        ] as [String : Any]

        guard let titleURL = URL(string: "http://192.168.137.1/DigitalTasbeehWithFriendsApi/api/CreateTasbeeh/createtasbeehtitle"),
              let titleData = try? JSONSerialization.data(withJSONObject: titleObj)
        else { return }

        var request = URLRequest(url: titleURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = titleData

        URLSession.shared.dataTask(with: request) { data, _, _ in
            if let data = data, let id = try? JSONDecoder().decode(Int.self, from: data) {
                DispatchQueue.main.async {
                    if selectedType == "Quran" {
                        let list = compoundQuran.map { CompoundQuranEntry(Tasbeeh_id: id, Quran_Tasbeeh_id: $0.Quran_Tasbeeh_id) }
                        postCompoundList(urlPath: "createcoumpoundtasbeeh", list: list)
                    } else {
                        let list = compoundWazifa.map { CompoundWazifaEntry(Wazifa_id: id, wazifa_text_id: $0.wazifa_text_id) }
                        postCompoundList(urlPath: "Createcompundwazifa", list: list)
                    }
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

