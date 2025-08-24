import SwiftUI

// MARK: - Dropdown Tasbeeh Struct (No Conflict)
struct DropdownTasbeehItem: Identifiable {
    let id: String
    let title: String
}

struct GroupOrSingle: Identifiable {
    let id: String
    let title: String
    let type: String
}

struct AssignTasbeehView: View {
    let userId: Int

    @State private var tasbeehList: [DropdownTasbeehItem] = []
    @State private var groupOrSingleList: [GroupOrSingle] = []
    @State private var selectedTasbeeh: String = ""
    @State private var selectedGroupOrSingle: String = ""
    @State private var selectedDay: String = ""
    
    @State private var deadline: Date = Date()
    @State private var count: String = ""
    @State private var distributionType: String = ""
    @State private var selectedType: String = ""

    let dayOptions = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    let distributionOptions = ["Equally", "Mannully"]

    // MARK: - Navigation Data
    @State private var navigateToManually = false

    var body: some View {
        NavigationStack {
            Form {
                Picker("Select Tasbeeh", selection: $selectedTasbeeh) {
                    ForEach(tasbeehList) { item in
                        Text(item.title).tag(item.id)
                    }
                }

                Picker("Select Group/Single", selection: $selectedGroupOrSingle) {
                    ForEach(groupOrSingleList) { item in
                        Text(item.title).tag(item.id)
                    }
                }
                .onChange(of: selectedGroupOrSingle) { value in
                    if let selected = groupOrSingleList.first(where: { $0.id == value }) {
                        selectedType = selected.type
                    }
                }

                Picker("Select Day", selection: $selectedDay) {
                    ForEach(dayOptions, id: \.self) { day in
                        Text(day)
                    }
                }

                

                Section(header: Text("Deadline")) {
                    DatePicker("Select date", selection: $deadline, displayedComponents: .date)
                }

                Section(header: Text("Tasbeeh Count")) {
                    TextField("Enter count", text: $count)
                        .keyboardType(.numberPad)
                }

                if selectedType == "group" {
                    Picker("Distribution Type", selection: $distributionType) {
                        ForEach(distributionOptions, id: \.self) { type in
                            Text(type)
                        }
                    }
                }

                // Navigation to Manually Contribution Screen on "Mannully" selection
                if distributionType == "Mannully" {
                    NavigationLink(
                        destination: ManuallyContributionView(
                            userId: userId,
                            groupId: Int(selectedGroupOrSingle) ?? 0,
                            tasbeehId: Int(selectedTasbeeh.dropFirst(2)) ?? 0,
                            goal: Int(count) ?? 0,
                            endDate: formattedDate(deadline),
                            schedule: selectedDay,
                            leaverId: nil
                        ),
                        isActive: $navigateToManually
                    ) {
                        EmptyView()
                    }
                } else if (selectedType == "group" && distributionType == "Equally") || selectedType == "Single" {
                    Button("Assign Tasbeeh") {
                        assignTasbeeh()
                    }
                }
            }
            .navigationTitle("Assign Tasbeeh")
            .onAppear {
                fetchTasbeehList()
                fetchGroupAndSingleList()
            }
        }
    }

    // MARK: - API Calls

