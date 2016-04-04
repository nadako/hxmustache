import mustache.*;
import mustache.Token;

class Mustache {
    public static var tags = ["{{", "}}"];

    static var tagRe = ~/#|\^|\/|>|\{|&|=|!/;
    static var whiteRe = ~/\s*/;
    static var spaceRe = ~/\s+/;
    static var equalsRe = ~/\s*=/;
    static var curlyRe = ~/\s*\}/;
    static var defaultWriter = new Writer();

    public static inline function render(template:String, context:Context, ?partials:Partials):String {
        return defaultWriter.render(template, context, partials);
    }

    public static inline function parse(template:String, ?tags:Array<String>):Array<Token> {
        return defaultWriter.parse(template, tags);
    }

    public static inline function clearCache():Void {
        defaultWriter.clearCache();
    }

    @:allow(mustache.Writer.parse)
    static function parseTemplate(template:String, ?tags:Array<String>):Array<Token> {
        if (template.length == 0)
            return [];

        var sections = [];     // Stack to hold section tokens
        var tokens = [];       // Buffer to hold the tokens
        var spaces = [];       // Indices of whitespace tokens on the current line
        var hasTag = false;    // Is there a {{tag}} on the current line?
        var nonSpace = false;  // Is there a non-space char on the current line?

        var openingTagRe, closingTagRe, closingCurlyRe;
        function compileTags(tagsToCompile:Array<String>) {
            if (tagsToCompile.length != 2)
                throw "Invalid tags: " + tagsToCompile;

            openingTagRe = new EReg(escapeRegExp(tagsToCompile[0]) + '\\s*', "");
            closingTagRe = new EReg('\\s*' + escapeRegExp(tagsToCompile[1]), "");
            closingCurlyRe = new EReg('\\s*' + escapeRegExp('}' + tagsToCompile[1]), "");
        }
        compileTags(tags != null ? tags : Mustache.tags);

        var scanner = new Scanner(template);
        while (!scanner.eos()) {
            var start = scanner.pos;

            // Match any text between tags.
            var value = scanner.scanUntil(openingTagRe);

            if (value.length > 0) {
                for (i in 0...value.length) {
                    var chr = value.charAt(i);

                    if (isWhitespace(chr))
                        spaces.push(tokens.length);
                    else
                        nonSpace = true;

                    tokens.push(new Token(Text, chr, start, start + 1));
                    start += 1;

                    // Check for whitespace on the current line.
                    if (chr == '\n') {
                        // Strips all whitespace tokens array for the current line
                        // if there was a {{#tag}} on it and otherwise only space.
                        if (hasTag && !nonSpace) {
                            while (spaces.length > 0)
                                tokens[spaces.pop()] = null;
                        } else {
                            spaces = [];
                        }

                        hasTag = false;
                        nonSpace = false;
                    }
                }
            }
            // Match the opening tag.
            if (scanner.scan(openingTagRe).length == 0)
                break;

            hasTag = true;

            // Get the tag type.
            var type = scanner.scan(tagRe);
            if (type.length > 0)
                scanner.scan(whiteRe);

            // Get the tag value.
            if (type == '=') {
                value = scanner.scanUntil(equalsRe);
                scanner.scan(equalsRe);
                scanner.scanUntil(closingTagRe);
            } else if (type == '{') {
                value = scanner.scanUntil(closingCurlyRe);
                scanner.scan(curlyRe);
                scanner.scanUntil(closingTagRe);
                type = '&';
            } else {
                value = scanner.scanUntil(closingTagRe);
            }

            // Match the closing tag.
            if (scanner.scan(closingTagRe).length == 0)
                throw 'Unclosed tag at ${scanner.pos}';

            var tokenType = switch(type) {
                case "#": Section(false);
                case "^": Section(true);
                case "/": SectionClose;
                case "": Value(true);
                case "&": Value(false);
                case "!": Comment;
                case "=": SetDelimiters;
                case ">": Partial;
                default: throw "unknown token type: " + type;
            }

            var token = new Token(tokenType, value, start, scanner.pos);
            tokens.push(token);

            switch (tokenType) {
                case Section(_):
                    sections.push(token);
                case SectionClose:
                    // Check section nesting.
                    var openSection = sections.pop();

                    if (openSection == null)
                        throw 'Unopened section "$value" at $start';

                    if (openSection.value != value)
                        throw 'Unclosed section "${openSection.value}" at $start';
                case Value(_):
                    nonSpace = true;
                case SetDelimiters:
                    // Set the tags for the next time around.
                    compileTags(spaceRe.split(value));
                default:
            }
        }

        // Make sure there are no open sections when we're done.
        var openSection = sections.pop();
        if (openSection != null)
            throw 'Unclosed section "${openSection.value}" at ${scanner.pos}';

        return nestTokens(squashTokens(tokens));
    }


    static function squashTokens(tokens:Array<Token>):Array<Token> {
        var squashedTokens = [];

        var lastToken = null;
        for (token in tokens) {
            if (token != null) {
                if (token.type == Text && lastToken != null && lastToken.type == Text) {
                    lastToken.value += token.value;
                    lastToken.endIndex = token.endIndex;
                } else {
                    squashedTokens.push(token);
                    lastToken = token;
                }
            }
        }

        return squashedTokens;
    }

    static function nestTokens(tokens:Array<Token>):Array<Token> {
        var nestedTokens = [];
        var collector = nestedTokens;
        var sections = [];

        for (token in tokens) {
            switch (token.type) {
                case Section(_):
                    collector.push(token);
                    sections.push(token);
                    collector = token.subTokens = [];
                case SectionClose:
                    var section = sections.pop();
                    section.sectionEndIndex = token.startIndex;
                    collector = if (sections.length > 0) sections[sections.length - 1].subTokens else nestedTokens;
                default:
                    collector.push(token);
            }
        }

        return nestedTokens;
    }

    static var escapeRegExpRe = ~/[\-\[\]{}()*+?.,\\\^$|#\s]/g;
    static function escapeRegExp(string:String):String {
        return escapeRegExpRe.map(string, function(r) return "\\" + r.matched(0));
    }

    static var nonSpaceRe = ~/\S/;
    static inline function isWhitespace(string:String):Bool {
        return !nonSpaceRe.match(string);
    }

    static var entityMap = [
        '&' => '&amp;',
        '<' => '&lt;',
        '>' => '&gt;',
        '"' => '&quot;',
        "'" => '&#39;',
        '/' => '&#x2F;',
        '`' => '&#x60;',
        '=' => '&#x3D;',
    ];
    static var escapeRe = ~/[&<>"'`=\/]/g;
    public static function escape(string:String):String {
        return escapeRe.map(string, function(re) return entityMap[re.matched(0)]);
    }

    @:allow(mustache.Writer)
    static function getSectionValueKind(value:Dynamic):SectionValueKind {
        if (value == null)
            return KFalsy;

        if (Std.is(value, Bool))
            return if ((value : Bool)) KBasic else KFalsy;

        if (Std.is(value, Float))
            return if ((value : Float) != 0) KBasic else KFalsy;

        var str = Std.instance(value, String);
        if (str != null)
            return if (str.length > 0) KObject(str) else KFalsy;

        var arr = Std.instance(value, Array);
        if (arr != null)
            return if (arr.length > 0) KArray(arr) else  KFalsy;

        if (Reflect.isFunction(value))
            return KFunction(value);

        if (Reflect.isObject(value))
            return KObject(value);

        return KBasic;
    }
}

enum SectionValueKind {
    KFalsy;
    KArray(a:Array<Dynamic>);
    KObject(o:{});
    KBasic;
    KFunction(f:View->String->(String->Null<String>)->Null<String>);
}