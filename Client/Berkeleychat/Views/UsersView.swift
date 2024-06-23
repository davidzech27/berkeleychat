import AVFoundation
import SwiftUI

struct UsersView: View {
    @Environment(Model.self) var model
    @State private var users = [UserModel]()
    @State private var currentUserEmail: String?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if users.isEmpty {
                ProgressView()
                    .foregroundColor(.white)
            } else {
                GeometryReader { geometry in
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: 0) {
                            ForEach(users) { user in
                                UserItemView(user: user, usersCount: users.count, current: user.email == currentUserEmail, totalUsers: users.count)
                                    .frame(width: geometry.size.width, height: geometry.size.height)
                            }
                        }
                    }
                    .scrollTargetBehavior(.paging)
                    .scrollPosition(id: $currentUserEmail, anchor: .top)
                    .onAppear {
                        if users.isEmpty {
                            return
                        }

                        // audioPlayerManager.startPlayback(url: URL(string: users.first!.introUrl)!)

                        // print(newValue)

                        // audioPlayerManager.stopPlayback()
                    }
                }
                .edgesIgnoringSafeArea(.all)
            }
        }
        .task {
            await fetchUsers()
        }
    }

    private func fetchUsers() async {
        do {
            let fetchedUsers = try await model.grpc.getUsers(email: model.auth.localUser?.email ?? "", major: model.auth.localUser?.major ?? "")
            users = fetchedUsers.users.map { user in
                UserModel(email: user.email, name: user.name, profilePhotoUrl: user.profilePhotoURL,
                          major: user.major, courses: user.courses, introUrl: user.introURL, messages: user.messages)
            }
            print("Fetched users:", users.count)
        } catch {
            print("Error fetching users:", error)
        }
    }
}

struct UserItemView: View {
    let user: UserModel
    let usersCount: Int
    let current: Bool
    let totalUsers: Int

    @State private var audioPlayerManager = AudioPlayerManager()

    @State private var isVisible = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer()

            // if current {
            AsyncImage(url: URL(string: user.profilePhotoUrl)) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                case let .success(image):

                    // if current {
                    image
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .transition(.flipFromBottom)
                // } else {
                //    Text("")
                // }
                case .failure:
                    Image(systemName: "photo")
                        .foregroundColor(.gray)
                @unknown default:
                    EmptyView()
                }
            }
            // }

            VStack(alignment: .leading, spacing: 4) {
                Text(user.name)
                    .foregroundColor(.white)
                    .font(.title3)
                    .bold()

                Text("@\(user.email.split(separator: "@").first ?? "")")
                    .foregroundColor(.white)
                    .font(.subheadline)
                    .opacity(0.75)
            }

            Spacer()

            ForEach(user.messages, id: \.self) { message in

                if message.count < 5 {
                    Text("")
                } else {
                    HoveringView {
                        Text(message)
                            .foregroundColor(.white)
                            .font(.subheadline)
                            .opacity(0.75)
                    }
                }
            }

            Spacer()
        }
        .padding(16)
        .detectVisibility(isVisible: $isVisible)
        .onChange(of: isVisible) { newValue in
            if newValue {
                audioPlayerManager.startPlayback(url: URL(string: user.introUrl)!)
            } else {
                audioPlayerManager.stopPlayback()
            }
        }
    }
}

struct HoveringView<Content: View>: View {
    let content: Content
    let amplitude: CGFloat
    let period: Double

    @State private var phase: CGFloat = 0

    init(amplitude: CGFloat = 15, period: Double = 2, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.amplitude = amplitude
        self.period = period
    }

    var body: some View {
        content
            .offset(x: xOffset, y: yOffset)
            .onAppear {
                withAnimation(.linear(duration: period).repeatForever(autoreverses: true)) {
                    phase = 2 * .pi
                }
            }
    }

    private var xOffset: CGFloat {
        amplitude * sin(phase)
    }

    private var yOffset: CGFloat {
        amplitude * cos(phase * 1.3)
    }
}

// extension String {
//    func skipInvalidUnicode() -> String {
//        return String(unicodeScalars.filter { $0.isASCII || $0.properties.isValidUnicode })
//    }
// }
//
//
@Observable
class AudioPlayerManager {
    var player: AVPlayer?
    var isPlaying: Bool = false

    func startPlayback(url: URL) {
        print(url)
        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        player?.play()
        isPlaying = true
    }

    func stopPlayback() {
        player?.pause()
        isPlaying = false
    }

    func togglePlayback() {
        if isPlaying {
            stopPlayback()
        } else {
            player?.play()
            isPlaying = true
        }
    }
}

struct VisibilityDetector: ViewModifier {
    @Binding var isVisible: Bool

    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .preference(key: VisibilityPreferenceKey.self, value: geometry.frame(in: .global))
                }
            )
            .onPreferenceChange(VisibilityPreferenceKey.self) { bounds in
                DispatchQueue.main.async {
                    self.isVisible = isViewVisible(bounds)
                }
            }
    }

    private func isViewVisible(_ bounds: CGRect) -> Bool {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first
        else {
            return false
        }

        return bounds.intersects(window.frame)
    }
}

struct VisibilityPreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

extension View {
    func detectVisibility(isVisible: Binding<Bool>) -> some View {
        modifier(VisibilityDetector(isVisible: isVisible))
    }
}
