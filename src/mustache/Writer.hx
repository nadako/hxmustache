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
                case Section(inverted):
                    if (inverted)
                        renderInverted(token, context, partials, originalTemplate);
                    else
                        renderSection(token, context, partials, originalTemplate);
                case Partial:
                    renderPartial(token, context, partials);
                case PartialOverride:
                    renderPartialOverride(token, context, partials);
                case Block:
                    renderBlock(token, context, partials, originalTemplate);
                case Value(escape):
                    var value = context.lookup(token.value);
                    if (value == null)
                        null;
                    else if (escape)
                        Mustache.escape(Std.string(value));
                    else
                        Std.string(value);
                case Text:
                    token.value;
                case Comment | SetDelimiters | SectionClose:
                    continue;
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
                var len = arr.length;
                for (i in 0...len)
                    buffer += renderTokens(token.subTokens, context.push(arr[i]), partials, originalTemplate);
                buffer;
            case KFunction(f):
                // Extract the portion of the original template that the section contains.
                f(originalTemplate.substring(token.endIndex, token.sectionEndIndex), function(template) return render(template, context, partials));
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

    function renderPartialOverride(token:Token, context:Context, partials:Partials):String {
        if (partials == null)
            return null;

        var value = partials(token.value);
        if (value == null)
            return null;

        return renderTokens(this.parse(value), context.push({}, token), partials, value);
    }

    inline function renderBlock(token:Token, context:Context, partials:Partials, originalTemplate:String):String {
        return renderTokens(resolveBlock(token, context).subTokens, context, partials, originalTemplate);
    }

    function resolveBlock(token:Token, context:Context):Token {
        var resultToken = token;
        while (context != null) {
            if (context.partialOverride != null) {
                for (overrideToken in context.partialOverride.subTokens) {
                    if (overrideToken.type == Block && overrideToken.value == token.value)
                        resultToken = overrideToken;
                }
            }
            context = context.parent;
        }
        return resultToken;
    }
}
