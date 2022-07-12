//import Foundation
//import AppleSwiftFormat
//import AppleSwiftFormatConfiguration
//
//public class CodeFormatter {
//    
//    private let configuration: Configuration
//    
//    public init(configuration: Configuration? = nil) {
//        self.configuration = configuration ?? .default()
//    }
//    
//    public func format(source: String) throws -> String {
//        let formatter = SwiftFormatter(configuration: configuration)
//        var outout = StringOutput()
//        try formatter.format(source: source, assumingFileURL: nil, to: &outout)
//        return outout.result
//    }
//}
//
//private extension Configuration {
//    static func `default`() -> Configuration {
//        var configuration = Configuration()
//        configuration.indentation = .spaces(4)
//        configuration.lineLength = 500
//        return configuration
//    }
//}
