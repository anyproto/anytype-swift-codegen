import Foundation

final class ServiceParser {
    
    private let endpointFormat = "rpc\\s*(?<name>\\w+)\\s*\\((?<request>[^\\(\\)]+)\\)\\s*returns\\s*\\((?<response>[^\\(\\)]+)\\)"
    private let serviceFormat = "service\\s*(?<name>\\w+)"
    
    func parse(serviceProto: String) throws -> Service {

        let regex = try NSRegularExpression(pattern: serviceFormat)
        let range = NSRange(location: 0, length: serviceProto.utf16.count)

        let matches = regex.matches(in: serviceProto, range: range)

        guard let match = matches.first, matches.count == 1 else {
            throw ServiceGeneratorError.serviceMatchError
        }

        let name = (serviceProto as NSString).substring(with: match.range(withName: "name"))
        let rpc = try extractRpc(serviceProto: serviceProto)

        return Service(name: name, rpc: rpc)
    }
    
    private func extractRpc(serviceProto: String) throws -> [Rpc] {

        let regex = try NSRegularExpression(pattern: endpointFormat)
        let range = NSRange(location: 0, length: serviceProto.utf16.count)

        let matches = regex.matches(in: serviceProto, range: range)

        let rpc = matches.map { match in
            let name = (serviceProto as NSString).substring(with: match.range(withName: "name"))
            let request = (serviceProto as NSString).substring(with: match.range(withName: "request"))
            let response = (serviceProto as NSString).substring(with: match.range(withName: "response"))
            return Rpc(name: name, request: request, response: response)
        }

        return rpc
    }
}
