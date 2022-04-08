import Files
import Foundation

final class CommandUtility {
    static func validatedFiles(input: String, output: String) throws -> (source: File, target: File) {
        guard FileManager.default.fileExists(atPath: input) else {
            throw Error.inputFileNotExists(input)
        }
        
        guard FileManager.default.fileExists(atPath: output) else {
            throw Error.outputFileNotExists(output)
        }
        
        guard input != output else {
            throw Error.filesAreEqual(input, output)
        }

        guard let source = try? File(path: input), let target = try? File(path: output) else {
            throw Error.couldNotOpen(input, output)
        }
        
        guard source.extension == FileExtensions.swiftExtension.extName else {
            throw Error.fileShouldHaveExtension(source.path, .swiftExtension)
        }
        
        guard target.extension == FileExtensions.swiftExtension.extName else {
            throw Error.fileShouldHaveExtension(target.path, .swiftExtension)
        }
        
        return (source: source, target: target)
    }
    
    static func generateHeader(importsFilePath: String?) -> String {
        let headerComments = """
// DO NOT EDIT
//
// Generated automatically by the AnytypeSwiftCodegen.
//
// For more info see:
// https://github.com/anytypeio/anytype-swift-codegen
"""
        
        guard let importsFilePath = importsFilePath,
                let imports = try? File(path: importsFilePath).readAsString() else {
            return headerComments
        }
        
        return [headerComments, imports].joined(separator: "\n\n")
    }
}
