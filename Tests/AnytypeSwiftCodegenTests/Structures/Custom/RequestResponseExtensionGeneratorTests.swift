//
//  RequestResponseExtensionGeneratorTests.swift
//  
//
//  Created by Dmitry Lobanov on 24.01.2020.
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

final class RequestResponseExtensionGeneratorTests: XCTestCase
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
            static func invoke(_ data: Data?) -> Data? { Lib.ServiceFruitApple(data) }
            }
            
            enum Service {
            public static func invoke(name: String, seedCount: Int) -> Future<Response, Error> {
            .init{promise in promise(self.result(.init(name: name, seedCount: seedCount)))}
            }
            
            }
            }
            
            internal extension Outer.Fruit.Raspberry {
            private struct Invocation {
            static func invoke(_ data: Data?) -> Data? { Lib.ServiceFruitRaspberry(data) }
            }
            
            enum Service {
            public static func invoke(name: String, seed: String) -> Future<Response, Error> {
            .init{promise in promise(self.result(.init(name: name, seed: seed)))}
            }
            
            }
            }

            """
        
        try runTest(
            source: source,
            expected: expected,
            using: RequestResponseExtensionGenerator().with(scopeMatcherAsDebug: true)
        )
    }
}
