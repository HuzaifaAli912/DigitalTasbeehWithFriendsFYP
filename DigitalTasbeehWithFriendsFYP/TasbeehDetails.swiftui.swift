import SwiftUI



// MARK: - API Models (match API JSON exactly)
struct TasbeehDetailsDTO: Decodable {
    let tasbeehId: Int
    let title: String
    let userId: Int
    let type: String
    let quranItems: [QuranItemDTO]
    let wazifaItems: [WazifaItemDTO]
    
    enum CodingKeys: String, CodingKey {
        case tasbeehId = "TasbeehId"
        case title = "Title"
        case userId = "UserId"
        case type = "Type"
        case quranItems = "QuranItems"
        case wazifaItems = "WazifaItems"
    }
}

struct QuranItemDTO: Decodable, Identifiable {
    var id: String { "Q-\(itemId)" }
    let source: String        // "Quran"
    let itemId: Int
    let suraName: String
    let ayahFrom: Int
    let ayahTo: Int
    let ayahText: String
    let count: Int
    
    enum CodingKeys: String, CodingKey {
        case source = "Source"
        case itemId = "ItemId"
        case suraName = "Sura_name"
        case ayahFrom = "Ayah_number_from"
        case ayahTo = "Ayah_number_to"
        case ayahText = "Ayah_text"
        case count = "Count"
    }
}

struct WazifaItemDTO: Decodable, Identifiable {
    var id: String { "W-\(itemId)" }
    let source: String        // "Wazifa"
    let itemId: Int
    let text: String
    let count: Int
    
    enum CodingKeys: String, CodingKey {
        case source = "Source"
        case itemId = "ItemId"
        case text = "Text"
        case count = "Count"
    }
}

// MARK: - ViewModel
final class TasbeehDetailsVM: ObservableObject {
    @Published var details: TasbeehDetailsDTO?
    @Published var isLoading = false
    @Published var alert: AlertError?
    
    // Change to your server/IP if needed
    private let baseURL = "http://192.168.137.1/DigitalTasbeehWithFriendsApi"
    
    func load(tasbeehId: Int) {
        guard let url = URL(string: "\(baseURL)/api/CreateTasbeeh/TasbeehDetails?tasbeehId=\(tasbeehId)") else {
            alert = AlertError(message: "Bad URL")
            return
        }
        isLoading = true
        alert = nil
        
        URLSession.shared.dataTask(with: url) { data, resp, err in
            DispatchQueue.main.async {
                self.isLoading = false
                if let err = err {
                    self.alert = AlertError(message: err.localizedDescription)
                    return
                }
                guard let http = resp as? HTTPURLResponse else {
                    self.alert = AlertError(message: "No response from server")
                    return
                }
                guard (200...299).contains(http.statusCode), let data = data else {
                    let text = String(data: data ?? Data(), encoding: .utf8) ?? "Unknown server error"
                    self.alert = AlertError(message: "HTTP \(http.statusCode): \(text)")
                    return
                }
                do {
                    let dto = try JSONDecoder().decode(TasbeehDetailsDTO.self, from: data)
                    self.details = dto
                } catch {
                    self.alert = AlertError(message: "Decode error: \(error.localizedDescription)")
                }
            }
        }.resume()
    }
}

// MARK: - View
struct TasbeehDetailsView: View {
    let tasbeehId: Int
    @StateObject private var vm = TasbeehDetailsVM()
    
    var body: some View {
        NavigationStack {
            Group {
                if vm.isLoading {
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("Loading tasbeeh details…")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let d = vm.details {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            header(d)
                            
                            if !d.quranItems.isEmpty {
                                SectionHeader(title: "Quran Items")
                                VStack(spacing: 10) {
                                    ForEach(d.quranItems) { item in
                                        QuranItemCard(item: item)
                                    }
                                }
                            }
                            
                            if !d.wazifaItems.isEmpty {
                                SectionHeader(title: "Wazifa Items")
                                VStack(spacing: 10) {
                                    ForEach(d.wazifaItems) { item in
                                        WazifaItemCard(item: item)
                                    }
                                }
                            }
                            
                            if d.quranItems.isEmpty && d.wazifaItems.isEmpty {
                                Text("No linked items found for this tasbeeh.")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding()
                    }
                } else {
                    VStack(spacing: 10) {
                        Text("No data found")
                        Button("Retry") { vm.load(tasbeehId: tasbeehId) }
                            .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("Tasbeeh Details")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { if vm.details == nil { vm.load(tasbeehId: tasbeehId) } }
            .alert(item: $vm.alert) { a in
                Alert(title: Text("Message"), message: Text(a.message), dismissButton: .default(Text("OK")))
            }
        }
    }
    
    // Header
    @ViewBuilder
    private func header(_ d: TasbeehDetailsDTO) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(d.title)
                .font(.title2).bold()
            HStack(spacing: 8) {
                TypeBadge(type: d.type)
                Text("ID: \(d.tasbeehId)")
                    .font(.caption).foregroundStyle(.secondary)
                Text("User: \(d.userId)")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - UI Pieces
struct SectionHeader: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.headline)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct TypeBadge: View {
    let type: String
    var body: some View {
        Text(type.uppercased())
            .font(.caption2).bold()
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(Capsule().fill(color(for: type).opacity(0.15)))
            .foregroundColor(color(for: type))
    }
    private func color(for type: String) -> Color {
        switch type.lowercased() {
        case "quran": return .green
        case "wazifa": return .blue
        case "mixed": return .orange
        default: return .gray
        }
    }
}

struct QuranItemCard: View {
    let item: QuranItemDTO
    @State private var expand = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(item.suraName).font(.subheadline).bold()
                Spacer()
                Text("x\(item.count)").font(.caption).foregroundStyle(.secondary)
            }
            Text("Ayahs: \(item.ayahFrom)–\(item.ayahTo)")
                .font(.caption).foregroundStyle(.secondary)
            if expand {
                Text(item.ayahText)
                    .font(.footnote)
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.opacity)
            }
            Button(expand ? "Hide ayah text" : "Show ayah text") {
                withAnimation { expand.toggle() }
            }
            .font(.caption)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.1)))
    }
}

struct WazifaItemCard: View {
    let item: WazifaItemDTO
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Wazifa").font(.subheadline).bold()
                Spacer()
                Text("x\(item.count)").font(.caption).foregroundStyle(.secondary)
            }
            Text(item.text)
                .font(.footnote)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.1)))
    }
}

// MARK: - Preview
struct TasbeehDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            TasbeehDetailsView(tasbeehId: 1)
        }
    }
}