    func fetchTasbeehList() {
        guard let url = URL(string: "http://192.168.137.1/DigitalTasbeehWithFriendsApi/api/CreateTasbeeh/Alltasbeeh?userid=\(userId)") else { return }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data {
                if let decoded = try? JSONDecoder().decode([[String: AnyCodable]].self, from: data) {
                    let list = decoded.compactMap { dict -> DropdownTasbeehItem? in
                        if let id = dict["ID"]?.value as? Int,
                           let title = dict["Tasbeeh_Title"]?.value as? String {
                            return DropdownTasbeehItem(id: "t-\(id)", title: title)
                        }
                        return nil
                    }
                    DispatchQueue.main.async {
                        self.tasbeehList = list
                    }
                }
            }
        }.resume()
    }

    func fetchGroupAndSingleList() {
        let groupURL = "http://192.168.137.1/DigitalTasbeehWithFriendsApi/api/user/GroupTitles?memberId=\(userId)"
        URLSession.shared.dataTask(with: URL(string: groupURL)!) { data, _, _ in
            if let data = data,
               let decoded = try? JSONDecoder().decode([[String: AnyCodable]].self, from: data) {
                let groups = decoded.compactMap { dict -> GroupOrSingle? in
                    if let groupid = dict["Groupid"]?.value as? Int,
                       let title = dict["Grouptitle"]?.value as? String,
                       let adminId = dict["Adminid"]?.value as? Int,
                       adminId == userId {
                        return GroupOrSingle(id: "\(groupid)", title: title, type: "group")
                    }
                    return nil
                }

                let singleURL = "http://192.168.137.1/DigitalTasbeehWithFriendsApi/api/Sigle/GetAllSingletasbeehbyid?userid=\(userId)"
                URLSession.shared.dataTask(with: URL(string: singleURL)!) { sdata, _, _ in
                    if let sdata = sdata,
                       let sdecoded = try? JSONDecoder().decode([[String: AnyCodable]].self, from: sdata) {
                        let singles = sdecoded.compactMap { dict -> GroupOrSingle? in
                            if let id = dict["ID"]?.value as? Int,
                               let title = dict["Title"]?.value as? String {
                                return GroupOrSingle(id: "\(id)", title: title, type: "Single")
                            }
                            return nil
                        }

                        DispatchQueue.main.async {
                            self.groupOrSingleList = groups + singles
                        }
                    }
                }.resume()
            }
        }.resume()
    }

    func assignTasbeeh() {
        if selectedType == "Single" {
            let payload: [String: Any] = [
                "SingleTasbeeh_id": Int(selectedGroupOrSingle) ?? 0,
                "Tasbeeh_id": Int(selectedTasbeeh.dropFirst(2)) ?? 0,
                "Goal": Int(count) ?? 0,
                "Enddate": formattedDate(deadline),
                "schedule": selectedDay,
                
            ]
            postRequest(
                urlString: "http://192.168.137.1/DigitalTasbeehWithFriendsApi/api/Sigle/Assigntosingletasbeeh",
                payload: payload
            )
        } else if selectedType == "group" && distributionType == "Equally" {
            let payload: [String: Any] = [
                "Group_id": Int(selectedGroupOrSingle) ?? 0,
                "Tasbeeh_id": Int(selectedTasbeeh.dropFirst(2)) ?? 0,
                "Goal": Int(count) ?? 0,
                "End_date": formattedDate(deadline),
                "schedule": selectedDay,
                
            ]
            postRequest(
                urlString: "http://192.168.137.1/DigitalTasbeehWithFriendsApi/api/AssignTasbeeh/AssignTasbeeh",
                payload: payload,
                then: { id in
                    let groupId = Int(selectedGroupOrSingle) ?? 0
                    let query = "groupid=\(groupId)&tasbeehid=\(id)"
                    postRequest(
                        urlString: "http://192.168.0.130/DigitalTasbeehWithFriendsApi/api/Request/DistributeTasbeehEqually?\(query)",
                        payload: [:]
                    )
                }
            )
        }
    }

    func postRequest(urlString: String, payload: [String: Any], then: ((Int) -> Void)? = nil) {
        guard let url = URL(string: urlString),
              let jsonData = try? JSONSerialization.data(withJSONObject: payload) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data,
               let decoded = try? JSONDecoder().decode([String: AnyCodable].self, from: data),
               let id = decoded["ID"]?.value as? Int {
                then?(id)
            }
        }.resume()
    }

    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter.string(from: date)
    }
}

// MARK: - Preview

struct AssignTasbeehView_Previews: PreviewProvider {
    static var previews: some View {
        AssignTasbeehView(userId: 1)
            .previewDevice("iPhone 14 Pro")
    }
}

