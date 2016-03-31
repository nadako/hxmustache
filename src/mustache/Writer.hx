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
            var value = switch (token.type) {
                case Section: renderSection(token, context, partials, originalTemplate);
                case SectionInverted: renderInverted(token, context, partials, originalTemplate);
                case Partial: renderPartial(token, context, partials);
                case ValueUnescaped: unescapedValue(token, context);
                case Value: escapedValue(token, context);
                case Text: rawValue(token);
                case Comment | SetDelimiter | SectionClose: continue;
            }
            if (value != null)
                buffer += value;
        }

        return buffer;
    }

    function renderSection(token:Token, context:Context, partials, originalTemplate:String):String {
        var value:Dynamic = context.lookup(token.value);

        if (value == null)
            return null;

        if ((value is Bool) && !(value : Bool))
            return null;

        switch (Type.typeof(value)) {
            case TClass(Array):
                var buffer = '';
                var arr = (value : Array<Dynamic>), len = arr.length;
                for (i in 0...len) {
                    buffer += renderTokens(token.subTokens, context.push(arr[i]), partials, originalTemplate);
                }
                return buffer;
            case TObject | TFloat | TInt:
                return renderTokens(token.subTokens, context.push(value), partials, originalTemplate);
            case TClass(String):
                if ((value : String).length == 0)
                    return null;
                return renderTokens(token.subTokens, context.push(value), partials, originalTemplate);
            case TFunction:
                // Extract the portion of the original template that the section contains.
                value = value(context.view, originalTemplate.substring(token.endIndex, token.sectionEndIndex), function(template) return render(template, context, partials));
                if (value != null)
                    return value;
            default:
                return renderTokens(token.subTokens, context, partials, originalTemplate);
        }
    }

    function renderInverted(token:Token, context:Context, partials, originalTemplate:String):String {
        var value:Dynamic = context.lookup(token.value);

        var render = (value == null);

        if (!render) {
            var arr = Std.instance(value, Array);
            if (arr != null && arr.length == 0)
                render = true;
        }
        
        if (!render) {
            if ((value is String) && (value : String).length == 0)
                render = true;
        }

        if (!render)
            return null;
        else
            return renderTokens(token.subTokens, context, partials, originalTemplate);
    }

    function renderPartial(token:Token, context:Context, partials:Dynamic):String {
        if (partials == null) return null;

        var value = Reflect.isFunction(partials) ? partials(token.value) : Reflect.field(partials, token.value);
        if (value != null)
            return renderTokens(this.parse(value), context, partials, value);

        return null;
    }

    inline function unescapedValue(token:Token, context:Context):String {
        return context.lookup(token.value);
    }

    function escapedValue(token:Token, context:Context):String {
        var value = context.lookup(token.value);
        return if (value != null) Mustache.escape(Std.string(value)) else null;
    }

    inline function rawValue(token:Token):String {
        return token.value;
    }
}
