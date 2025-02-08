import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var appPath = ""
    @State private var resultMessage = ""
    @State private var appIcon: NSImage?
    @State private var appName = ""

    var body: some View {
        VStack {
            VStack {
                if let icon = appIcon {
                    VStack {
                        Image(nsImage: icon)
                            .resizable()
                            .frame(width: 128, height: 128)
                            .padding()
                        Text(appName)
                            .font(.headline)
                            .foregroundColor(.primary)
                            .padding(.top, 4)
                    }
                    .onDrop(of: [.fileURL], isTargeted: nil) { providers in
                        handleDrop(providers)
                    }
                } else {
                    VStack {
                        Text("Drag an app here")
                            .padding()
                            .foregroundColor(.gray)
                    }
                    .frame(width: 150, height: 150)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(12)
                    .onDrop(of: [.fileURL], isTargeted: nil) { providers in
                        handleDrop(providers)
                    }
                }
            }
            Text(resultMessage)
                .foregroundColor(.blue)
                .padding()
        }
        .padding()
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        for provider in providers where provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { (urlData, _) in
                DispatchQueue.main.async {
                    if let urlData = urlData as? Data,
                       let url = URL(dataRepresentation: urlData, relativeTo: nil),
                       url.pathExtension == "app" {
                        self.appPath = url.path
                        self.extractAppIcon()
                        self.extractAppName()
                        self.checkApp()
                    }
                }
            }
            return true
        }
        return false
    }

    private func checkApp() {
        guard !appPath.isEmpty else {
            return
        }

        let contentsPath = "\(appPath)/Contents"
        let infoPlistPath = "\(contentsPath)/Info.plist"

        // Extract the executable name from Info.plist
        guard let executableName = getExecutableName(from: infoPlistPath) else {
            resultMessage = "Failed to find executable."
            return
        }

        let executablePath = "\(contentsPath)/MacOS/\(executableName)"

        // Check if the executable links against UIKit from iOS Support
        if checkForMacCatalyst(in: executablePath) {
            resultMessage = "✅ This app is a Mac Catalyst app."
        } else {
            resultMessage = "❌ This app is NOT a Mac Catalyst app."
        }
    }

    private func getExecutableName(from plistPath: String) -> String? {
        let process = Process()
        process.launchPath = "/usr/bin/defaults"
        process.arguments = ["read", plistPath, "CFBundleExecutable"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.launch()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func checkForMacCatalyst(in executablePath: String) -> Bool {
        let process = Process()
        process.launchPath = "/usr/bin/otool"
        process.arguments = ["-L", executablePath]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.launch()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        let output = String(data: data, encoding: .utf8) ?? ""

        // Check for any references to iOS Support
        return output.contains("/System/iOSSupport/")
    }

    private func extractAppIcon() {
        let contentsPath = "\(appPath)/Contents"
        let infoPlistPath = "\(contentsPath)/Info.plist"

        guard getExecutableName(from: infoPlistPath) != nil else {
            resultMessage = "Failed to find executable."
            self.appIcon = nil
            return
        }

        let bundleURL = URL(fileURLWithPath: appPath)
        if let bundle = Bundle(url: bundleURL),
           let iconName = bundle.infoDictionary?["CFBundleIconFile"] as? String {

            var iconPath = "\(contentsPath)/Resources/\(iconName)"

            // Append .icns extension if it's missing
            if !iconPath.hasSuffix(".icns") {
                iconPath += ".icns"
            }

            if let icon = NSImage(contentsOfFile: iconPath) {
                self.appIcon = icon
            } else {
                self.appIcon = nil
            }
        } else {
            self.appIcon = nil
        }
    }

    private func extractAppName() {
        let contentsPath = "\(appPath)/Contents"
        let infoPlistPath = "\(contentsPath)/Info.plist"

        let process = Process()
        process.launchPath = "/usr/bin/defaults"
        process.arguments = ["read", infoPlistPath, "CFBundleDisplayName"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.launch()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        // swiftlint:disable line_length
        if let name = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty {
            self.appName = name
        } else {
            self.appName = (getExecutableName(from: infoPlistPath) ?? "Unknown App")
        }
        // swiftlint:enable line_length
    }
}

#Preview {
    ContentView()
}
