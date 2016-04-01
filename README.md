[![Build Status](https://travis-ci.org/nadako/hxmustache.svg?branch=master)](https://travis-ci.org/nadako/hxmustache)

# Mustache templates for Haxe

This is a Haxe implementation of logic-less [mustache](http://mustache.github.io/) templating.

Originally ported from [mustache.js](https://github.com/janl/mustache.js).

**Status**: works fine, passes tests and safe to use. Internal structure and API may change a little, but not much.

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

More docs coming, meanwhile, see [mustache(5)](http://mustache.github.io/mustache.5.html) for the actual template language description.
