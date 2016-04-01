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

    public inline function render(template:String, context:Context, partials:Partials):String {
        return renderTokens(parse(template), context, partials, template);
    }

    function renderTokens(tokens:Array<Token>, context:Context, partials:Partials, originalTemplate:String):String {
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

    function renderSection(token:Token, context:Context, partials:Partials, originalTemplate:String):String {
        var value = context.lookup(token.value);
        return switch (Mustache.getSectionValueKind(value)) {
            case KFalsy:
                null;
            case KBasic:
                renderTokens(token.subTokens, context, partials, originalTemplate);
            case KObject(obj):
                renderTokens(token.subTokens, context.push(obj), partials, originalTemplate);
            case KArray(arr):
                var buffer = '';
                var arr = (value : Array<Dynamic>), len = arr.length;
                for (i in 0...len)
                    buffer += renderTokens(token.subTokens, context.push(arr[i]), partials, originalTemplate);
                buffer;
            case KFunction(f):
                // Extract the portion of the original template that the section contains.
                f(context.view, originalTemplate.substring(token.endIndex, token.sectionEndIndex), function(template) return render(template, context, partials));
        }
    }

    function renderInverted(token:Token, context:Context, partials:Partials, originalTemplate:String):String {
        var value = context.lookup(token.value);
        return switch (Mustache.getSectionValueKind(value)) {
            case KFalsy: renderTokens(token.subTokens, context, partials, originalTemplate);
            default: null;
        }
    }

    function renderPartial(token:Token, context:Context, partials:Partials):String {
        if (partials == null)
            return null;

        var value = partials(token.value);
        if (value != null)
            return renderTokens(this.parse(value), context, partials, value);

        return null;
    }

    function unescapedValue(token:Token, context:Context):String {
        var value = context.lookup(token.value);
        return if (value != null) return Std.string(value) else null;
    }

    function escapedValue(token:Token, context:Context):String {
        var value = context.lookup(token.value);
        return if (value != null) Mustache.escape(Std.string(value)) else null;
    }

    inline function rawValue(token:Token):String {
        return token.value;
    }
}
