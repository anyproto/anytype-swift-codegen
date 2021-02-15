import Foundation
import Curry
import Commandant
import SwiftSyntax
import AnytypeSwiftCodegen

/// Print current version.
struct VersionCommand: CommandProtocol
{
    public typealias Options = NoOptions<Swift.Error>

    let verb = "version"
    let function = "Display the current version"

    func run(_ options: Options) throws
    {
        // TODO: Add swift version extraction from SwiftSyntax, I guess.
        // We should bind this codegen only to SwiftSyntax library.
        let version = AnytypeSwiftCodegen.ToolVersion
        print("\(version)")
    }
}
