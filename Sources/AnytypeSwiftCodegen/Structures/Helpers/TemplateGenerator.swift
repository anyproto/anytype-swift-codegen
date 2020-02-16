//
//  TemplateGenerator.swift
//  
//
//  Created by Dmitry Lobanov on 23.01.2020.
//
import Foundation
import SwiftSyntax

class TemplateGenerator: SyntaxRewriter {
    struct Options {
        var filePath: String = ""
    }
    var options: Options = .init()
    init(options: Options) {
        self.options = options
    }
    override init() {}
    
    func generate(_ filePath: String) -> Syntax? {
        guard FileManager.default.fileExists(atPath: filePath) else { return nil }
        return try? SyntaxParser.parse(URL(fileURLWithPath: filePath))
    }
}

extension TemplateGenerator: Generator {
    func generate(_ node: SourceFileSyntax) -> Syntax {
        guard let syntax = self.generate(self.options.filePath) else {
            return SyntaxFactory.makeBlankSourceFile()
        }
        return syntax
    }
}
