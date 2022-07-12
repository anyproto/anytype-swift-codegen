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
        let importsFilePath: String
        
        static let defaultStringValue: String = ""
        
        public static func evaluate(_ m: CommandMode) -> Result<Self, CommandantError<Swift.Error>> {
            curry(Self.init)
                <*> m <| Option(key: "filePath", defaultValue: defaultStringValue, usage: "The path to the file in 'generate' action.")
                <*> m <| Option(key: "outputFilePath", defaultValue: defaultStringValue, usage: "Use with flag --filePath. It will output to this file")
                <*> m <| Option(key: "importsFilePath", defaultValue: defaultStringValue, usage: "Import file that will be included at top after comments if presented")
        }
    }
}

struct GenerateInitializersCommand: CommandProtocol {
    let verb = "generateInitializes"
    let function = "Generate initializers"

    func run(_ options: Options) throws {
        let (source, target) = try CommandUtility
            .validatedFiles(input: options.filePath, output: options.outputFilePath)
        
        
        let sourceFile = try SyntaxParser.parse(URL(fileURLWithPath: source.path))
        let result = InitializerGenerator(scope: .public).generate(sourceFile)

//        let formatter = CodeFormatter()
        
        let output = [
            CommandUtility.generateHeader(importsFilePath: options.importsFilePath),
            result.description
        ].joined(separator: "\n")
//        let formattedOutput = try formatter.format(source: output)
//        try target.write(formattedOutput)
        try target.write(output)
    }
}
