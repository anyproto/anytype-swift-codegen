import Commandant
import Curry

extension GenerateCommand {
    struct Options: OptionsProtocol {
        let filePath: String
        let outputFilePath: String
        let transform: String
        let templateFilePath: String
        let importsFilePath: String
        let serviceFilePath: String
        
        static let defaultStringValue: String = ""
        
        public static func evaluate(_ m: CommandMode) -> Result<Self, CommandantError<Swift.Error>> {
            curry(Self.init)
                <*> m <| Option(key: "filePath", defaultValue: defaultStringValue, usage: "The path to the file in 'generate' action.")
                <*> m <| Option(key: "outputFilePath", defaultValue: defaultStringValue, usage: "Use with flag --filePath. It will output to this file")
                <*> m <| Option(key: "transform", defaultValue: "", usage: "Transform with name or shortcut.")
                <*> m <| Option(key: "templateFilePath", defaultValue: defaultStringValue, usage: "Template file that should be used in some transforms")
                <*> m <| Option(key: "importsFilePath", defaultValue: defaultStringValue, usage: "Import file that will be included at top after comments if presented")
                <*> m <| Option(key: "serviceFilePath", defaultValue: defaultStringValue, usage: "Rpc service file that contains Rpc services descriptions in .proto (protobuffers) format.")
        }
    }
}
