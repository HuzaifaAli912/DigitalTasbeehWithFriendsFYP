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
struct TasbeehModel: Identifiable, Equatable {
    let id: Int
    let title: String
    let type: String // "group" or "single"
}

// MARK: - Main View
struct GroupListView: View {
    let userId: Int

    @State private var tasbeehList: [TasbeehModel] = []
    @State private var searchText: String = ""          // ✅ added
    @State private var navigateToCreate = false
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {

                // ✅ Back Button Row
                HStack {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.blue)
                                .font(.title2)
                            Text("Back")
                                .foregroundColor(.blue)
                                .font(.headline)
                        }
                    }
                    Spacer()
                }
                .padding(.top, 10)
                .padding(.horizontal)

                // Title
                Text("All Groups/Single")
                    .font(.title2)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 10)

                // ✅ Search Bar
                TextField("Search group or single…", text: $searchText)
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding([.horizontal, .top])

                // List
                ScrollView {
                    VStack(spacing: 15) {
                        if filteredList.isEmpty {
                            Text(searchText.isEmpty ? "No items found." : "No matches for \"\(searchText)\".")
                                .foregroundColor(.gray)
                                .padding(.top, 20)
                        } else {
                            ForEach(filteredList) { item in
                                if item.type == "group" {
                                    NavigationLink(destination: AllGroupTasbeehView(groupId: item.id, userId: userId, groupName: item.title)) {
                                        GroupItemView(
                                            icon: "person.3.fill",
                                            title: item.title
                                        )
                                    }
                                } else {
                                    GroupItemView(
                                        icon: "person.fill",
                                        title: item.title
                                    )
                                }
                            }
                        }
                    }
                    .padding(.top, 20)
                    .padding(.horizontal)
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
            .navigationBarBackButtonHidden(true)
            .onAppear { fetchAllTasbeehs() }
        }
    }

    // MARK: - Filtering
    private var filteredList: [TasbeehModel] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return tasbeehList }

        return tasbeehList.filter { item in
            // match title OR type keyword
            item.title.lowercased().contains(q)
            || item.type.lowercased().contains(q) // lets you type "group" or "single"
        }
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

