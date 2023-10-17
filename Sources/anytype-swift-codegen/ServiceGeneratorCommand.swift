import Foundation
import ArgumentParser
import AnytypeSwiftCodegen
import Yams

struct ServiceYaml: Codable {
    let source: String
    let template: String
    let output: String
}

@main
struct ServiceGeneratorCommand: ParsableCommand {

    public static let configuration = CommandConfiguration(abstract: "Generate code for protobuf services")

    @Option(name: .long, help: "Yaml config file")
    private var yamlPath: String
    
    @Option(name: .long, help: "Project directory")
    private var projectDir: String
    
    @Option(name: .long, help: "Output directory")
    private var outputDir: String
    
    func run() throws {
        
        let path = URL(fileURLWithPath: yamlPath)
        let data = try Data(contentsOf: path)
        let decoder = YAMLDecoder()
        let config = try decoder.decode(ServiceYaml.self, from: data)
        
        let sourcePath = (projectDir as NSString).appendingPathComponent(config.source)
        let templatePath = (projectDir as NSString).appendingPathComponent(config.template)
        let outputPath = (outputDir as NSString).appendingPathComponent(config.output)
        
        let serviceProtobuf = try String(contentsOfFile: sourcePath)
        let template = try String(contentsOfFile: templatePath)

        let result = try ServiceGenerator(
            template: template,
            serviceProtobuf: serviceProtobuf
        )
        .generate()

        try result.write(toFile: outputPath, atomically: true, encoding: .utf8)
    }
}

