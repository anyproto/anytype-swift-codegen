enum FileExtensions {
    case swiftExtension
    case protobufExtension
    func extName() -> String {
        switch self {
        case .swiftExtension: return "swift"
        case .protobufExtension: return "proto"
        }
    }
}
