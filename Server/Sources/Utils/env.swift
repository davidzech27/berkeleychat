import Foundation

func loadEnvironmentVariables() {
    guard let envFileContent = try? String(contentsOfFile: ".env", encoding: .utf8) else {
        fatalError("Could not load .env file")
    }

    let lines = envFileContent.split(separator: "\n")
    for line in lines {
        let parts = line.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: true)
        if parts.count == 2 {
            let key = String(parts[0]).trimmingCharacters(in: .whitespacesAndNewlines)
            let value = String(parts[1]).trimmingCharacters(in: .whitespacesAndNewlines)
            setenv(key, value, 1)
        }
    }
}
