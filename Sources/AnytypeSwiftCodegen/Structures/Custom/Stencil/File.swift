import Foundation

let FunctionArgumentsTemplate = """
{% filter removeNewLines %}
    {% for field in object.fields %}
        {{ field.name }}: {{field.type}}
        {% if field.defaultValue %} = {{ field.defaultValue }}{% endif %}
        {{ ", " if not forloop.last }}
    {% endfor %}
{% endfilter %}{% endmacro %}
"""

let FunctionCallArgumentsTemplate = """
{% filter removeNewLines %}
    {% for field in object.fields %}
        {{ field.name }}: {{ field.name }}
        {{ ", " if not forloop.last }}
    {% endfor %}
{% endfilter %}
"""
