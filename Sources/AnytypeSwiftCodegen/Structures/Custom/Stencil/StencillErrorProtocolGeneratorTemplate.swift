import Foundation

let StencillErrorProtocolGeneratorTemplate = """
{% for object in objects %}
extension {{ object.type }}: Swift.Error {}
{% endfor %}
"""
