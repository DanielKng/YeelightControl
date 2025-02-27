import SwiftUI

/// Root view of the application that handles initial routing
/// Shows either onboarding for first-time users or the main app interface
struct ContentView: View {
    // MARK: - Properties
    
    /// Access to the Yeelight device manager
    @EnvironmentObject private var yeelightManager: YeelightManager
    
    /// Access to network connectivity status
    @EnvironmentObject private var networkMonitor: NetworkMonitor
    
    /// Determines if this is the first app launch
    @State private var isFirstLaunch: Bool = !DeviceStorage.shared.hasCompletedOnboarding
    
    /// Controls visibility of network connectivity alert
    @State private var showNetworkAlert: Bool = false
    
    // MARK: - Body
    
    var body: some View {
        Group {
            if isFirstLaunch {
                OnboardingView(isFirstLaunch: $isFirstLaunch)
                    .transition(.opacity)
            } else {
                MainView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: isFirstLaunch)
        .onChange(of: networkMonitor.isConnected) { isConnected in
            // Show network alert if connection is lost (but not during onboarding)
            if !isConnected && !isFirstLaunch {
                showNetworkAlert = true
            }
        }
        .alert(
            "Network Connection Lost",
            isPresented: $showNetworkAlert,
            actions: {
                Button("OK", role: .cancel) {}
            },
            message: {
                Text("Please check your WiFi connection to control your Yeelight devices.")
            }
        )
    }
}

// MARK: - Onboarding View

/// Provides a multi-page onboarding experience for first-time users
struct OnboardingView: View {
    // MARK: - Properties
    
    /// Binding to control when onboarding is complete
    @Binding var isFirstLaunch: Bool
    
    /// Tracks the current onboarding page
    @State private var currentPage = 0
    
    // MARK: - Body
    
    var body: some View {
        TabView(selection: $currentPage) {
            // MARK: Welcome page
            welcomePage
                .tag(0)
            
            // MARK: Network permissions page
            networkPermissionsPage
                .tag(1)
            
            // MARK: Final setup page
            finalSetupPage
                .tag(2)
        }
        .tabViewStyle(PageTabViewStyle())
        .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
    }
    
    // MARK: - Page Views
    
    /// First onboarding page with welcome message
    private var welcomePage: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "lightbulb.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                .foregroundColor(.yellow)
            
            Text("Welcome to YeelightControl")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Control your Yeelight smart lights with ease")
                .font(.title3)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
            
            continueButton(text: "Get Started") {
                withAnimation {
                    currentPage = 1
                }
            }
        }
    }
    
    /// Second onboarding page explaining network permissions
    private var networkPermissionsPage: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "network")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                .foregroundColor(.blue)
            
            Text("Network Access")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("YeelightControl needs access to your local network to discover and control your lights")
                .font(.title3)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
            
            continueButton(text: "Continue") {
                withAnimation {
                    currentPage = 2
                }
            }
        }
    }
    
    /// Final onboarding page with completion button
    private var finalSetupPage: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                .foregroundColor(.green)
            
            Text("You're All Set!")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Start discovering and controlling your Yeelight devices")
                .font(.title3)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
            
            continueButton(text: "Get Started") {
                // Mark onboarding as completed in persistent storage
                DeviceStorage.shared.completeOnboarding()
                
                // Transition to main app
                withAnimation {
                    isFirstLaunch = false
                }
            }
        }
    }
    
    // MARK: - Helper Views
    
    /// Creates a standardized continue button for onboarding
    /// - Parameters:
    ///   - text: Button text to display
    ///   - action: Action to perform when tapped
    /// - Returns: A styled button view
    private func continueButton(text: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(text)
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .cornerRadius(10)
                .padding(.horizontal)
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .environmentObject(YeelightManager.shared)
        .environmentObject(NetworkMonitor())
} 