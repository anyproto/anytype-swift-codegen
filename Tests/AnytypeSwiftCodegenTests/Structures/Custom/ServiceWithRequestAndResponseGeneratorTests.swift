import XCTest
@testable import AnytypeSwiftCodegen

final class ServiceGeneratorTests: XCTestCase
{
    private enum Constants {
        static let template = """
        {% for endpoint in endpoints %}
        Type = {{ endpoint.type }}
        InvocationName = {{ endpoint.invocationName }}
        Arguments:
        {% for field in endpoint.requestArguments %}
        {{ field.name }},{{field.type}},{{ field.defaultValue }}
        {% endfor %}
        {% endfor %}
        """
    }
    
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
            
            Type = Outer.Fruit.Apple
            InvocationName = FruitApple
            Arguments:
            name,String,"abc"
            seedCount,Int,44
            Type = Outer.Fruit.Raspberry
            InvocationName = FruitRaspberry
            Arguments:
            name,String,"def"
            seed,String,45

            """
        
        let serviceFilePath = try createFile(service)
        
        try runTest(
            source: source,
            expected: expected,
            using: ServiceGenerator(scope: .public, template: Constants.template, serviceFilePath: serviceFilePath.path)
        )
    }
}
