//
//  StoredPropertiesExtractor.swift
//  
//
//  Created by Dmitry Lobanov on 23.01.2020.
//

import Foundation
import SwiftSyntax

class StoredPropertiesExtractor: SyntaxRewriter {
    struct Options {
        var filterNames: [String] = []
        var allowInconsistentSetter: Bool = false
    }
    class VariableFilter {
        struct Variable {
            static let zero = Variable()
            func isEmpty() -> Bool { nameSyntax == nil }
            enum Accessor: CustomStringConvertible {
                case none
                case getter
                case setter
                func computed() -> Bool {
                    self == .getter
                }
                var description: String {
                    switch self {
                    case .none: return "none"
                    case .getter: return "getter"
                    case .setter: return "setter"
                    }
                }
            }
            var name: String { nameSyntax?.description ?? "" }
            var nameSyntax: PatternSyntax?
            var typeAnnotation: String { typeAnnotationSyntax?.description ?? "" }
            var typeAnnotationSyntax: TypeAnnotationSyntax?
            var accessor: Accessor = .none
            func computed() -> Bool { accessor.computed() }
            func unknownType() -> Bool { typeAnnotationSyntax == nil }
            
        }
        
        private let setterVariableGroupName: String = "setterVariable"
        private let setterVariablePattern: NSRegularExpression = (try? NSRegularExpression(pattern: "(?<setterVariable>[^=]+)\\s*=")) ?? NSRegularExpression()
        
        private func setters(setter: AccessorDeclSyntax?, variable: Variable) -> Variable.Accessor {
            guard let body = setter?.body else { return .getter }
            if #available(OSX 10.13, *) {
                let variableName = variable.name.trimmingCharacters(in: .whitespacesAndNewlines)
                let bodyDescription = body.description
                let ranges = self.setterVariablePattern.matches(in: bodyDescription, options: [], range: NSRange.init(location: 0, length: bodyDescription.count)).filter{$0.numberOfRanges > 0}.map {$0.range(withName: self.setterVariableGroupName)}
                let containsVariableAtLeft = [ranges.first].compactMap{$0}.map{(bodyDescription as NSString).substring(with: $0).contains(variableName)}.allSatisfy({$0})
                
                return containsVariableAtLeft ? .setter : .getter
            } else {
                // Fallback on earlier versions
            }
            return .getter
        }
        private func modifier(modifier: AccessorBlockSyntax?, variable: Variable) -> Variable.Accessor {
            guard let modifier = modifier else { return .none }
            let setters = modifier.accessors.enumerated().map {$0.element}.filter { .contextualKeyword("set") == $0.accessorKind.tokenKind }.first
            return self.setters(setter: setters, variable: variable)
        }
        private func accessor(accessor: Syntax?, variable: Variable) -> Variable.Accessor {
            guard let accessor = accessor else { return .none }
            
            if CodeBlockItemSyntax(accessor) != nil {
                return .getter
            }
                
            else if let value = AccessorBlockSyntax(accessor) {
                return self.modifier(modifier: value, variable: variable)
            }
            
            return .none
        }
        func variable(_ variable: VariableDeclSyntax) -> Variable {
            for binding in variable.bindings {
                var variable = Variable(nameSyntax: binding.pattern, typeAnnotationSyntax: binding.typeAnnotation)
                variable.accessor = self.accessor(accessor: binding.accessor, variable: variable)
                return variable
            }
            return .zero
        }
    }
    
    // MARK: Variables
    var options: Options = .init()
    // StructName -> (Struct, [MemberItem])
    var extractedFields: [String: (TypeSyntax, [VariableFilter.Variable])] = [:]
    
    var filter = VariableFilter()
    
    // MARK: Extraction
    func extract(_ node: StructDeclSyntax) -> [String: (TypeSyntax, [VariableFilter.Variable])] {
        let syntax = node
        let variables = syntax.members.members.enumerated().compactMap{ $0.element.decl.as(VariableDeclSyntax.self) }.map(self.filter.variable).filter{
            !($0.isEmpty() || $0.computed() || $0.unknownType())
        }
                
        let identifier = syntax.fullIdentifier.description.trimmingCharacters(in: .whitespacesAndNewlines)
        self.extractedFields[identifier] = (syntax.fullIdentifier, variables)
        
        return self.extractedFields
    }
    
    // MARK: Visits
    override func visit(_ node: StructDeclSyntax) -> DeclSyntax {
        _ = self.extract(node)
        return super.visit(node)
    }
}
