//
//  NestedTypesScanner.swift
//  
//
//  Created by Dmitry Lobanov on 23.01.2020.
//

import SwiftSyntax

class NestedTypesScanner: SyntaxRewriter {
    enum DeclarationType: String, CustomStringConvertible {
        var description: String { return self.rawValue }
        
        case unknown
        case enumeration
        case structure
    }
    
    struct Options {
        var scanEntries: [DeclarationType] = [.unknown]
    }
    
    struct DeclarationNotation: CustomStringConvertible {
        var description: String {
            output(0)
        }
        func output(_ level: Int) -> String {
//            "\(name)"
            let leading = String(repeating: "\t", count: level)
            let trailing = String(repeating: "\t", count: level)
            
            return leading + "\(identifier)->\n" + declarations.compactMap{$0.output(level + 1)}.joined(separator: "\n") + trailing
        }
        var declaration: DeclarationType = .unknown
        var syntax: DeclSyntax = SyntaxFactory.makeBlankUnknownDecl()
        var declarations: [DeclarationNotation] = []
        var identifier: String {
            switch self.syntax {
            case let value as StructDeclSyntax:
                return value.identifier.description.trimmingCharacters(in: .whitespacesAndNewlines)
            case let value as EnumDeclSyntax:
                return value.identifier.description.trimmingCharacters(in: .whitespacesAndNewlines)
            default: return ""
            }
        }
        var fullIdentifier: String {
            switch self.syntax {
            case let value as StructDeclSyntax:
                return value.fullIdentifier.description.trimmingCharacters(in: .whitespacesAndNewlines)
            case let value as EnumDeclSyntax:
                return value.fullIdentifier.description.trimmingCharacters(in: .whitespacesAndNewlines)
            default: return ""
            }
        }
    }
    var options: Options = .init()
    init(options: Options) {
        self.options = options
    }
    override init() {}
    func scanEntry(_ declaration: DeclSyntax) -> DeclarationNotation? {
        switch declaration {
        case let value as StructDeclSyntax:
            return .init(declaration: .structure, syntax: value, declarations: [])
        case let value as EnumDeclSyntax:
            return .init(declaration: .enumeration, syntax: value, declarations: [])
        default: return nil
        }
    }
    
    func scanRecursively(_ declaration: DeclSyntax) -> DeclarationNotation? {
        switch declaration {
        case let value as StructDeclSyntax:
            return .init(declaration: .structure, syntax: value, declarations: value.members.members.enumerated().compactMap{$0.element.decl}.compactMap(self.scanRecursively))
        case let value as EnumDeclSyntax:
            return .init(declaration: .enumeration, syntax: value, declarations: value.members.members.enumerated().compactMap{$0.element.decl}.compactMap(self.scanRecursively))
        default: return nil
        }
    }
    
    func scan(_ node: StructDeclSyntax) -> DeclarationNotation? {
        self.scanRecursively(node)
    }
    func scan(_ node: DeclSyntax) -> DeclarationNotation? {
        self.scanRecursively(node)
    }
    
    func scan(_ node: SourceFileSyntax) -> [DeclarationNotation] {
        node.statements.compactMap{$0.item as? DeclSyntax}.compactMap(self.scan)
    }
    
    // MARK: Visits
    override func visit(_ node: SourceFileSyntax) -> Syntax {
        _ = self.scan(node)
        return node
    }
}
