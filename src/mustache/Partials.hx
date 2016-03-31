package mustache;

@:callable
abstract Partials(String->String) from String->String {
    @:from static inline function fromObject(obj:{}):Partials {
        return function(name) return Reflect.field(obj, name);
    }
}
