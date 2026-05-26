import SwiftUI

/// In-app start screen shown while the initial schedule loads. Visually identical to the
/// static iOS launch screen (same horseshoe + cream) so the handoff is seamless, then it
/// holds during data loading and fades to the main UI (KakaoTalk-style).
struct SplashView: View {
    private let ink = Color(red: 0.11, green: 0.11, blue: 0.11)

    var body: some View {
        ZStack {
            Color("LaunchBackground").ignoresSafeArea()
            // horseshoe stays centered — matches the launch screen exactly
            Image("LaunchLogo")
            VStack {
                Spacer()
                ProgressView()
                    .tint(ink.opacity(0.55))
                Text("우마스케쥴")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(ink.opacity(0.5))
                    .padding(.top, 12)
            }
            .padding(.bottom, 54)
        }
    }
}
