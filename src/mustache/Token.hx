package mustache;

enum TokenType {
    Text;
    Value;
    ValueUnescaped;
    Section;
    SectionInverted;
    SectionClose;
    Partial;
    Comment;
    SetDelimiter;
}

class Token {
    public var type:TokenType;
    public var value:String;
    public var startIndex:Int;
    public var endIndex:Int;
    public var subTokens:Array<Token>;
    public var sectionEndIndex:Int;

    public inline function new(type:TokenType, value:String, startIndex:Int, endIndex:Int, ?subTokens:Array<Token>, ?sectionEndIndex:Int) {
        this.type = type;
        this.value = value;
        this.startIndex = startIndex;
        this.endIndex = endIndex;
        this.subTokens = subTokens;
        this.sectionEndIndex = sectionEndIndex;
    }
}
