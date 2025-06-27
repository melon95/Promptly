import Foundation
import SwiftUI

// A struct to decode the release information from GitHub API
struct GitHubRelease: Codable {
    let tagName: String
    let htmlURL: String
    
    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case htmlURL = "html_url"
    }
}

@MainActor
class UpdateManager: ObservableObject {
    @Published var isUpdateAvailable = false
    @Published var latestReleaseURL: URL?
    
    private let repoOwner = "melon95"
    private let repoName = "Promptly"
    
    func checkForUpdates() {
        let urlString = "https://api.github.com/repos/\(repoOwner)/\(repoName)/releases/latest"
        guard let url = URL(string: urlString) else {
            print("Invalid URL for GitHub API")
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error fetching releases: \(error.localizedDescription)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Invalid response from GitHub API")
                return
            }
            
            guard let data = data else {
                print("No data received from GitHub API")
                return
            }
            
            do {
                let release = try JSONDecoder().decode(GitHubRelease.self, from: data)
                // GitHub tags are often prefixed with 'v', e.g., "v1.2.3".
                // We need to remove it for comparison.
                let latestVersion = release.tagName.replacingOccurrences(of: "v", with: "")
                let currentVersion = VersionProvider.appVersion
                
                // Compare versions using numeric comparison.
                // This correctly handles "1.10.0" > "1.9.0".
                if latestVersion.compare(currentVersion, options: .numeric) == .orderedDescending {
                    DispatchQueue.main.async {
                        self.isUpdateAvailable = true
                        self.latestReleaseURL = URL(string: release.htmlURL)
                        print("A new version (\(latestVersion)) is available.")
                    }
                } else {
                    print("You are on the latest version.")
                }
            } catch {
                print("Error decoding release info: \(error.localizedDescription)")
            }
        }.resume()
    }
} 