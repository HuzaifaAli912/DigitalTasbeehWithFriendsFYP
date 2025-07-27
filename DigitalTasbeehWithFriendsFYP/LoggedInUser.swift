import Foundation

struct LoggedInUser: Codable, Identifiable {
    let id: Int
    let username: String
    let email: String?

    enum CodingKeys: String, CodingKey {
        case id = "ID"
        case username = "Username"
        case email = "Email"
    }
}

