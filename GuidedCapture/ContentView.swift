/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Top-level SwiftUI container view for the entire app.
*/

import RealityKit
import SwiftUI
import os

@available(iOS 17.0, *)
/// The root of the SwiftUI view graph.
struct ContentView: View {
    static let logger = Logger(subsystem: GuidedCaptureSampleApp.subsystem,
                                category: "ContentView")

    @StateObject var appModel: AppDataModel = AppDataModel.instance
    
    @State private var showReconstructionView: Bool = false
    @State private var showErrorAlert: Bool = false
    @State private var showStartView: Bool = false
    @State private var showCompleteView: Bool = false
    @State private var startTime: Date?
    @State private var endTime: Date?
    private var showProgressView: Bool {
        appModel.state == .completed || appModel.state == .restart || appModel.state == .ready
    }

    var body: some View {
        VStack {
            if appModel.state == .capturing {
                if let session = appModel.objectCaptureSession {
                    CapturePrimaryView(session: session)
                }
            } else if showProgressView {
                CircularProgressView()
            }
        }
        .onChange(of: appModel.state) { _, newState in
            if newState == .failed {
                showErrorAlert = true
                showReconstructionView = false
            } else {
                showErrorAlert = false
                showReconstructionView = newState == .reconstructing || newState == .viewing
                if newState == .reconstructing {
                    showStartView = true
                }
            }
        }
        .sheet(isPresented: $showStartView) {
            VStack {
                Text("Start Processing")
                    .font(.title)
                    .padding()
                Button("OK") {
                    startTime = Date()
                    showStartView = false
                }
                .padding()
            }
        }
        .sheet(isPresented: $showReconstructionView) {
            if let folderManager = appModel.scanFolderManager {
                ReconstructionPrimaryView(outputFile: folderManager.modelsFolder.appendingPathComponent("model-mobile.usdz"))
                    .onAppear {
                        showCompleteView = true
                    }
            }
        }
        .sheet(isPresented: $showCompleteView) {
            VStack {
                Text("Completed")
                    .font(.title)
                    .padding()
                if let startTime = startTime {
                    let duration = Date().timeIntervalSince(startTime)
                    Text("Time taken: \(duration) seconds")
                        .padding()
                }
                Button("OK") {
                    showCompleteView = false
                }
                .padding()
            }
        }
        .alert(
            "Failed:  " + (appModel.error != nil  ? "\(String(describing: appModel.error!))" : ""),
            isPresented: $showErrorAlert,
            actions: {
                Button("OK") {
                    ContentView.logger.log("Calling restart...")
                    appModel.state = .restart
                }
            },
            message: {}
        )
        .environmentObject(appModel)
    }
}

private struct CircularProgressView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack {
            Spacer()
            ZStack {
                Spacer()
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: colorScheme == .light ? .black : .white))
                Spacer()
            }
            Spacer()
        }
    }
}

#if DEBUG
@available(iOS 17.0, *)
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
