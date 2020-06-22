package graphql;

using StringTools;

abstract Source(graphql.parser.Source) from graphql.parser.Source to graphql.parser.Source {
    inline function new(t:graphql.parser.Source) {
        this = t;
    }


    @:from public static inline function fromString(s:String) {
        return new Source(new graphql.parser.Source(s.trim()));
    }

    @:to public inline function toString():String {
        return this.body.toString();
    }
}