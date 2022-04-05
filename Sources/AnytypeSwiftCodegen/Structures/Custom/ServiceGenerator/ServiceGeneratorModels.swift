struct ServiceData {
    let this: DeclarationNotation
    let request: DeclarationNotation
    let response: DeclarationNotation
}


extension ServiceGenerator {
    struct Options {
        let scope: AccessLevelScope
        let templatePaths: [String]
    }
}
