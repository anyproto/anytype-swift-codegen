import Foundation
import Commandant
import SwiftSyntax

let registry: CommandRegistry<Swift.Error> = {
    let registry = CommandRegistry<Swift.Error>()
    registry.register(HelpCommand(registry: registry))
    registry.register(GenerateServiceCommand())
    registry.register(GenerateInitializersCommand())
    registry.register(GenerateErrorAdoptionCommand())
    return registry
}()

registry.main(defaultVerb: "help") { error in
    fputs("\(error)\n", stderr)
}
