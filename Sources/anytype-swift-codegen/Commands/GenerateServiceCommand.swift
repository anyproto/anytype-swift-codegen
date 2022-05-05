import Foundation
import Curry
import Commandant
import Files
import SwiftSyntax
import AnytypeSwiftCodegen

extension GenerateServiceCommand {
    struct Options: OptionsProtocol {
        let filePath: String
        let outputFilePath: String
        let templateFilePath: String
        let importsFilePath: String
        let serviceFilePath: String
        
        static let defaultStringValue: String = ""
        
        public static func evaluate(_ m: CommandMode) -> Result<Self, CommandantError<Swift.Error>> {
            curry(Self.init)
                <*> m <| Option(key: "filePath", defaultValue: defaultStringValue, usage: "The path to the file in 'generate' action.")
                <*> m <| Option(key: "outputFilePath", defaultValue: defaultStringValue, usage: "Use with flag --filePath. It will output to this file")
                <*> m <| Option(key: "templateFilePath", defaultValue: defaultStringValue, usage: "Template file path")
                <*> m <| Option(key: "importsFilePath", defaultValue: defaultStringValue, usage: "Import file that will be included at top after comments if presented")
                <*> m <| Option(key: "serviceFilePath", defaultValue: defaultStringValue, usage: "Rpc service file that contains Rpc services descriptions in .proto (protobuffers) format.")
        }
    }
}

struct GenerateServiceCommand: CommandProtocol {
    let verb = "generateService"
    let function = "Generate protobuf services"

    func run(_ options: Options) throws {        
        let (source, target) = try CommandUtility
            .validatedFiles(input: options.filePath, output: options.outputFilePath)
         
        guard let serviceFile = try? File(path: options.serviceFilePath) else {
            throw Error.serviceFileNotExists(options.serviceFilePath)
        }
        guard serviceFile.extension == FileExtensions.protobufExtension.extName else {
            throw Error.fileShouldHaveExtension(serviceFile.path, .protobufExtension)
        }
        
        let sourceFile = try SyntaxParser.parse(URL(fileURLWithPath: source.path))
        let result = ServiceGenerator(
            scope: .public,
            templatePath: options.templateFilePath,
            serviceFilePath: options.serviceFilePath
        )
        .generate(sourceFile)
        
        let output = [
            CommandUtility.generateHeader(importsFilePath: options.importsFilePath),
            result.description
        ].joined(separator: "\n")
        try target.write(output)
    }
}
