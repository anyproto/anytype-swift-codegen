import Foundation
import Curry
import Commandant
import Files
import SwiftSyntax
import SwiftSyntaxParser
import AnytypeSwiftCodegen

extension GenerateServiceCommand {
    struct Options: OptionsProtocol {
        let filePath: String
        let outputFilePath: String
        let templateFilePath: String
        let serviceFilePath: String
        
        static let defaultStringValue: String = ""
        
        public static func evaluate(_ m: CommandMode) -> Result<Self, CommandantError<Swift.Error>> {
            curry(Self.init)
                <*> m <| Option(key: "filePath", defaultValue: defaultStringValue, usage: "The path to the file in 'generate' action.")
                <*> m <| Option(key: "outputFilePath", defaultValue: defaultStringValue, usage: "Use with flag --filePath. It will output to this file")
                <*> m <| Option(key: "templateFilePath", defaultValue: defaultStringValue, usage: "Stencill template path")
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
        
        let templateFile = try File(path: options.templateFilePath)
        let template = try String(contentsOfFile: templateFile.path)
        
        let sourceFile = try SyntaxParser.parse(URL(fileURLWithPath: source.path))
        let result = try ServiceGenerator(
            scope: .public,
            template: template,
            serviceFilePath: options.serviceFilePath
        )
        .generate(sourceFile)
        
        try target.write(result)
    }
}
