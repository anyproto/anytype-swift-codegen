//
//  ServiceGeneratorTests.swift
//  
//
//  Created by Dmitry Lobanov on 27.10.2020.
//

import XCTest
@testable import AnytypeSwiftCodegen

/*
// input
struct Outer {
    struct Fruit {
        struct Apple {
            struct Request {
                var name: String = .init()
                var seedCount: Int = .init()
                struct Kind {}
            }
            struct Response {
                struct Error {
                    struct Code {}
                }
            }
        }
        struct Raspberry {
            struct Request {
                var name: String = .init()
                var seed: String = .init()
                struct Kind {}
            }
            struct Response {
                struct Error {
                    struct Code {}
                }
            }
        }
    }
}
// Outdated result.
// result
extension Fruit.Apple {
    struct Invocation {/**/}
    struct Service {
        // public function
        // template
    }
}
extension Fruit.Raspberry {
    struct Invocation {/**/}
    struct Service {
        // public function
        // template
    }
}
*/

/// TODO:
/// Fix output later.
/// Trust code not test in this case.
///
final class ServiceGeneratorTests: XCTestCase
{
    // New test.
    func test_public() throws
    {
        let source = """
            struct Outer {
                struct Fruit {
                    struct Apple {
                        struct Request {
                            var name: String = .init()
                            var seedCount: Int = .init()
                            struct Kind {}
                        }
                        struct Response {
                            struct Error {
                                struct Code {}
                            }
                        }
                    }
                    struct Raspberry {
                        struct Request {
                            var name: String = .init()
                            var seed: String = .init()
                            struct Kind {}
                        }
                        struct Response {
                            struct Error {
                                struct Code {}
                            }
                        }
                    }
                }
            }
            """
        
        let expected = """
            
            public extension Outer.Fruit.Apple {
            private struct Invocation {
            static func invoke(_ data: Data?) -> Data? { Lib.ServiceFruitApple(data) }
            }
            
            public enum Service {
            public typealias RequestParameters = Request
            private static func request(_ parameters: RequestParameters) -> Request {
            parameters
            }
            public static func invoke(name: String, seedCount: Int, queue: DispatchQueue? = nil) -> Future<Response, Error> {
            self.invoke(parameters: .init(name: name, seedCount: seedCount), on: queue)
            }
            public static func invoke(name: String, seedCount: Int) -> Result<Response, Error> {
            self.result(.init(name: name, seedCount: seedCount))
            }
            
            }
            }
            
            public extension Outer.Fruit.Raspberry {
            private struct Invocation {
            static func invoke(_ data: Data?) -> Data? { Lib.ServiceFruitRaspberry(data) }
            }
            
            public enum Service {
            public typealias RequestParameters = Request
            private static func request(_ parameters: RequestParameters) -> Request {
            parameters
            }
            public static func invoke(name: String, seed: String, queue: DispatchQueue? = nil) -> Future<Response, Error> {
            self.invoke(parameters: .init(name: name, seed: seed), on: queue)
            }
            public static func invoke(name: String, seed: String) -> Result<Response, Error> {
            self.result(.init(name: name, seed: seed))
            }

            }
            }

            """
        
        try runTest(
            source: source,
            expected: expected,
            using: ServiceGenerator().with(scopeMatcherAsDebug: true)
        )
    }

    /// Do not remove, maybe you need it later.
    func old_test_internal() throws
    {
        let source = """
            struct Outer {
                struct Fruit {
                    struct Apple {
                        struct Request {
                            var name: String = .init()
                            var seedCount: Int = .init()
                            struct Kind {}
                        }
                        struct Response {
                            struct Error {
                                struct Code {}
                            }
                        }
                    }
                    struct Raspberry {
                        struct Request {
                            var name: String = .init()
                            var seed: String = .init()
                            struct Kind {}
                        }
                        struct Response {
                            struct Error {
                                struct Code {}
                            }
                        }
                    }
                }
            }
            """
        
        let expected = """
            
            internal extension Outer.Fruit.Apple {
            private struct Invocation {
            static func invoke(_ data: Data?) -> Data? { Lib.LibFruitApple(data) }
            }
            
            enum Service {
            public typealias RequestParameters = (name: String, seedCount: Int)
            private static func request(_ parameters: RequestParameters) -> Request {
            .init(name: parameters.name, seedCount: parameters.seedCount)
            }
            
            }
            }
            
            internal extension Outer.Fruit.Raspberry {
            private struct Invocation {
            static func invoke(_ data: Data?) -> Data? { Lib.LibFruitRaspberry(data) }
            }
            
            internal enum Service {
            public typealias RequestParameters = (name: String, seed: String)
            private static func request(_ parameters: RequestParameters) -> Request {
            .init(name: parameters.name, seed: parameters.seed)
            }
            
            }
            }

            """
        
        try runTest(
            source: source,
            expected: expected,
            using: ServiceGenerator(scope: .internal).with(scopeMatcherAsDebug: true)
        )
    }
}
