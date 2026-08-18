import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var scanStore: ScanStore
    @State private var isPresentingScan = false

    var body: some View {
        NavigationStack {
            Group {
                if scanStore.scans.isEmpty {
                    ContentUnavailableView(
                        "No Scans Yet",
                        systemImage: "cube.transparent",
                        description: Text("Tap New Scan to capture a room.")
                    )
                } else {
                    List(scanStore.scans) { scan in
                        Text(scan.name)
                    }
                }
            }
            .navigationTitle("SceneShift")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("New Scan") {
                        isPresentingScan = true
                    }
                }
            }
            .fullScreenCover(isPresented: $isPresentingScan) {
                ScanSessionView()
                    .environmentObject(scanStore)
            }
        }
    }
}
