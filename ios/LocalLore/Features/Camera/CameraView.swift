import SwiftUI

struct CameraView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 64))
                    .foregroundStyle(.secondary)
                Text("Camera")
                    .font(.title)
                Text("Point at artwork or landmarks to identify them")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Camera")
        }
    }
}

#Preview {
    CameraView()
}
