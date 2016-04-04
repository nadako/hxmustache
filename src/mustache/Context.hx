package mustache;

@:dce
@:forward
abstract Context(ContextImpl) from ContextImpl {
    public inline function new(view:View, ?parentContext:Context, ?partialOverride:Token) {
        this = new ContextImpl(view, parentContext, partialOverride);
    }

    @:from static inline function fromView(view:View):Context {
        return new Context(view);
    }
}

private class ContextImpl {
    public var view(default,null):View;
    public var parent(default,null):Context;
    var cache:Map<String,Dynamic>;
    public var partialOverride:Null<Token>;

    public function new(view:View, parentContext:Context, partialOverride:Token) {
        this.view = view;
        this.cache = ['.' => view];
        this.parent = parentContext;
        this.partialOverride = partialOverride;
    }
    
    public inline function push(view:View, ?partialOverride:Token):Context {
        return new Context(view, this, partialOverride);
    }

    public function lookup(name:String):Dynamic {
        var value = null;
        if (cache.exists(name)) {
            value = cache[name];
        } else {
            var context = (this : Context), lookupHit = false;
            while (context != null) {
                if (name.indexOf('.') > 0) {
                    value = context.view;
                    var names = name.split('.');
                    var index = 0;

                    while (value != null && index < names.length) {
                        if (index == names.length - 1)
                            lookupHit = Reflect.hasField(value, names[index]);

                        value = Reflect.field(value, names[index++]);
                    }
                } else {
                    value = Reflect.field(context.view, name);
                    lookupHit = Reflect.hasField(context.view, name);
                }

                if (lookupHit)
                    break;

                context = context.parent;
            }

            cache[name] = value;
        }

        if (Reflect.isFunction(value))
            value = value(view);
        return value;
    }
}
