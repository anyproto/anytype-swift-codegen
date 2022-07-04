import Foundation

struct StringOutput: TextOutputStream {
    var result: String = ""
    
    mutating func write(_ string: String) {
        result.append(string)
    }
}
