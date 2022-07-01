//
//  TestRunner.swift
//  
//
//  Created by Dmitry Lobanov on 29.01.2020.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxParser
import XCTest
import SnapshotTesting
@testable import AnytypeSwiftCodegen

// MARK: - Test Runners

func runTest<T>(
    source: String,
    expected: String,
    using generator: T,
    file: StaticString = #file,
    function: String = #function,
    line: UInt = #line
    ) throws
    where T: Generator
{
    /// Tweak special characters.
    func tweak(_ string: String) -> String
    {
        return string.replacingOccurrences(of: "␣", with: " ")
    }

    let syntax = try parseString(tweak(source))

    let result = try CodeFormatter().format(source: generator.generate(syntax).description)

    let diffString = Diffing<String>.lines.diff(tweak(expected), result)?.0

    print(border("source"))
    print(source)
    print(border("result"))
    print(result)
    print(border("expected"))
    print(expected)
    print(border("diff"))
    print(diffString ?? "(no diff)")
    print(border("done"))
    print()

    if let diffString = diffString {
        XCTFail(diffString, file: file, line: line)
    }
}

// MARK: - Parse string or file
func parseString(_ source: String) throws -> SourceFileSyntax
{
    let sourceURL = try createFile(source)

    let syntax = try SyntaxParser.parse(sourceURL)

    return syntax
}

func createFile(_ source: String) throws -> URL
{
    let sourceURL = URL(fileURLWithPath: NSTemporaryDirectory())
        .appendingPathComponent(UUID().uuidString)
        .appendingPathExtension("swift")

    try source.write(to: sourceURL, atomically: true, encoding: .utf8)

    return sourceURL
}

// MARK: - Private

extension Snapshotting where Value == SourceFileSyntax, Format == String
{
    /// Export snapshot as `.swift` file.
    fileprivate static let swiftLines: Snapshotting =
        Snapshotting<String, String>(pathExtension: "swift", diffing: .lines)
            .pullback { $0.description }
}

private func border(_ string: String) -> String
{
    let line = String(repeating: "=", count: max(3, 20 - string.count / 2))
    return "\(line) \(string) \(line)"
}
