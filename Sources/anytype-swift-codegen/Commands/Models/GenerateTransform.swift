import SwiftSyntax
import AnytypeSwiftCodegen

extension GenerateCommand {
    enum Transform: String, CaseIterable {
        case errorAdoption, requestAndResponse, memberwiseInitializer, serviceWithRequestAndResponse
        func transform(options: Options) -> (SourceFileSyntax) -> Syntax {
            switch self {
            case .errorAdoption: return ErrorProtocolAdoptionGenerator().generate
            case .requestAndResponse: return RequestResponseExtensionGenerator().with(templatePaths: [options.templateFilePath]).with(serviceFilePath: options.serviceFilePath).generate
            case .memberwiseInitializer: return MemberwiseConvenientInitializerGenerator().generate
            case .serviceWithRequestAndResponse: return ServiceWithRequestAndResponseGenerator().with(templatePaths: [options.templateFilePath]).with(serviceFilePath: options.serviceFilePath).generate
            }
        }
        func shortcut() -> String {
            switch self {
            case .errorAdoption: return "e"
            case .requestAndResponse: return "rr"
            case .memberwiseInitializer: return "mwi"
            case .serviceWithRequestAndResponse: return "swrr"
            }
        }
        func documentation() -> String {
            switch self {
            case .errorAdoption: return "Adopt error protocol to .Error types."
            case .requestAndResponse: return "Add Invocation and Service to Scope IF Scope.Request and Scope.Response types exist."
            case .memberwiseInitializer: return "Add Memberwise initializers in extension."
            case .serviceWithRequestAndResponse: return "Add Invocation and Service to Scope with Request converter and Request parameters IF Scope.Request and Scope.Response types exist."
            }
        }
        static func create(_ shortcutOrName: String) -> Self? {
            Self.init(rawValue: shortcutOrName) ?? .create(shortcut: shortcutOrName)
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
