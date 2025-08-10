import SwiftUI

struct AlertError: Identifiable {
    var id = UUID()
    var message: String
}

struct TasbeehItem: Identifiable, Codable, Equatable {
    let id: Int
    let title: String
    let type: String

    enum CodingKeys: String, CodingKey {
        case id = "ID"
        case title = "Tasbeeh_Title"
        case type = "Type"
    }
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

struct AllTasbeehView: View {
    let userId: Int

    @State private var tasbeehs: [TasbeehItem] = []
    @State private var searchText: String = ""
    @State private var isLoading = false
    @State private var alertError: AlertError?

    @State private var isCompoundMode = false
    @State private var selectedTasbeehs: [TasbeehItem] = []
    @State private var compoundTitle: String = ""

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

                Text("All Tasbeeh")
                    .font(.title2)
                    .fontWeight(.bold)

                if isLoading {
                    ProgressView()
                        .padding()
                }

                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(filteredTasbeehs) { tasbeeh in
                            // Wrap the entire HStack in a NavigationLink to make it tappable
                            NavigationLink(
                                destination: TasbeehDetails(tasbeehId: tasbeeh.id) // Navigate to TasbeehDetails
                            ) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(tasbeeh.title)
                                            .font(.headline)
                                            .foregroundColor(.black)
                                        Text(tasbeeh.type)
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }

                                    Spacer()

                                    Button(action: {
                                        deleteTasbeeh(id: tasbeeh.id)
                                    }) {
                                        Image(systemName: "trash")
                                            .foregroundColor(.red)
                                    }
                                }
                                .padding()
                                .background(
                                    selectedTasbeehs.contains(tasbeeh) && isCompoundMode
                                    ? Color.green.opacity(0.3)
                                    : Color.blue.opacity(0.3)
                                )
                                .cornerRadius(12)
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

    var filteredTasbeehs: [TasbeehItem] {
        if searchText.isEmpty {
            return tasbeehs
        } else {
            return tasbeehs.filter { $0.title.lowercased().contains(searchText.lowercased()) }
        }
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
}

struct AllTasbeehView_Previews: PreviewProvider {
    static var previews: some View {
        AllTasbeehView(userId: 1)
    }
}

