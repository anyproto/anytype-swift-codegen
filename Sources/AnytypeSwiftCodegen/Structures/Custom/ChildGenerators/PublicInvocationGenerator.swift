import Foundation

//class PublicInvocationGenerator {
//    
//    private enum Configuration {
//        static let methodName = "invocation"
//        static let returnType = "ProtobufMessages.Invocation<Response>"
//    }
//    
//    func generate(vars: [Variable]) -> Syntax {
//        
//        
//        
//        let args = vars.map { Argument.init(from: $0) }
//        
//        FunctionDeclGenerator.generate(
//            accessLevel: .publicLevel,
//            staticFlag: true,
//            name: Configuration.methodName,
//            args: args,
//            returnType: Configuration.returnType,
//            body: T##CodeBlockSyntax
//        )
//    }
//}
