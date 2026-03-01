## iOS Development

- **Verify builds with xcbeautify** for cleaner output
  - `xcodebuild -scheme <SchemeName> -configuration Debug -sdk iphonesimulator build | xcbeautify`
  - Example: `xcodebuild -scheme iGotYouHaha -configuration Debug -sdk iphonesimulator build | xcbeautify`
- Use XcodeGen (`project.yml`) for project generation instead of committing `.xcodeproj`
- Install xcbeautify: `brew install xcbeautify`
