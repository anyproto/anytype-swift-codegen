import Foundation
import PackagePlugin

@main
struct ServiceGenPlugin: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) throws -> [Command] {
        
        return [
            .prebuildCommand(
                displayName: "ServiceGen Plugin",
                executable: try context.tool(named: "anytype-swift-codegen").path,
                arguments: [
                    "--yamlPath", context.package.directory.appending("anytypeGen.yml").string
                ],
                outputFilesDirectory: context.pluginWorkDirectory
            )
        ]
    }
}
