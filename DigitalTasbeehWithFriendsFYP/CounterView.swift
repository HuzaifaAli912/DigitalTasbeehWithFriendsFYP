//import SwiftUI
//
//// MARK: - Model
//struct TasbeehCounterModel {
//    let title: String
//    let arabicText: String
//    let currentCount: Int
//    let totalCount: Int
//}
//
//// MARK: - View
//struct TasbeehCounterView: View {
//    let tasbeeh: TasbeehCounterModel
//    @State private var count: Int
//    @State private var progress: CGFloat = 0
//
//    init(tasbeeh: TasbeehCounterModel) {
//        self.tasbeeh = tasbeeh
//        _count = State(initialValue: tasbeeh.currentCount)
//        _progress = State(initialValue: CGFloat(tasbeeh.currentCount) / CGFloat(tasbeeh.totalCount))
//    }
//
//    var body: some View {
//        VStack(spacing: 20) {
//            // Top Title + Menu (No back button)
//            HStack {
//                Spacer()
//                Text(tasbeeh.title)
//                    .font(.title2)
//                    .fontWeight(.bold)
//                Spacer()
//                Menu {
//                    Button("Progress") {
//                        print("Progress tapped")
//                    }
//
//                    Button(role: .destructive) {
//                        print("Close Tasbeeh tapped")
//                    } label: {
//                        Text("Close Tasbeeh")
//                            .foregroundColor(.red)
//                    }
//                } label: {
//                    Image(systemName: "slider.horizontal.3")
//                        .font(.title2)
//                        .foregroundColor(.black)
//                }
//            }
//            .padding(.horizontal)
//
//            // Circular Progress View
//            VStack {
//                ZStack {
//                    Circle()
//                        .stroke(Color.gray.opacity(0.2), lineWidth: 15)
//
//                    Circle()
//                        .trim(from: 0, to: progress)
//                        .stroke(Color.blue, style: StrokeStyle(lineWidth: 15, lineCap: .round))
//                        .rotationEffect(.degrees(-90))
//
//                    Text("\(Int(progress * 100))%")
//                        .font(.title)
//                        .fontWeight(.bold)
//                }
//                .frame(width: 140, height: 140)
//
//                Text("\(count) / \(tasbeeh.totalCount)")
//                    .font(.headline)
//            }
//
//            // Progress dots
//            HStack(spacing: 12) {
//                ForEach(0..<7, id: \.self) { i in
//                    Circle()
//                        .fill(i < (count * 7 / max(tasbeeh.totalCount, 1)) ? Color.blue : Color.gray.opacity(0.3))
//                        .frame(width: 12, height: 12)
//                }
//            }
//
//            // Arabic Tasbeeh text with counts
//            HStack(spacing: 10) {
//                Text("\(count)")
//                    .font(.headline)
//                    .foregroundColor(.white)
//                    .padding()
//                    .background(Circle().fill(Color.blue))
//
//                Text(tasbeeh.arabicText)
//                    .multilineTextAlignment(.center)
//                    .font(.system(size: 20))
//                    .foregroundColor(.black)
//
//                Text("\(tasbeeh.totalCount)")
//                    .font(.headline)
//                    .foregroundColor(.white)
//                    .padding()
//                    .background(Circle().fill(Color.blue))
//            }
//            .padding()
//            .background(Color.white)
//            .cornerRadius(12)
//            .shadow(radius: 2)
//            .padding(.horizontal)
//
//            Spacer()
//
//            // Large Count Button
//            Button(action: {
//                if count < tasbeeh.totalCount {
//                    count += 1
//                    withAnimation {
//                        progress = CGFloat(count) / CGFloat(tasbeeh.totalCount)
//                    }
//                }
//            }) {
//                Text("Count")
//                    .font(.title)
//                    .fontWeight(.bold)
//                    .frame(maxWidth: .infinity)
//                    .frame(height: 150)
//                    .background(Color.blue.opacity(0.8))
//                    .foregroundColor(.white)
//            }
//        }
//        .padding(.top)
//        .background(Color(.systemGray6))
//        .ignoresSafeArea(edges: .bottom)
//    }
//}
//
//// MARK: - Preview
//struct TasbeehCounterView_Previews: PreviewProvider {
//    static var previews: some View {
//        TasbeehCounterView(tasbeeh: TasbeehCounterModel(
//            title: "Tasbeeh Fatima",
//            arabicText: "سُبْحَانَ ٱللَّٰهِ وَبِحَمْدِهِ",
//            currentCount: 5,
//            totalCount: 33
//        ))
//    }
//}
//



