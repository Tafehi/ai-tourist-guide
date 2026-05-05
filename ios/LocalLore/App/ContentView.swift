import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            CameraView()
                .tabItem {
                    Label("Camera", systemImage: "camera")
                }
            MapView()
                .tabItem {
                    Label("Map", systemImage: "map")
                }
            LibraryView()
                .tabItem {
                    Label("Library", systemImage: "books.vertical")
                }
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}

#Preview {
    ContentView()
}
