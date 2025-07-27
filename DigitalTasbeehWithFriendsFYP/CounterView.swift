import SwiftUI

// MARK: - TasbeehDetailItem Model
struct TasbeehDetailItem: Identifiable {
    var id: Int
    var text: String // Text for the Tasbeeh item
    var count: Int   // Count for this Tasbeeh item
}

// MARK: - TasbeehLog Model (for progress log) - Conform to Decodable
struct TasbeehLog: Identifiable, Decodable {
    var id: Int
    var current: Int
    var goal: Int
    var note: String?
}

// Circular Progress View
struct CircularProgress: View {
    var progress: CGFloat
    var size: CGFloat = 150
    var strokeWidth: CGFloat = 10
    
    var body: some View {
        ZStack {
            let radius = (size - strokeWidth) / 2
            let circumference = radius * 2 * .pi
            let strokeDashOffset = circumference - (progress / 100) * circumference
            
            // Background circle
            Circle()
                .stroke(Color.gray.opacity(0.8), lineWidth: strokeWidth)
                .frame(width: size, height: size)
            
            // Progress circle
            Circle()
                .trim(from: 0, to: progress / 100)
                .stroke(Color.blue, style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round))
                .rotationEffect(.degrees(-90)) // Corrected this line
                .frame(width: size, height: size)
            
            Text("\(Int(progress))%")
                .font(.title2)
                .bold()
                .foregroundColor(.black)
        }
    }
}

// Main View for Tasbeeh Group
struct TasbeehGroup: View {
    var groupid: Int
    var Userid: Int
    var tasbeehid: Int
    var title: String
    
    @State private var progress: CGFloat = 0
    @State private var savedProgress: TasbeehLog? = nil
    @State private var itemProgress: [Int: Int] = [:]
    @State private var loading: Bool = true
    @State private var showOptions = false
    @State private var tasbeehdeatiles: [TasbeehDetailItem] = []
    @State private var showModal = false
    @State private var isSaving: Bool = false
    @State private var saveError: Bool = false
    @State private var notes: String = ""
    @State private var showReminderModal = false
    @State private var isChainComplete = false
    @State private var showModalForCloseTasbeeh = false
    @State private var currentTasbeehType: String = ""
    @Environment(\.presentationMode) var presentationMode
    
    // Fetch the tasbeeh details from the backend
    func fetchTasbeehDetails() {
        let url = URL(string: "https://yourapi.com/fetchtasbeehlog?UserId=\(Userid)&groupid=\(groupid)&tasbeehid=\(tasbeehid)")!
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let data = data, error == nil {
                let decoder = JSONDecoder()
                if let result = try? decoder.decode(TasbeehLog.self, from: data) {
                    DispatchQueue.main.async {
                        self.savedProgress = result
                        self.progress = CGFloat(result.current) / CGFloat(result.goal) * 100
                    }
                }
            }
        }.resume()
    }
    
    // Increment the progress by 1
    func incrementProgress(for item: TasbeehDetailItem) {
        guard let activeIndex = tasbeehdeatiles.firstIndex(where: { $0.id == item.id }) else {
            handleChainCompletion()
            return
        }

        itemProgress[activeIndex, default: 0] += 1
        saveProgress()

        // Check if item is completed
        if itemProgress[activeIndex]! >= tasbeehdeatiles[activeIndex].count {
            checkChainCompletion()
        }
    }
    
    func checkChainCompletion() {
        isChainComplete = tasbeehdeatiles.allSatisfy { item in
            (itemProgress[item.id] ?? 0) >= item.count
        }
    }
    
    // Handle chain completion (when all tasks are done)
    func handleChainCompletion() {
        // Implement logic for completing chain, e.g., resetting the progress and notifying server
        print("Chain Completed!")
    }
    
    // Save progress to AsyncStorage or server
    func saveProgress() {
        // Replace with your API call or local storage logic
        print("Progress saved: \(itemProgress)")
    }
    
    // Close Tasbeeh (Button)
    func closeTasbeeh() {
        // API call to close tasbeeh
        print("Closing Tasbeeh")
        // After closing tasbeeh
        presentationMode.wrappedValue.dismiss()
    }
    
    // Modal actions for options
    func toggleOptions() {
        showOptions.toggle()
    }
    
    // Modal actions for closing tasbeeh
    func closeModal() {
        showModalForCloseTasbeeh.toggle()
    }
    
    var body: some View {
        VStack {
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss() // Navigate back
                }) {
                    Image(systemName: "arrow.backward.circle.fill")
                        .resizable()
                        .frame(width: 40, height: 40)
                }
                Spacer()
                Text(title)
                    .font(.title)
                    .bold()
                    .padding()
                Spacer()
                Button(action: toggleOptions) {
                    Image(systemName: "ellipsis.circle")
                        .resizable()
                        .frame(width: 30, height: 30)
                }
            }
            .padding()

            CircularProgress(progress: progress)
            
            Text("Tasbeeh Fatiha")
                .font(.title3)
                .padding()

            // Progress text
            Text("\(progress)% Completed")

            List(tasbeehdeatiles, id: \.id) { item in
                HStack {
                    Text(item.text)
                    Spacer()
                    Text("\(item.count)")
                    Button(action: {
                        incrementProgress(for: item)
                    }) {
                        Text("Increment")
                            .foregroundColor(.blue)
                            .padding()
                    }
                }
            }
            
            Spacer()

            // Floating Action Button (FAB) for actions
            Button(action: closeModal) {
                Text("Close Tasbeeh")
                    .foregroundColor(.white)
                    .frame(width: 200, height: 60)
                    .background(Color.red)
                    .cornerRadius(30)
                    .font(.title2)
            }
            .padding()

            // Modal for showing options
            if showOptions {
                VStack {
                    Text("Progress")
                    Text("Close Tasbeeh")
                }
            }
        }
        .onAppear {
            fetchTasbeehDetails()
        }
        .sheet(isPresented: $showModalForCloseTasbeeh) {
            VStack {
                Text("Are you sure you want to close this Tasbeeh?")
                Button("Yes") {
                    closeTasbeeh()
                }
                Button("No") {
                    showModalForCloseTasbeeh.toggle()
                }
            }
        }
    }
}

struct TasbeehGroup_Previews: PreviewProvider {
    static var previews: some View {
        TasbeehGroup(groupid: 1, Userid: 1, tasbeehid: 1, title: "Tasbeeh Fatiha")
    }
}

