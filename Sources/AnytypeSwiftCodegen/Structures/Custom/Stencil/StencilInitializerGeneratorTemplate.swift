import Foundation

let StencilInitializerGeneratorTemplate = """
{% for object in objects where object.fields.count != 0%}
extension {{ object.type }} {
    public init({% filter removeNewlines:"leading" %}
    {% for field in object.fields %}
        {{ field.name }}: {{field.type}}{% if field.defaultValue %} = {{ field.defaultValue }}{% endif %}
        {{ ", " if not forloop.last }}
    {% endfor %}
    {% endfilter %}) {
        {% for field in object.fields %}
        self.{{ field.name }} = {{ field.name }}
        {% endfor %}
    }
}

{% endfor %}
"""
