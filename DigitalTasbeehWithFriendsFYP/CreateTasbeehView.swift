import SwiftUI

// MARK: - Surah Model
struct Surah {
    let id: String
    let title: String
    let ayahs: [Int]
}

// MARK: - Create Tasbeeh View
struct CreateTasbeehView: View {
    let userId: Int

    @State private var tasbeehTitle: String = ""
    @State private var count: String = ""
    @State private var selectedSurah: String? = nil
    @State private var selectedAyahFrom: String = ""
    @State private var selectedAyahTo: String = ""
    @State private var selectedType: String = "Quran"
    @State private var wazifaText: String = ""
    @State private var combinedData: [TasbeehItem] = []
    @State private var alertMessage: AlertError?

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
            VStack {
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
                .padding()

                if selectedType == "Quran" {
                    VStack {
                        Picker("Select Surah", selection: $selectedSurah) {
                            ForEach(surahData, id: \.id) { surah in
                                Text(surah.title).tag(Optional(surah.id))
                            }
                        }
                        .padding()

                        if let selectedSurahId = selectedSurah,
                           let surah = surahData.first(where: { $0.id == selectedSurahId }) {
                            Text("Selected Surah: \(surah.title)")
                                .foregroundColor(.gray)

                            TextField("Enter Ayah From", text: $selectedAyahFrom)
                                .keyboardType(.numberPad)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(10)

                            TextField("Enter Ayah To", text: $selectedAyahTo)
                                .keyboardType(.numberPad)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(10)

                            TextField("Enter Count", text: $count)
                                .keyboardType(.numberPad)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(10)
                        }
                    }
                } else {
                    VStack {
                        TextField("Enter Wazifa Text", text: $wazifaText)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)

                        TextField("Enter Count", text: $count)
                            .keyboardType(.numberPad)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                    }
                }

                Button(action: {
                    createTasbeeh()
                }) {
                    Text("Create Tasbeeh")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(15)
                        .padding()
                }

                List(combinedData, id: \.id) { item in
                    Text("\(item.title)")
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Create Tasbeeh")
            .alert(item: $alertMessage) { error in
                Alert(title: Text("Error"), message: Text(error.message), dismissButton: .default(Text("OK")))
            }
        }
    }

    func createTasbeeh() {
        if selectedType == "Quran" {
            addQuranTasbeeh()
        } else {
            addWazifaText()
        }
    }

    func addQuranTasbeeh() {
        guard let surah = surahData.first(where: { $0.id == selectedSurah }),
              !selectedAyahFrom.isEmpty, !selectedAyahTo.isEmpty else {
            alertMessage = AlertError(message: "Please complete Quran selection")
            return
        }

        let tasbeehData: [String: Any] = [
            "surahName": surah.title,
            "ayahNumberFrom": selectedAyahFrom,
            "ayahNumberTo": selectedAyahTo,
            "count": count
        ]

        guard let url = URL(string: "http://192.168.137.1/DigitalTasbeehWithFriendsApi/api/CreateTasbeeh/Addqurantasbeeh") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: tasbeehData)
        } catch {
            alertMessage = AlertError(message: "Encoding error: \(error)")
            return
        }

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                alertMessage = AlertError(message: "Error: \(error)")
                return
            }
            if let data = data,
               let decoded = try? JSONDecoder().decode([TasbeehItem].self, from: data) {
                DispatchQueue.main.async {
                    self.combinedData.append(contentsOf: decoded)
                }
            }
        }.resume()
    }

    func addWazifaText() {
        let wazifaData: [String: Any] = [
            "text": wazifaText,
            "count": count
        ]

        guard let url = URL(string: "http://192.168.137.1/DigitalTasbeehWithFriendsApi/api/CreateTasbeeh/Addwazifa") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: wazifaData)
        } catch {
            alertMessage = AlertError(message: "Encoding error: \(error)")
            return
        }

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                alertMessage = AlertError(message: "Error: \(error)")
                return
            }
            if let data = data,
               let decoded = try? JSONDecoder().decode([TasbeehItem].self, from: data) {
                DispatchQueue.main.async {
                    self.combinedData.append(contentsOf: decoded)
                }
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

// MARK: - Error Model
struct AlertErrorr: Identifiable {
    var id = UUID()
    var message: String
}


