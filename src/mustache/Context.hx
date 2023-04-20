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
        var value: Dynamic = null;
        if (cache.exists(name)) {
            value = cache[name];
        } else {
            var context = (this : Context);
            while (context != null) {
                var found = false;

                if (name.indexOf(".") == -1) {
                    // simple name - just try getting the value from this view
                    switch (getField(context.view, name)) {
                        case Some(v):
                            found = true;
                            value = v;
                        case None:
                    }
                } else {
                    // dotted name - traverse through values
                    var names = name.split('.');
                    var index = 0;

                    value = context.view;
                    while (value != null && index < names.length) {
                        switch (getField(value, names[index++])) {
                            case Some(v):
                                if (index == names.length - 1)
                                    found = true;
                                value = v;
                            case None:
                                value = null;
                        }
                    }

                }

                if (found)
                    break;

                context = context.parent;
            }

            cache[name] = value;
        }

        if (Reflect.isFunction(value))
            value = value();
        return value;
    }

    static function getField(object:Dynamic, name:String):haxe.ds.Option<Dynamic> {
        var map = #if haxe4 Std.downcast #else Std.instance #end(object, haxe.ds.StringMap);
        if (map != null) {
            return map.exists(name) ? Some(map.get(name)) : None;
        }

        var value = Reflect.field(object, name);

        // if field is a function, return a closure that calls the method with this object
        if (Reflect.isFunction(value))
            return Some(function() return Reflect.callMethod(object, value, []));

        // if it's a non-null value or is null, but contained in the structure - nice
        if (value != null || Reflect.hasField(object, name))
            return Some(value);

        // if it's a null value, and Reflect.hasField returned false (because it's only guaranteed to work on anon structures)
        // check if object is an instance of class and its definition contains given field
        var cl = Type.getClass(object);
        if (cl != null && Type.getInstanceFields(cl).indexOf(name) != -1)
            return Some(value);

        // otherwise, field not found :(
        return None;
    }
}
