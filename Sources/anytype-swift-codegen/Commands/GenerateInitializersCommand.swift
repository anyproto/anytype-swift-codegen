import Foundation
import Curry
import Commandant
import Files
import SwiftSyntax
import SwiftSyntaxParser
import AnytypeSwiftCodegen

extension GenerateInitializersCommand {
    struct Options: OptionsProtocol {
        let filePath: String
        let outputFilePath: String
        let templateFilePath: String
        
        static let defaultStringValue: String = ""
        
        public static func evaluate(_ m: CommandMode) -> Result<Self, CommandantError<Swift.Error>> {
            curry(Self.init)
                <*> m <| Option(key: "filePath", defaultValue: defaultStringValue, usage: "The path to the file in 'generate' action.")
                <*> m <| Option(key: "outputFilePath", defaultValue: defaultStringValue, usage: "Use with flag --filePath. It will output to this file")
                <*> m <| Option(key: "templateFilePath", defaultValue: defaultStringValue, usage: "Stencill template path")
        }
    }
}

struct GenerateInitializersCommand: CommandProtocol {
    let verb = "generateInitializes"
    let function = "Generate initializers"

    func run(_ options: Options) throws {
        let (source, target) = try CommandUtility
            .validatedFiles(
                input: options.filePath,
                output: options.outputFilePath
            )
        
        let templateFile = try File(path: options.templateFilePath)
        let template = try String(contentsOfFile: templateFile.path)
        
        let sourceFile = try SyntaxParser.parse(URL(fileURLWithPath: source.path))
        let result = try InitializerGenerator(template: template).generate(sourceFile)
        
        try target.write(result)
    }
}
