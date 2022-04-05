import SwiftSyntax
import AnytypeSwiftCodegen

extension GenerateCommand {
    enum Transform: String, CaseIterable {
        case errorAdoption
        case requestAndResponse
        case memberwiseInitializer
        case serviceWithRequestAndResponse
        
        func transform(options: Options) -> (SourceFileSyntax) -> Syntax {
            switch self {
            case .errorAdoption:
                return ErrorProtocolAdoptionGenerator()
                    .generate
            case .requestAndResponse:
                return RequestResponseExtensionGenerator()
                    .with(templatePaths: [options.templateFilePath])
                    .with(serviceFilePath: options.serviceFilePath)
                    .generate
            case .memberwiseInitializer:
                return MemberwiseConvenientInitializerGenerator()
                    .generate
            case .serviceWithRequestAndResponse:
                return ServiceWithRequestAndResponseGenerator()
                    .with(templatePaths: [options.templateFilePath])
                    .with(serviceFilePath: options.serviceFilePath)
                    .generate
            }
        }
        
        var shortcut: String {
            switch self {
            case .errorAdoption: return "e"
            case .requestAndResponse: return "rr"
            case .memberwiseInitializer: return "mwi"
            case .serviceWithRequestAndResponse: return "swrr"
            }
        }
        
        static func create(_ shortcutOrName: String) -> Self? {
            Self.init(rawValue: shortcutOrName) ?? .create(shortcut: shortcutOrName)
        }
        
        static func create(shortcut: String) -> Self? {
            allCases.first(where: {$0.shortcut == shortcut})
        }
    }
}
