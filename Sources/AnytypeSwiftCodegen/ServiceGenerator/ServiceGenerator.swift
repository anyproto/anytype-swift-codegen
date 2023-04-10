import Foundation

enum ServiceGeneratorError: Error {
    case serviceMatchError
}

public class ServiceGenerator {
    
    private let parser = ServiceParser()
    private let stencilGenerator = StencillServiceGenerator()
        
    private let template: String
    private let serviceProtobuf: String
    
    public init(template: String, serviceProtobuf: String) {
        self.template = template
        self.serviceProtobuf = serviceProtobuf
    }
    
    public func generate() throws -> String {
        let serviceData = try parser.parse(serviceProto: serviceProtobuf)
        return try stencilGenerator.generate(objects: [serviceData], template: template)
    }
}
