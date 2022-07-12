import Foundation

enum Templates {
    
    static let initName = "init"
    static let errorName = "error"
    static let serviceName = "service"
//    static let functionArgumentsName = "functionArguments"
//    static let functionCallArgumentsName = "functionCallArguments"
    
    static let all: [String: String] = {
        return [
            Templates.initName: StencilInitializerGeneratorTemplate,
            Templates.errorName: StencillErrorProtocolGeneratorTemplate,
            Templates.serviceName: StencillServiceGeneratorTemplate
//            Templates.functionArgumentsName: FunctionArgumentsTemplate,
//            Templates.functionCallArgumentsName: FunctionCallArgumentsTemplate,
        ]
    }()
    
}
