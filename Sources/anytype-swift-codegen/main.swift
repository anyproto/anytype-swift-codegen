import Foundation
import Commandant
import SwiftSyntax

let registry: CommandRegistry<Swift.Error> = {
    let registry = CommandRegistry<Swift.Error>()
    registry.register(VersionCommand())
    registry.register(HelpCommand(registry: registry))
    registry.register(GenerateCommand())
    return registry
}()

registry.main(defaultVerb: "help") { error in
    fputs("\(error)\n", stderr)
}
