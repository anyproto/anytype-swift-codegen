//
//  GenerateCommand.swift
//  
//
//  Created by Dmitry Lobanov on 25.01.2020.
//

import Foundation
import Curry
import Commandant
import Files
import SwiftSyntax
import AnytypeSwiftCodegen

struct GenerateCommand: CommandProtocol
{
    
    enum Error: Swift.Error {
        static let swiftExtension = "swift"
        case inputFileNotExists(String)
        case outputFileNotExists(String)
        case filesAreEqual(String, String)
        case filesAreCorrupted
        case fileShouldHaveSwiftExtension(String)
        case transformDoesntExist(String)
    }

    let verb = "generate"
    let function = "Apply source transform and output it to different file."

    func run(_ options: Options) throws {
        
        guard !options.list else {
            Transform.documentation().forEach{ print($0) }
            return
        }
        
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
        guard source.extension == Error.swiftExtension else {
            throw Error.fileShouldHaveSwiftExtension(source.path)
        }
        
        guard target.extension == Error.swiftExtension else {
            throw Error.fileShouldHaveSwiftExtension(target.path)
        }
        
        guard let transform = Transform.create(options.transform) else {
            throw Error.transformDoesntExist(options.transform)
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

extension GenerateCommand {
    struct Options: OptionsProtocol {
        fileprivate let filePath: String
        fileprivate let debug: Bool
        fileprivate let outputFilePath: String
        fileprivate let transform: String
        fileprivate let list: Bool
        fileprivate let templateFilePath: String
        fileprivate let commentsHeaderFilePath: String
        fileprivate let importsFilePath: String
        
        fileprivate static let defaultStringValue: String = ""
        
        public static func evaluate(_ m: CommandMode) -> Result<Self, CommandantError<Swift.Error>> {
            return curry(Self.init)
                <*> m <| Option(key: "filePath", defaultValue: defaultStringValue, usage: "The path to the file in 'generate' action.")
                <*> m <| Switch(flag: "d", key: "debug", usage: "DEBUG")
                <*> m <| Option(key: "outputFilePath", defaultValue: defaultStringValue, usage: "Use with flag --filePath. It will output to this file")
                <*> m <| Option(key: "transform", defaultValue: "", usage: "Transform with name or shortcut.")
                <*> m <| Switch(flag: "l", key: "list", usage: "List available transforms")
                <*> m <| Option(key: "templateFilePath", defaultValue: defaultStringValue, usage: "Template file that should be used in some transforms")
                <*> m <| Option(key: "commentsHeaderFilePath", defaultValue: defaultStringValue, usage: "Comments header file that will be included at top")
                <*> m <| Option(key: "importsFilePath", defaultValue: defaultStringValue, usage: "Import file that will be included at top after comments if presented")
        }
    }
}

extension GenerateCommand {
    enum Transform: String, CaseIterable {
        case errorAdoption, requestAndResponse, memberwiseInitializer
        func transform(options: Options) -> (SourceFileSyntax) -> Syntax {
            switch self {
            case .errorAdoption: return ErrorProtocolAdoptionGenerator().generate
            case .requestAndResponse: return RequestResponseExtensionGenerator().with(templatePaths: [options.templateFilePath]).generate
            case .memberwiseInitializer: return MemberwiseConvenientInitializerGenerator().generate
            }
        }
        func shortcut() -> String {
            switch self {
            case .errorAdoption: return "e"
            case .requestAndResponse: return "rr"
            case .memberwiseInitializer: return "mwi"
            }
        }
        func documentation() -> String {
            switch self {
            case .errorAdoption: return "Adopt error protocol to .Error types."
            case .requestAndResponse: return "Add Invocation and Service to Scope IF Scope.Request and Scope.Response types exist."
            case .memberwiseInitializer: return "Add Memberwise initializers in extension."
            }
        }
        static func create(_ shortcutOrName: String) -> Self? {
            return Self.init(rawValue: shortcutOrName) ?? .create(shortcut: shortcutOrName)
        }
        static func create(shortcut: String) -> Self? {
            allCases.first(where: {$0.shortcut() == shortcut})
        }
        static func list() -> [(String, String, String)] {
            allCases.compactMap {($0.rawValue, $0.shortcut() ,$0.documentation())}
        }
        static func documentation() -> [String] {
            list().map{"flag: \($0.1) -> name: \($0.0) \n \t\t\t \($0.2)\n"}
        }
    }
}
