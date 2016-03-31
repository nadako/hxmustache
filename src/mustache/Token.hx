package mustache;

abstract Token(Array<Dynamic>) {
    public inline function new(type:String, value:String, startIndex:Int, endIndex:Int, ?subTokens:Array<Token>, ?closing:Int) {
        this = [type, value, startIndex, endIndex, subTokens, closing];
    }

    public var type(get,never):String;
    inline function get_type() return this[0];

    public var value(get,set):String;
    inline function get_value() return this[1];
    inline function set_value(v) return this[1] = v;

    public var startIndex(get,never):Int;
    inline function get_startIndex() return this[2];

    public var endIndex(get,set):Int;
    inline function get_endIndex() return this[3];
    inline function set_endIndex(v) return this[3] = v;

    public var subTokens(get,set):Array<Token>;
    inline function get_subTokens() return this[4];
    inline function set_subTokens(v) return this[4] = v;

    public var sectionEndIndex(get,set):Int;
    inline function get_sectionEndIndex() return this[5];
    inline function set_sectionEndIndex(v) return this[5] = v;
}
