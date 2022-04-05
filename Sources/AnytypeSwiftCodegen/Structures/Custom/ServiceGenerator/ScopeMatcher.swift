class ScopeMatcher {
    private let endpoints: [Endpoint]
    private let threshold: Int
    
    init(threshold: Int, endpoints: [Endpoint]) {
        self.threshold = threshold
        self.endpoints = endpoints
    }
    
    func bestRpc(for scope: ServiceGenerator.Scope) -> Endpoint? {
        return endpoints.compactMap { (value) in
            (value, self.sufficiesDifference(lhs: scope.request.fullIdentifier, rhs: value.request))
        }
        .compactMap{($0.0, max($0.1.0, $0.1.1))}
        .sorted { (left, right) -> Bool in
            left.1 < right.1
        }
        .first(where: {$0.1 <= self.threshold})?.0
    }
    
    // MARK: - Private
    
    // Given two strings:
    // A = "abcdef"
    // B = "lkmabcdef"
    // This function return result
    // C = (0, length(lkm))
    private func sufficiesDifference(lhs: String, rhs: String) -> (Int, Int) {
        let left = lhs.reversed()
        let right = rhs.reversed()
        var leftStartIndex = left.startIndex
        var rightStartIndex = right.startIndex
        let leftEndIndex = left.endIndex
        let rightEndIndex = right.endIndex
        
        while leftStartIndex != leftEndIndex, rightStartIndex != rightEndIndex, left[leftStartIndex] == right[rightStartIndex] {
            leftStartIndex = left.index(after: leftStartIndex)
            rightStartIndex = right.index(after: rightStartIndex)
        }
        return (
            left.distance(from: leftStartIndex, to: leftEndIndex),
            right.distance(from: rightStartIndex, to: rightEndIndex)
        )
    }
}

