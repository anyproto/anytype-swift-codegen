enum FileExtensions {
    case swiftExtension
    case protobufExtension
    
    var extName: String {
        switch self {
        case .swiftExtension: return "swift"
        case .protobufExtension: return "proto"
        }
    }
}
