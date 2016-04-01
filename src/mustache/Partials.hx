package mustache;

@:callable
abstract Partials(String->String) from String->String {
    @:from static inline function fromDynamic(obj:Dynamic):Partials {
        return function(name) return Reflect.field(obj, name);
    }
}
