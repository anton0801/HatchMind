//
//  WelcomeView.swift
//  Hatch Mind
//

import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var prefs: UserPreferences
    @State private var goToOnboarding = false
    @State private var showLogin = false
    @State private var float: CGFloat = 0

    var body: some View {
        ZStack {
            LinearGradient(colors: [.hmBgPrimary, .hmBgSoft],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            // Soft glow
            Circle()
                .fill(Color.hmYellowGlow.opacity(0.3))
                .frame(width: 280, height: 280)
                .blur(radius: 40)
                .offset(y: -120)

            VStack(spacing: 28) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(Color.hmYellow.opacity(0.18))
                        .frame(width: 200, height: 200)
                        .blur(radius: 12)
                    EggShape()
                        .fill(LinearGradient(colors: [.hmChickSoft, .hmYellow],
                                             startPoint: .top, endPoint: .bottom))
                        .frame(width: 130, height: 165)
                        .shadow(color: Color.hmYellowActive.opacity(0.3), radius: 18, y: 8)
                        .offset(y: float)

                    Image(systemName: "sparkles")
                        .font(.system(size: 22))
                        .foregroundColor(.hmOrange)
                        .offset(x: 70, y: -60)
                        .opacity(0.7)
                }
                .onAppear {
                    withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                        float = -8
                    }
                }
                .onDisappear { float = 0 }

                VStack(spacing: 12) {
                    Text("Welcome to\nHatch Mind")
                        .font(.system(size: 36, weight: .heavy, design: .rounded))
                        .foregroundColor(.hmTextPrimary)
                        .multilineTextAlignment(.center)

                    Text("Track every day, every degree, every egg —\nfrom set to hatch.")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.hmTextSecondary.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                Spacer()

                VStack(spacing: 12) {
                    Button {
                        prefs.haptic()
                        goToOnboarding = true
                    } label: { Text("Start") }
                    .buttonStyle(PrimaryButtonStyle())

                    Button {
                        prefs.haptic()
                        showLogin = true
                    } label: { Text("Log In") }
                    .buttonStyle(SecondaryButtonStyle())
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 30)
            }
            .padding(.horizontal, 16)
        }
        .fullScreenCover(isPresented: $goToOnboarding) {
            OnboardingView()
        }
        .sheet(isPresented: $showLogin) {
            LoginView()
        }
    }
}

struct LoginView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var prefs: UserPreferences
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showError: Bool = false
    @State private var animateGlow: Bool = false

    var body: some View {
        ZStack {
            Color.hmBgPrimary.ignoresSafeArea()

            VStack(spacing: 22) {
                ZStack {
                    Circle()
                        .fill(Color.hmYellow.opacity(0.2))
                        .frame(width: 100, height: 100)
                        .scaleEffect(animateGlow ? 1.1 : 1.0)
                        .opacity(animateGlow ? 0.5 : 0.9)
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 38))
                        .foregroundColor(.hmYellowActive)
                }
                .padding(.top, 40)

                Text("Log In")
                    .font(.hmTitle())
                    .foregroundColor(.hmTextPrimary)

                Text("Use the demo account to explore the app.")
                    .font(.hmBody())
                    .foregroundColor(.hmTextSecondary.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                VStack(spacing: 12) {
                    HMTextField(icon: "envelope.fill", placeholder: "Email", text: $email)
                    HMSecureField(icon: "key.fill", placeholder: "Password", text: $password)
                }
                .padding(.horizontal, 20)

                if showError {
                    Text("Wrong credentials. Try the demo account.")
                        .font(.hmCaption())
                        .foregroundColor(.hmStatusError)
                        .transition(.opacity)
                }

                Button {
                    prefs.haptic()
                    if email.lowercased() == "demo@hatchmind.app" && password == "demo123" {
                        prefs.isLoggedIn = true
                        prefs.hasCompletedOnboarding = true
                        prefs.profile = UserProfile.demo
                        presentationMode.wrappedValue.dismiss()
                    } else if !email.isEmpty && !password.isEmpty {
                        prefs.isLoggedIn = true
                        prefs.hasCompletedOnboarding = true
                        prefs.profile = UserProfile(name: email.components(separatedBy: "@").first ?? "Farmer",
                                                    farmName: "My Coop",
                                                    email: email)
                        presentationMode.wrappedValue.dismiss()
                    } else {
                        withAnimation { showError = true }
                    }
                } label: { Text("Log In") }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, 20)

                Button {
                    email = "demo@hatchmind.app"
                    password = "demo123"
                    prefs.haptic()
                } label: {
                    Text("Use demo account")
                        .font(.hmCaption())
                        .foregroundColor(.hmYellowActive)
                        .underline()
                }

                Spacer()
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                animateGlow = true
            }
        }
        .onDisappear { animateGlow = false }
    }
}

struct HMTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(.hmYellowActive)
            TextField(placeholder, text: $text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .foregroundColor(.hmTextPrimary)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(Color.hmCard)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.hmDivider, lineWidth: 1))
    }
}

struct HMSecureField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(.hmYellowActive)
            SecureField(placeholder, text: $text)
                .foregroundColor(.hmTextPrimary)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(Color.hmCard)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.hmDivider, lineWidth: 1))
    }
}
