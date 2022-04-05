import SwiftSyntax
import Foundation

struct Variable {
    internal init(
        nameSyntax: PatternSyntax? = nil,
        typeAnnotationSyntax: TypeAnnotationSyntax? = nil,
        accessor: Accessor = .none,
        accessLevel: TokenKind? = nil
    ) {
        self.nameSyntax = nameSyntax
        self.typeAnnotationSyntax = typeAnnotationSyntax
        self.accessor = accessor
        self.accessLevel = accessLevel ?? .internalKeyword
    }
    
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
    
    var accessLevel: TokenKind = .internalKeyword
    func inaccessibleDueToAccessLevel() -> Bool {
        switch accessLevel {
        case .privateKeyword, .fileprivateKeyword: return true
        case .internalKeyword, .publicKeyword: return false
        default: return false
        }
    }
    
    static func accessLevels() -> [TokenKind] {
        [.privateKeyword, .fileprivateKeyword, .internalKeyword, .publicKeyword]
    }
}

class VariableFilter {
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
        
        if CodeBlockSyntax(accessor) != nil {
            return .getter
        }
            
        else if let value = AccessorBlockSyntax(accessor) {
            return self.modifier(modifier: value, variable: variable)
        }
        
        return .none
    }
    
    func variable(_ variable: VariableDeclSyntax) -> Variable {
        for binding in variable.bindings {
            let accessLevel: TokenKind? = variable.modifiers?
                .compactMap({$0})
                .map(\.name)
                .map(\.tokenKind)
                .filter(Variable.accessLevels().contains)
                .first
                            
            var variable = Variable(
                nameSyntax: binding.pattern,
                typeAnnotationSyntax: binding.typeAnnotation,
                accessLevel: accessLevel
            )
            variable.accessor = accessor(accessor: binding.accessor, variable: variable)
            return variable
        }
        return .zero
    }
}
