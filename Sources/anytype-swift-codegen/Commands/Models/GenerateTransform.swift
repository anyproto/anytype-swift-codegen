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
                return ErrorProtocolAdoptionGenerator()
                    .generate(source)
            case .memberwiseInitializer:
                return MemberwiseConvenientInitializerGenerator()
                    .generate(source)
            case .serviceWithRequestAndResponse:
                return ServiceGenerator(templatePaths: [options.templateFilePath])
                    .with(serviceFilePath: options.serviceFilePath)
                    .generate(source)
            }
        }
    }
}
