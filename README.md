[![Build Status](https://travis-ci.org/nadako/hxmustache.svg?branch=master)](https://travis-ci.org/nadako/hxmustache)

# Mustache templates for Haxe

This is a Haxe implementation of logic-less [mustache](http://mustache.github.io/) templating.

Originally ported from [mustache.js](https://github.com/janl/mustache.js).

**Status**: works fine, passes tests and should be safe to use. Travis-tested on all Haxe targets (except the new Lua one).
Internal structure and API may change a little, but not much.

[Try online!](http://nadako.github.io/hxmustache/)

## Usage

Here's a quick example:

```haxe
class Main {
    static function main() {
        var template = "Hello {{name}}, how are you?";
        var context = {name: "World"};
        var output = Mustache.render(template, context);
        trace(output); // Hello World, how are you?
    }
}
```

See [mustache(5)](http://mustache.github.io/mustache.5.html) for the actual template language description, here we'll
only document extensions and API specifics.

## API

The main entry point is the `Mustache.render` function and it's defined like this:

```haxe
public static function render(template:String, context:mustache.Context, ?partials:mustache.Partials):String;
```

The `template` argument is obviously the template itself. It will be parsed to an AST and cached across calls.

The `context` is the root context for template variables. You can pass any object and its fields will be looked up
using reflection. If field is a function, it will be called without arguments on lookup to return a value to render.
If the object passed is instance of `haxe.ds.StringMap` it contents will be accessed via `get` call rather than reflection.
For an advanced usage, you can manually create `new mustache.Context(yourData)`.

The `partials` (optional) is where partial templates are stored (used by `{{>name}}` and `{{<name}}...{{/name}}` tags).
It can either be an object with string fields or a lookup function with `String->String` signature.

## Falsy values

Mustache uses concept of falsy values for e.g. determining if section should be rendered or not.
Here's what hxmustache considers *falsy*:

 * `null`
 * `false`
 * `0` and `0.0`
 * empty `String`
 * empty `Array`

These values will make `{{#name}}` sections NOT render, and `{{^name}}` DO render. If used as `{{value}}`s, they won't be rendered in any way.

All other values are considered truthy.

## Functions

If the value of a section is a function, it will be called with 2 arguments:

 * part of template inside the section
 * rendering function (`String->String`)

...and is expected to return rendered string. Example:

```haxe
class Main {
    static function main() {
        var context = {
            "name": "Tater",
            "bold": function() { // this function will be called when looking up `bold`
                return function(text, render) { // this function will be called for rendering a section
                    return "<b>" + render(text) + "</b>";
                }
            }
        };
        var template = "{{#bold}}Hi {{name}}.{{/bold}}";
        var output = Mustache.render(template, context);
        trace(output); // <b>Hi Tater.</b>
    }
}
```



## Additional features

### Template inheritance

hxmustache implements the popular [template inheritance proposal](https://github.com/mustache/spec/pull/75).
Example:

```haxe
class Main {
    static function main() {
        var layout = "
        <head>
            <title>{{$title}}Default title{{/title}}</title>
        </head>
        <body>
            <div id='content'>
            {{$content}}{{/content}}
            </div>
        </body>";

        var template = "
        {{<layout}}
            {{$title}}{{name}}{{/title}}
            {{$content}}
                Hello, {{name}}!
            {{/content}}
        {{/layout}}";

        var context = {name: "Dan"};

        var partials = {"layout": layout};
        var output = Mustache.render(template, context, partials);

        trace(output);
        /*
            <head>
                <title>Dan</title>
            </head>
            <body>
                <div id='content'>
                    Hello, Dan!
                </div>
            </body>
        */
    }
}
```

## Command-line interface

hxmustache can be used as a command-line tool. Examples:

Output to stdout:
```
haxelib run hxmustache view.json template.mustache
```

Output to `output.html`:
```
haxelib run hxmustache view.json template.mustache output.html
```

Add partial templates:
```
haxelib run hxmustache view.json template.mustache -p mypartial.mustache -p myotherpartial.mustache
```

Partials will be available by the name of the partial template file without directory and extension (e.g. `layout` for `templates/layout.mustache`).
