import Foundation
import Curry
import Commandant
import Files
import SwiftSyntax
import AnytypeSwiftCodegen

struct GenerateCommand: CommandProtocol
{
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
            try self.processTransform(source: source, target: target, options: options)
        }
        
    }
    
    private func processTransform(source: File, target: File, options: Options) throws {
        guard source.extension == FileExtensions.swiftExtension.extName else {
            throw Error.fileShouldHaveExtension(source.path, .swiftExtension)
        }
        
        guard target.extension == FileExtensions.swiftExtension.extName else {
            throw Error.fileShouldHaveExtension(target.path, .swiftExtension)
        }
        
        guard let transform = Transform.create(options.transform) else {
            throw Error.transformDoesntExist(options.transform)
        }
         
        if [.requestAndResponse, .serviceWithRequestAndResponse].contains(transform) {
            guard let serviceFile = try? File(path: options.serviceFilePath) else {
                throw Error.serviceFileNotExists(options.serviceFilePath)
            }
            guard serviceFile.extension == FileExtensions.protobufExtension.extName else {
                throw Error.fileShouldHaveExtension(serviceFile.path, .protobufExtension)
            }
        }
        
        let t1 = DispatchTime.now()
        
        let sourceFile = try SyntaxParser.parse(URL(fileURLWithPath: source.path))
        
        let t2 = DispatchTime.now()
        
        let result = transform.transform(options: options)(sourceFile)

        let t3 = DispatchTime.now()
        
        print("Processing source file -> \(source.path) ")
        print("Output to file -> \(target.path)")
        if options.debug {
            print("=============== time ===============")
            print("total time:", t3 - t1)
            print("  SyntaxParser.parse time:  ", t2 - t1)
            print("  rewriter.rewrite time:", t3 - t2)
            print("=============== result ===============")
            print()
        }
        else {
            let optionalHeader = [options.commentsHeaderFilePath, options.importsFilePath].compactMap{try? File(path: $0).readAsString()}.joined(separator: "\n\n")
            let output = [optionalHeader, result.description].joined(separator: "\n")
            try target.write(output)
        }
    }
}
