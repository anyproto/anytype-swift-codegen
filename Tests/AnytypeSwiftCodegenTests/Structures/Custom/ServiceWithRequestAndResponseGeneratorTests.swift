//
//  ServiceWithRequestAndResponseGeneratorTests.swift
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

final class ServiceWithRequestAndResponseGeneratorTests: XCTestCase
{
    func test_basic() throws
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
            
            enum Service {
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
            using: ServiceWithRequestAndResponseGenerator().with(scopeMatcherAsDebug: true)
        )
    }
}
