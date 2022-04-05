import SwiftSyntax
import AnytypeSwiftCodegen

extension GenerateCommand {
    enum Transform: String, CaseIterable {
        case errorAdoption
        case memberwiseInitializer
        case serviceWithRequestAndResponse
        
        func transform(options: Options, source: SourceFileSyntax) -> Syntax {
            switch self {
            case .errorAdoption:
                return ErrorProtocolGenerator()
                    .generate(source)
            case .memberwiseInitializer:
                return InitializerGenerator()
                    .generate(source)
            case .serviceWithRequestAndResponse:
                return ServiceGenerator(
                    scope: .public,
                    templatePaths: [options.templateFilePath],
                    serviceFilePath: options.serviceFilePath
                )
                .generate(source)
            }
        }
    }
}
