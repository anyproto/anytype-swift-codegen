import Foundation
import PackagePlugin

@main
struct ServiceGenPlugin: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) throws -> [Command] {
        
        let fileManager = FileManager.default
        
        let configuration = [context.package.directory, target.directory]
          .map { $0.appending("anytypeGen.yml") }
          .filter { fileManager.fileExists(atPath: $0.string) }
          .first
        
        return [
            .prebuildCommand(
                displayName: "ServiceGen Plugin",
                executable: try context.tool(named: "anytype-codegen-binary").path,
                arguments: [
                    "--yaml-path", configuration?.string ?? "",
                    "--project-dir", context.package.directory,
                    "--output-dir", context.pluginWorkDirectory
                ],
                outputFilesDirectory: context.pluginWorkDirectory
            )
        ]
    }
}
