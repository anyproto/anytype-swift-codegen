import Foundation
import ArgumentParser
import AnytypeSwiftCodegen
import Yams

struct ServiceYaml: Codable {
    let source: String
    let template: String
    let output: String
}

struct ServiceGeneratorCommand: ParsableCommand {

    public static let configuration = CommandConfiguration(abstract: "Generate code for protobuf services")

    @Option(name: .long, help: "Yaml config file")
    private var yamlPath: String
    
    func run() throws {
        
        let path = URL(string: yamlPath)!
        let data = try Data(contentsOf: path)
        let decoder = YAMLDecoder()
        let config = try decoder.decode(ServiceYaml.self, from: data)
        
        let serviceProtobuf = try String(contentsOfFile: config.source)
        let template = try String(contentsOfFile: config.template)

        let result = try ServiceGenerator(
            template: template,
            serviceProtobuf: serviceProtobuf
        )
        .generate()

        try result.write(toFile: config.output, atomically: true, encoding: .utf16)
    }
}

