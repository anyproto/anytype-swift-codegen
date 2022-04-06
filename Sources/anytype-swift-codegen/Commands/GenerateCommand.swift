import Foundation
import Curry
import Commandant
import Files
import SwiftSyntax
import AnytypeSwiftCodegen

struct GenerateCommand: CommandProtocol {
    let verb = "generate"
    let function = "Apply source transform and output it to different file."

    func run(_ options: Options) throws {        
        guard FileManager.default.fileExists(atPath: options.filePath) else {
            throw Error.inputFileNotExists(options.filePath)
        }
        
        guard FileManager.default.fileExists(atPath: options.outputFilePath) else {
            throw Error.outputFileNotExists(options.outputFilePath)
        }
        
        guard options.filePath != options.outputFilePath else {
            throw Error.filesAreEqual(options.filePath, options.outputFilePath)
        }

        if let source = try? File(path: options.filePath), let target = try? File(path: options.outputFilePath) {
            try processTransform(source: source, target: target, options: options)
        }
        
    }
    
    private func processTransform(source: File, target: File, options: Options) throws {
        guard source.extension == FileExtensions.swiftExtension.extName else {
            throw Error.fileShouldHaveExtension(source.path, .swiftExtension)
        }
        
        guard target.extension == FileExtensions.swiftExtension.extName else {
            throw Error.fileShouldHaveExtension(target.path, .swiftExtension)
        }
        
        guard let transform = Transform(rawValue: options.transform) else {
            throw Error.transformDoesntExist(options.transform)
        }
         
        if .serviceWithRequestAndResponse == transform {
            guard let serviceFile = try? File(path: options.serviceFilePath) else {
                throw Error.serviceFileNotExists(options.serviceFilePath)
            }
            guard serviceFile.extension == FileExtensions.protobufExtension.extName else {
                throw Error.fileShouldHaveExtension(serviceFile.path, .protobufExtension)
            }
        }
        
        let sourceFile = try SyntaxParser.parse(URL(fileURLWithPath: source.path))
        let result = transform.transform(options: options, source: sourceFile)
        
        print("Processing source file -> \(source.path) ")
        print("Output to file -> \(target.path)")
        
        
        let output = [generateHeader(options: options), result.description].joined(separator: "\n")
        try target.write(output)
    }
    
    private func generateHeader(options: Options) -> String {
        let headerComments = """
// DO NOT EDIT
//
// Generated automatically by the AnytypeSwiftCodegen.
//
// For more info see:
// https://github.com/anytypeio/anytype-swift-codegen
"""
        
        guard let imports = try? File(path: options.importsFilePath).readAsString() else {
            return headerComments
        }
        
        return [headerComments, imports].joined(separator: "\n\n")
    }
}
