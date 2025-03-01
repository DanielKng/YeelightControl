import SwiftUI
import Core
import UI

struct ContentView: View {
    @EnvironmentObject var serviceContainer: BaseServiceContainer
    
    var body: some View {
        TabView {
            DeviceListView()
                .tabItem {
                    Label("Lights", systemImage: "lightbulb.fill")
                }
            
            SceneGalleryView()
                .tabItem {
                    Label("Scenes", systemImage: "theatermasks.fill")
                }
            
            AutomationListView()
                .tabItem {
                    Label("Automation", systemImage: "timer")
                }
        }
        .environmentObject(serviceContainer)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(BaseServiceContainer())
    }
}
