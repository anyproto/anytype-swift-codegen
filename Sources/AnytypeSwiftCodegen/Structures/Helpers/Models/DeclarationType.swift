enum DeclarationType: String, CustomStringConvertible {
    case unknown
    case enumeration
    case structure
    
    var description: String { return self.rawValue }
}
