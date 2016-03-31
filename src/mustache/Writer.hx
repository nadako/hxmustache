package mustache;

class Writer {
    var cache:Map<String,Array<Token>>;

    public function new() {
        cache = new Map();
    }

    public inline function clearCache():Void {
        cache = new Map();
    }

    public function parse(template:String, ?tags:Array<String>):Array<Token> {
        var tokens = cache[template];

        if (tokens == null)
            tokens = cache[template] = Mustache.parseTemplate(template, tags);

        return tokens;
    }

    public inline function render(template:String, context:Context, partials):String {
        return renderTokens(parse(template), context, partials, template);
    }

    function renderTokens(tokens:Array<Token>, context:Context, partials, originalTemplate:String):String {
        var buffer = '';

        for (token in tokens) {
            var symbol = token[0];

            var value =
                if (symbol == '#') renderSection(token, context, partials, originalTemplate);
                else if (symbol == '^') renderInverted(token, context, partials, originalTemplate);
                else if (symbol == '>') renderPartial(token, context, partials);
                else if (symbol == '&') unescapedValue(token, context);
                else if (symbol == 'name') escapedValue(token, context);
                else if (symbol == 'text') rawValue(token);
                else null;

            if (value != null)
                buffer += value;
        }

        return buffer;
    }

    function renderSection(token:Token, context:Context, partials, originalTemplate:String):String {
        var buffer = '';
        var value:Dynamic = context.lookup(token[1]);

        function subRender(template) return render(template, context, partials);

        switch (Type.typeof(value)) {
            case TNull:
                return null;
            case TClass(Array):
                for (elem in (value : Array<Dynamic>)) {
                    buffer += renderTokens(token[4], context.push(elem), partials, originalTemplate);
                }
            case TObject | TFloat | TInt | TClass(String):
                buffer += renderTokens(token[4], context.push(value), partials, originalTemplate);
            case TFunction:
                // Extract the portion of the original template that the section contains.
                value = value(context.view, originalTemplate.substring(token[3], token[5]), subRender);
                if (value != null)
                    buffer += value;
            default:
                buffer += renderTokens(token[4], context, partials, originalTemplate);
        }

        return buffer;
    }

    function renderInverted(token:Token, context:Context, partials, originalTemplate:String):String {
        var value:Dynamic = context.lookup(token[1]);

        if (value != null)
            return null;

        var arr = Std.instance(value, Array);
        if (arr != null && arr.length > 0)
            return null;

        return renderTokens(token[4], context, partials, originalTemplate);
    }

    function renderPartial(token:Token, context:Context, partials:Dynamic):String {
        if (partials == null) return null;

        var value = Reflect.isFunction(partials) ? partials(token[1]) : partials[token[1]];
        if (value != null)
            return renderTokens(this.parse(value), context, partials, value);

        return null;
    }

    inline function unescapedValue(token:Token, context:Context):String {
        return context.lookup(token[1]);
    }

    function escapedValue(token:Token, context:Context):String {
        var value = context.lookup(token[1]);
        return if (value != null) Mustache.escape(value) else null;
    }

    inline function rawValue(token:Token):String {
        return token[1];
    }
}
