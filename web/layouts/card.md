{% if title %}## {{ title }}{% endif  %}
{{ "![](" + image + ")" if image else "" }}
{{ contents|safe }}
