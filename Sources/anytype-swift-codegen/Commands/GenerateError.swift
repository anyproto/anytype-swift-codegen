enum Error: Swift.Error {
    case inputFileNotExists(String)
    case outputFileNotExists(String)
    case serviceFileNotExists(String)
    case filesAreEqual(String, String)
    case filesAreCorrupted
    case fileShouldHaveExtension(String, FileExtensions)
    case couldNotOpen(String, String)
}
