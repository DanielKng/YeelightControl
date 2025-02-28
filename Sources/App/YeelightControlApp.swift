import SwiftUI

@main
struct YeelightControlApp: App {
    // Initialize the YeelightManager as a StateObject to persist across view updates
    @StateObject private var yeelightManager = YeelightManager.shared
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(yeelightManager)
        }
    }
}