import SwiftUI

// MARK: - Model
struct TasbeehCounterModel {
    let title: String
    let arabicText: String
    let currentCount: Int
    let totalCount: Int
    let tasbeehId: Int
    let groupId: Int
    let userId: Int
    let adminId: Int
}

// MARK: - View
struct TasbeehCounterView: View {
    let tasbeeh: TasbeehCounterModel
    @State private var count: Int
    @State private var progress: CGFloat = 0
    @State private var showProgressScreen = false

    init(tasbeeh: TasbeehCounterModel) {
        self.tasbeeh = tasbeeh
        _count = State(initialValue: tasbeeh.currentCount)
        _progress = State(initialValue: CGFloat(tasbeeh.currentCount) / CGFloat(tasbeeh.totalCount))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Top Title + Menu
                HStack {
                    Spacer()
                    Text(tasbeeh.title)
                        .font(.title2)
                        .fontWeight(.bold)
                    Spacer()
                    Menu {
                        Button("Progress") {
                            showProgressScreen = true
                        }

                        Button(role: .destructive) {
                            print("Close Tasbeeh tapped")
                        } label: {
                            Text("Close Tasbeeh")
                                .foregroundColor(.red)
                        }
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .font(.title2)
                            .foregroundColor(.black)
                    }
                }
                .padding(.horizontal)

                // Navigation Trigger
                NavigationLink(
                    destination: TasbeehProgressView(
                        groupid: tasbeeh.groupId,
                        userId: tasbeeh.userId,
                        adminId: tasbeeh.adminId,
                        tasbeehId: tasbeeh.tasbeehId,
                        title: tasbeeh.title
                    ),
                    isActive: $showProgressScreen
                ) {
                    EmptyView()
                }

                // Circular Progress View
                VStack {
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 15)

                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(Color.blue, style: StrokeStyle(lineWidth: 15, lineCap: .round))
                            .rotationEffect(.degrees(-90))

                        Text("\(Int(progress * 100))%")
                            .font(.title)
                            .fontWeight(.bold)
                    }
                    .frame(width: 140, height: 140)

                    Text("\(count) / \(tasbeeh.totalCount)")
                        .font(.headline)
                }

                // Progress dots
                HStack(spacing: 12) {
                    ForEach(0..<7, id: \.self) { i in
                        Circle()
                            .fill(i < (count * 7 / max(tasbeeh.totalCount, 1)) ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: 12, height: 12)
                    }
                }

                // Arabic Tasbeeh with Count
                HStack(spacing: 10) {
                    Text("\(count)")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Circle().fill(Color.blue))

                    Text(tasbeeh.arabicText)
                        .multilineTextAlignment(.center)
                        .font(.system(size: 20))
                        .foregroundColor(.black)

                    Text("\(tasbeeh.totalCount)")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Circle().fill(Color.blue))
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(radius: 2)
                .padding(.horizontal)

                Spacer()

                // Count Button
                Button(action: {
                    if count < tasbeeh.totalCount {
                        count += 1
                        withAnimation {
                            progress = CGFloat(count) / CGFloat(tasbeeh.totalCount)
                        }
                    }
                }) {
                    Text("Count")
                        .font(.title)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 150)
                        .background(Color.blue.opacity(0.8))
                        .foregroundColor(.white)
                }
            }
            .padding(.top)
            .background(Color(.systemGray6))
            .ignoresSafeArea(edges: .bottom)
        }
    }
}

// MARK: - Preview
struct TasbeehCounterView_Previews: PreviewProvider {
    static var previews: some View {
        TasbeehCounterView(tasbeeh: TasbeehCounterModel(
            title: "Tasbeeh Fatima",
            arabicText: "سُبْحَانَ ٱللَّٰهِ وَبِحَمْدِهِ",
            currentCount: 5,
            totalCount: 33,
            tasbeehId: 200,
            groupId: 1,
            userId: 101,
            adminId: 100
        ))
    }
}
