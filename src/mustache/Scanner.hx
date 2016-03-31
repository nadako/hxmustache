package mustache;

class Scanner {
    public var string(default,null):String;
    public var tail(default,null):String;
    public var pos(default,null):Int;

    public function new(string:String) {
        this.string = string;
        this.tail = string;
        this.pos = 0;
    }

    public inline function eos():Bool {
        return tail == "";
    }

    public function scan(re:EReg):String {
        if (!re.match(tail))
            return "";

        var p = re.matchedPos();
        if (p.pos != 0)
            return "";

        tail = tail.substring(p.len);
        pos += p.len;

        return re.matched(0);
    }

    public function scanUntil(re:EReg):String {
        var match;

        if (re.match(tail)) {
            var p = re.matchedPos();
            if (p.pos == 0) {
                match = "";
            } else {
                match = tail.substring(0, p.pos);
                tail = tail.substring(p.pos);
            }
        } else {
            match = tail;
            tail = "";
        }

        pos += match.length;

        return match;
    }
}
