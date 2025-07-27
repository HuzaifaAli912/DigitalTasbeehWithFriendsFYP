import SwiftUI

// MARK: - User Model
struct FriendModel: Identifiable, Codable {
    let id: Int
    let name: String

    enum CodingKeys: String, CodingKey {
        case id = "ID"
        case name = "name"
    }
}

// MARK: - All Friends View
struct AllFriendsView: View {
    let userId: Int
    @Environment(\.dismiss) private var dismiss

    @State private var friends: [FriendModel] = []

    var body: some View {
        VStack(alignment: .leading) {
            Text("Friends")
                .font(.title2)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 16)

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(friends) { friend in
                        HStack(spacing: 10) {
                            Image(systemName: "person.fill")
                                .foregroundColor(.white)
                                .padding()
                                .background(Circle().fill(Color.blue))
                            
                            Text(friend.name)
                                .foregroundColor(.black)
                                .fontWeight(.semibold)
                            
                            Spacer()
                        }
                        .padding()
                        .background(Color.blue.opacity(0.5))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                }
                .padding(.top, 10)
            }

            Spacer()
        }
        .navigationBarBackButtonHidden(false)
        .onAppear {
            fetchFriends()
        }
    }

    // MARK: - Fetch Friends API
    func fetchFriends() {
        guard let url = URL(string: "http://192.168.137.1/DigitalTasbeehWithFriendsApi/api/User/AllUser") else {
            print("❌ Invalid URL")
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                print("❌ Error fetching friends: \(error.localizedDescription)")
                return
            }

            if let data = data {
                do {
                    let decoded = try JSONDecoder().decode([FriendModel].self, from: data)
                    DispatchQueue.main.async {
                        self.friends = decoded.filter { $0.id != userId }
                    }
                } catch {
                    print("❌ JSON decode error: \(error.localizedDescription)")
                }
            }
        }.resume()
    }
}

// MARK: - Preview
struct AllFriendsView_Previews: PreviewProvider {
    static var previews: some View {
        AllFriendsView(userId: 1)
    }
}

