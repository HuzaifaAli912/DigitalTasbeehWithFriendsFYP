import SwiftUI

// MARK: - Group Tasbeeh Model
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

// MARK: - Combined Display Model
struct TasbeehModel: Identifiable {
    let id: Int
    let title: String
    let type: String  // "group" or "single"
}

// MARK: - Main View
struct GroupListView: View {
    let userId: Int
    @State private var tasbeehList: [TasbeehModel] = []
    @State private var navigateToCreate = false
    @State private var selectedGroupId: Int? = nil  // Track the selected group

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                Text("All Groups/Single")
                    .font(.title2)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 20)

                ScrollView {
                    VStack(spacing: 15) {
                        ForEach(tasbeehList) { item in
                            Button(action: {
                                self.selectedGroupId = item.id  // Set selected group ID
                                print("Selected Group ID: \(item.id)") // Debugging print
                            }) {
                                GroupItemView(
                                    icon: item.type == "group" ? "person.3.fill" : "person.fill",
                                    title: item.title
                                )
                            }
                        }
                    }
                    .padding(.top, 20)
                    .padding(.horizontal)
                }

                Spacer()

                HStack {
                    Spacer()
                    Button(action: {
                        self.navigateToCreate = true
                    }) {
                        Image(systemName: "plus")
                            .font(.title)
                            .foregroundColor(.white)
                            .frame(width: 55, height: 55)
                            .background(Color.blue)
                            .clipShape(Circle())
                            .shadow(radius: 5)
                            .padding()
                    }

                    NavigationLink(
                        destination: CreateGroupSingleView(userId: userId),
                        isActive: $navigateToCreate
                    ) {
                        EmptyView()
                    }
                }
            }
            .navigationBarBackButtonHidden(true)
            .onAppear {
                fetchAllTasbeehs()
            }

            // Corrected navigation link to pass groupId or singleId
            NavigationLink(
                destination: AllGroupTasbeehView(groupId: selectedGroupId ?? 0, userId: userId),
                isActive: Binding(
                    get: { selectedGroupId != nil },
                    set: { if !$0 { selectedGroupId = nil } }
                )
            ) {
                EmptyView()
            }
            .onChange(of: selectedGroupId) { newValue in
                print("Navigating with Group ID: \(newValue ?? 0)")  // Debugging print
            }
        }
    }

    // MARK: - Fetch All Tasbeehs (Groups and Singles)
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

    // MARK: - Fetch Groups
    func fetchGroups(completion: @escaping ([TasbeehModel]) -> Void) {
        guard let url = URL(string: "http://192.168.137.1/DigitalTasbeehWithFriendsApi/api/User/GroupTitles?memberId=\(userId)") else {
            print("❌ Invalid Group URL")
            completion([])
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data else {
                print("❌ No group data received")
                completion([])
                return
            }

            guard let decoded = try? JSONDecoder().decode([GroupModel].self, from: data) else {
                print("❌ Failed to decode Group")
                completion([])
                return
            }

            let mapped = decoded.map {
                TasbeehModel(id: $0.id, title: $0.title, type: "group")
            }

            // Print the fetched group data to console
            print("Fetched Groups: \(mapped)")

            completion(mapped)
        }.resume()
    }

    // MARK: - Fetch Singles
    func fetchSingles(completion: @escaping ([TasbeehModel]) -> Void) {
        guard let url = URL(string: "http://192.168.137.1/DigitalTasbeehWithFriendsApi/api/Sigle/GetAllSingletasbeehbyid?userid=\(userId)") else {
            print("❌ Invalid Single URL")
            completion([])
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data else {
                print("❌ No single data received")
                completion([])
                return
            }

            guard let decoded = try? JSONDecoder().decode([SingleTasbeehModel].self, from: data) else {
                print("❌ Failed to decode Single")
                completion([])
                return
            }

            let mapped = decoded.map {
                TasbeehModel(id: $0.id, title: $0.title, type: "single")
            }

            // Print the fetched single tasbeeh data to console
            print("Fetched Singles: \(mapped)")

            completion(mapped)
        }.resume()
    }
    //rating function
    func createTasbeeh(title: String, count: Int, type: String) {
        let url = URL(string: "http://192.168.137.1/DigitalTasbeehWithFriendsApi/api/AssignTasbeeh/Rategroupmember")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let tasbeeh = [
            "Tasbeeh_Title": title,
            "Count": count,
            "Type": type
        ] as [String : Any]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: tasbeeh)
        } catch {
            print("❌ JSON Error:", error)
            return
        }

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                print("❌ API Error:", error.localizedDescription)
            } else {
                print("✅ Tasbeeh Created")
            }
        }.resume()
    }
}

// MARK: - Reusable View for Group Item
struct GroupItemView: View {
    var icon: String
    var title: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.black)
            Text(title)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.black)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.blue.opacity(0.3))
        .cornerRadius(12)
    }
}

// MARK: - Preview
struct GroupListView_Previews: PreviewProvider {
    static var previews: some View {
        GroupListView(userId: 1)
    }
}

