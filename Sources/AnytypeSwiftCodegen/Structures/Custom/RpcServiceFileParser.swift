//
//  RpcServiceFileParser.swift
//  
//
//  Created by Dmitry Lobanov on 16.02.2020.
//

import Foundation
import SwiftSyntax

class RpcServiceFileParser: SyntaxRewriter {
    struct Options {
        var filePath: String = ""
    }
    var options: Options = .init()
    init(options: Options) {
        self.options = options
    }
    override init() {}
    
    var serviceParser: ServiceParser = .init()
    
    func parse(_ filePath: String) -> ServiceParser.Service? {
        guard FileManager.default.fileExists(atPath: filePath) else { return nil }
        return (try? String.init(contentsOfFile: filePath)).flatMap(self.serviceParser.parse)
    }
}

extension RpcServiceFileParser {
    /*
     service ClientCommands {
         rpc WalletCreate (anytype.Rpc.Wallet.Create.Request) returns (anytype.Rpc.Wallet.Create.Response);
     }
     */
    class ServiceParser {
        struct Service {
            struct Endpoint {
                var name: String
                var request: String
                var response: String
            }
            var endpoints: [Endpoint] = []
        }
        
//         read tokens and extract all rpc services endpoints.
        private let endpointFormat: NSRegularExpression = (try? NSRegularExpression(pattern: "rpc\\s+(?<name>\\w+)\\s+\\((?<request>[^\\(\\)]+)\\)\\s+returns\\s+\\((?<response>[^\\(\\)]+)\\)")) ?? NSRegularExpression()
        private let endpointName = "name"
        private let endpointRequest = "request"
        private let endpointResponse = "response"
        
        private func parse(line: String) -> Service.Endpoint? {
            if #available(OSX 10.13, *) {                
                let length = line.count
                let expectedNumbersOfRanges = 3 // count of NSRegularExpressions.
                let result = self.endpointFormat.matches(in: line, options: [], range: NSRange.init(location: 0, length: length)).filter{$0.numberOfRanges >= expectedNumbersOfRanges}.map {
                    ($0.range(withName: endpointName), $0.range(withName: endpointRequest), $0.range(withName: endpointResponse))
                }.map {
                    ((line as NSString).substring(with: $0.0), (line as NSString).substring(with: $0.1), (line as NSString).substring(with: $0.2))
                }.map(Service.Endpoint.init)
                return result.first
            }
            else {
                return nil
            }
        }
        
        func parse(_ string: String) -> Service {
            let strings = string.split(separator: "\n").map(String.init)
            let endpoints = strings.compactMap(self.parse(line:))
            return Service.init(endpoints: endpoints)
        }
    }
}
