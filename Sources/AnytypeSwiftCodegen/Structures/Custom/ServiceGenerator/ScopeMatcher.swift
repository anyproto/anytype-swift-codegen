class ScopeMatcher {
    private var service: RpcServiceFileParser.ServiceParser.Service?
    private var threshold: Int = 0
    func with(_ threshold: Int) -> Self {
        self.threshold = threshold
        return self
    }
    func with(_ filePath: String) -> Self {
        self.service = RpcServiceFileParser.init(options: .init(filePath: filePath)).parse(filePath)
        return self
    }
    init() {}
    
    // Given two strings:
    // A = "abcdef"
    // B = "lkmabcdef"
    // This function return result
    // C = (0, length(lkm))
    func sufficiesDifference(lhs: String, rhs: String) -> (Int, Int) {
        let left = lhs.reversed()
        let right = rhs.reversed()
        var leftStartIndex = left.startIndex
        var rightStartIndex = right.startIndex
        let leftEndIndex = left.endIndex
        let rightEndIndex = right.endIndex
        
        while leftStartIndex != leftEndIndex, rightStartIndex != rightEndIndex, left[leftStartIndex] == right[rightStartIndex] {
//                print("\(left[leftStartIndex]) == \(right[rightStartIndex])")
            leftStartIndex = left.index(after: leftStartIndex)
            rightStartIndex = right.index(after: rightStartIndex)
        }
        return (
            left.distance(from: leftStartIndex, to: leftEndIndex),
            right.distance(from: rightStartIndex, to: rightEndIndex)
        )
    }
    
    func bestRpc(for scope: ServiceGenerator.Scope) -> RpcServiceFileParser.ServiceParser.Service.Endpoint? {
        guard let service = service else { return nil }
        return service.endpoints.compactMap { (value) in
            (value, self.sufficiesDifference(lhs: scope.request.fullIdentifier, rhs: value.request))
        }.compactMap{($0.0, max($0.1.0, $0.1.1))}.sorted { (left, right) -> Bool in
            left.1 < right.1
            }.first(where: {$0.1 <= self.threshold})?.0
    }
    
    static var debug: ScopeMatcher = Debug()
    
    class Debug: ScopeMatcher {
        var endpoint: RpcServiceFileParser.ServiceParser.Service.Endpoint = .init(name: "", request: "", response: "")
        override func bestRpc(for scope: ServiceGenerator.Scope) -> RpcServiceFileParser.ServiceParser.Service.Endpoint? {
            endpoint
        }
    }
}

