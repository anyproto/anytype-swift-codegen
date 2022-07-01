import XCTest
@testable import AnytypeSwiftCodegen

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
                            var name: String = "abc"
                            var seedCount: Int = 44
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
                            var name: String = "def"
                            var seed: String = 45
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
        
        let service = """
        service ClientCommands {
            rpc FruitApple (Outer.Fruit.Apple.Request) returns (Outer.Fruit.Apple.Response);
            rpc FruitRaspberry (Outer.Fruit.Raspberry.Request) returns (Outer.Fruit.Raspberry.Response);
        }
        """
        
        let expected = """
            extension Outer.Fruit.Apple {
                private struct Invocation {
                    static func invoke(_ data: Data?) -> Data? { Lib.ServiceFruitApple(data) }
                }

                public enum Service {
                    public static func invoke(name: String = "abc", seedCount: Int = 44, queue: DispatchQueue? = nil) -> Future<Response, Error> {
                        self.invoke(parameters: .init(name: name, seedCount: seedCount), on: queue)
                    }
                    public static func invoke(name: String = "abc", seedCount: Int = 44) -> Result<Response, Error> {
                        self.result(.init(name: name, seedCount: seedCount))
                    }

                }
            }

            extension Outer.Fruit.Raspberry {
                private struct Invocation {
                    static func invoke(_ data: Data?) -> Data? { Lib.ServiceFruitRaspberry(data) }
                }

                public enum Service {
                    public static func invoke(name: String = "def", seed: String = 45, queue: DispatchQueue? = nil) -> Future<Response, Error> {
                        self.invoke(parameters: .init(name: name, seed: seed), on: queue)
                    }
                    public static func invoke(name: String = "def", seed: String = 45) -> Result<Response, Error> {
                        self.result(.init(name: name, seed: seed))
                    }

                }
            }

            """
        
        let serviceFilePath = try createFile(service)
        
        try runTest(
            source: source,
            expected: expected,
            using: ServiceGenerator(scope: .public, templatePath: "", serviceFilePath: serviceFilePath.path)
        )
    }
}
