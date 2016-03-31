class Assert {
    public static var assert(default,never) = new A();

    #if (haxe_ver < 3.3) // this is some hack for some haxe 3.2.1 bug
    @:native("assert")
    static function phpAssert() {
        untyped __php__("$args = func_get_args(); return call_user_func_array(self::$assert, $args);");
    }
    #end
}

@:callable
private abstract A(Bool->Void) {
    public inline function new() this = function(b) utest.Assert.isTrue(b);
    public inline function equal<T>(a:T, b:T) return utest.Assert.equals(b, a);
    public inline function deepEqual(a, b) return utest.Assert.same(b, a);
    public function throws(fn:Void->Void, re:EReg) {
        try fn() catch(e:String) {
            utest.Assert.match(re, e);
            return;
        }
        throw "no error thrown";
    }
}
