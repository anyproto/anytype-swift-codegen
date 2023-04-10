import Foundation

struct Service: Equatable {
    let name: String
    let rpc: [Rpc]
}

struct Rpc: Equatable {
    let name: String
    let request: String
    let response: String
}
