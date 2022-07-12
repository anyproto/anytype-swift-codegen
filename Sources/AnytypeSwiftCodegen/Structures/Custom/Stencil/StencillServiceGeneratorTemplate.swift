import Foundation

let StencillServiceGeneratorTemplate = """
import Combine
import Foundation
import Lib
import SwiftProtobuf

enum Anytype_Middleware_Error {
  static let domain: String = "org.anytype.middleware.services"
}

{% macro functionArguments fields %}{% filter removeNewlines:"leading" %}
    {% for field in fields %}
        {{ field.name }}: {{field.type}}{% if field.defaultValue %} = {{ field.defaultValue }}{% endif %}
        {{ ", " if not forloop.last }}
    {% endfor %}
{% endfilter %}{% endmacro %}
{% macro functionCallArguments fields %}{% filter removeNewlines:"leading" %}
    {% for field in fields %}
        {{ field.name }}: {{ field.name }}
        {{ ", " if not forloop.last }}
    {% endfor %}
{% endfilter %}{% endmacro %}
{% for endpoint in endpoints %}
extension {{ endpoint.type }} {
  private struct Invocation {
    static func invoke(_ data: Data?) -> Data? { Lib.Service{{ endpoint.invocationName }}(data) }
  }

  public enum Service {
    public static func invoke({% filter removeNewlines:"leading" %}
        {% call functionArguments endpoint.requestArguments %}
        {% if endpoint.requestArguments.count != 0 %}, {% endif %}
        queue: DispatchQueue? = nil
        {% endfilter %}) -> Future<Response, Error> {
      self.invoke(request: .init({% call functionCallArguments endpoint.requestArguments %}), on: queue)
    }
    public static func invoke({% call functionArguments endpoint.requestArguments %}) -> Result<Response, Error> {
      self.result(.init({% call functionCallArguments endpoint.requestArguments %}))
    }
    private static func invoke(request: Request, on queue: DispatchQueue?) -> Future<Response, Error> {
      .init { promise in
        if let queue = queue {
          queue.async {
            promise(self.result(request))
          }
        } else {
          promise(self.result(request))
        }
      }
    }
    private static func result(_ request: Request) -> Result<Response, Error> {
      guard let result = self.invoke(request) else {
        // get first Not Null (not equal 0) case.
        return .failure(Response.Error(code: .unknownError, description_p: "Unknown error during parsing"))
      }
      // get first zero case.
      if result.error.code != .null {
        let domain = Anytype_Middleware_Error.domain
        let code = result.error.code.rawValue
        let description = result.error.description_p
        return .failure(NSError(domain: domain, code: code, userInfo: [NSLocalizedDescriptionKey: description]))
      } else {
        return .success(result)
      }
    }
    private static func invoke(_ request: Request) -> Response? {
      Invocation.invoke(try? request.serializedData()).flatMap {
        try? Response(serializedData: $0)
      }
    }
  }
}

{% endfor %}
"""
