import ArgumentParser

@main
struct Codegen: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Anytype codegen",
        subcommands: [ServiceGeneratorCommand.self])

    init() { }
}
