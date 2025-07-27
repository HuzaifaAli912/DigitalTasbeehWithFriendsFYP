import SwiftUI

// MARK: - Home View
struct HomeView: View {
    let user: LoggedInUser

    var body: some View {
        NavigationStack {
            VStack {
                Text("Welcome, \(user.username)")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.top, 30)

                Spacer().frame(height: 20)

                // First Row (✅ Create Tasbeeh navigates to AllTasbeehView)
                HStack(spacing: 20) {
                    NavigationLink(destination: AllTasbeehView(userId: user.id)) {
                        HomeButton(iconName: "square.grid.3x3.fill", label: "Create Tasbeeh")
                    }

                    NavigationLink(destination: GroupListView(userId: user.id)) {
                        HomeButton(iconName: "person.3.fill", label: "Group/Single")
                    }
                }

                Spacer().frame(height: 25)

                // Second Row
                HStack(spacing: 20) {
                    NavigationLink(destination: AssignTasbeehView(userId: user.id)) {
                        HomeButton(iconName: "hand.point.right.fill", label: "Assign Tasbeeh")
                    }

                    // History Button - Placeholder for now
                    NavigationLink(destination: HistoryView(userId: user.id)) {  // Update this later with the correct destination
                        HomeButton(iconName: "scroll.fill", label: "History")
                    }
                }

                Spacer().frame(height: 25)

                // Third Row
                HStack(spacing: 20) {
                    NavigationLink(destination: NotificationView(userId: user.id)) {
                        HomeButton(iconName: "bell.fill", label: "Notification")
                    }

                    NavigationLink(destination: AllFriendsView(userId: user.id)) {
                        HomeButton(iconName: "person.2.fill", label: "Friends")
                    }
                }

                Spacer().frame(height: 40)

                // Logout Button with label
                Button(action: {
                    print("Logout tapped")
                }) {
                    VStack {
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.blue)
                                .frame(width: 80, height: 80)

                            Image(systemName: "arrowshape.turn.up.left.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 30, height: 30)
                                .foregroundColor(.white)
                        }

                        Text("Logout")
                            .font(.footnote)
                            .foregroundColor(.blue)
                            .padding(.top, 5) // Show the "Logout" text beneath the icon
                    }
                }

                Spacer()
            }
            .padding()
            .navigationBarBackButtonHidden(true)
        }
    }
}

// MARK: - Home Button View
struct HomeButton: View {
    var iconName: String
    var label: String

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.blue)
                    .frame(width: 100, height: 100)

                Image(systemName: iconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 45, height: 45)
                    .foregroundColor(.white)
            }

            Text(label)
                .font(.footnote)
                .multilineTextAlignment(.center)
                .frame(width: 100)
        }
    }
}




// MARK: - Preview
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(user: LoggedInUser(id: 1, username: "PreviewUser", email: "preview@example.com"))
    }
}

