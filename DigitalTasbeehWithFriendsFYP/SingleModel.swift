struct SingleModel: Identifiable, Codable {
    let id: Int
    let title: String
    let type: String = "single"

    enum CodingKeys: String, CodingKey {
        case id = "ID"
        case title = "Group_Title"
    }
}

