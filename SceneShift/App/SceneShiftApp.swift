import SwiftUI

@main
struct SceneShiftApp: App {
    @StateObject private var scanStore = ScanStore()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(scanStore)
        }
    }
}
