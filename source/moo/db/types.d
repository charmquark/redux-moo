/*//////////////////////////////////////////////////////////////////////////////////////////////////
////                                                                                            ////
////    Copyright 2014 Christopher Nicholson-Sauls                                              ////
////                                                                                            ////
////    Licensed under the Apache License, Version 2.0 (the "License"); you may not use this    ////
////    file except in compliance with the License.  You may obtain a copy of the License at    ////
////                                                                                            ////
////        http://www.apache.org/licenses/LICENSE-2.0                                          ////
////                                                                                            ////
////    Unless required by applicable law or agreed to in writing, software distributed         ////
////    under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR             ////
////    CONDITIONS OF ANY KIND, either express or implied.  See the License for the specific    ////
////    language governing permissions and limitations under the License.                       ////
////                                                                                            ////
//////////////////////////////////////////////////////////////////////////////////////////////////*/

/**
 *  Defines various datatypes used by the database, and which ought to be used by the vm and any
 *  other components that are dealing wiht the database.
 */
module moo.db.types;


/**
 *  Some basic types.
 */
alias MFloat    = double    ;
alias MInt      = long      ;   ///ditto
alias MList     = MValue[]  ;   ///ditto
alias MString   = dstring   ;   ///ditto


/**
 *  MOO error type.
 */
enum MError : MInt
{
    None,
    Type,
    Div,
    Perm,
    PropNF,
    VerbNF,
    VarNF,
    InvInd,
    RecMove,
    MaxRec,
    Range,
    Args,
    NAcc,
    InvArg,
    Quota,
    Float
}


/**
 *  MOO object type.
 */
final class MObject
{
    mixin Flags!(`RECYCLED`, q{
        PLAYER      = 0x01,
        PROGRAMMER  = 0x02,
        WIZARD      = 0x04,
        RECYCLED    = 0x08,
        READ        = 0x10,
        WRITE       = 0x20,
        FERTILE     = 0x80
    });
    mixin FlagProperties!("player", "programmer", "wizard", "recycled", "fertile");
    mixin FlagProperty!(READ, "readable");
    mixin FlagProperty!(WRITE, "writable");


    private static struct IteratorByField(string F)
    {
        private MObject current;


        @property @safe bool empty() const pure nothrow
        {
            return current is null;
        }


        @property @safe inout(MObject) front() inout pure nothrow
        {
            return current;
        }


        @safe void popFront() pure nothrow
        {
            current = mixin(`current.` ~ F);
        }


        @property @safe auto save() pure nothrow
        {
            return this;
        }
    }


    package @safe this(MInt id) pure nothrow
    {
        this.id = id;
    }


    package {
        MInt                id          ;
        MObject             child       ;
        MObject             content     ;
        MObject             location    ;
        MString             name        ;
        MObject             next        ;
        MObject             owner       ;
        MObject             parent      ;
        MProperty[MSymbol]  properties  ;
        MObject             sibling     ;
        MVerb[]             verbs       ;
    }


    @property @trusted auto children() inout pure nothrow
    {
        return IteratorByField!`sibling`(cast() child);
    }


    @property @trusted auto contents() inout pure nothrow
    {
        return IteratorByField!`next`(cast() content);
    }


    @property @trusted auto inheritanceHierarchy() inout pure nothrow
    {
        return IteratorByField!`parent`(cast() this);
    }


    @property @trusted auto locationHierarchy() inout pure nothrow
    {
        return IteratorByField!`location`(cast() this);
    }


    @safe inout(MVerb) getVerb(MInt vid) inout nothrow
    {
        if (vid >= 0 && vid < verbs.length)
        {
            return verbs[vid];
        }
        return null;
    }
}


/**
 *
 */
struct MProperty
{
    mixin Flags!(`0`, q{
        READ    = 0x01,
        WRITE   = 0x02,
        CHOWN   = 0x04
    });
    mixin FlagProperty!(READ, "readable");
    mixin FlagProperty!(WRITE, "writable");
    mixin FlagProperty!(CHOWN, "chownable");


    package {
        MObject owner       = null;
        MValue  value       ;
    }
}


/**
 * 
 */
final class MSymbol
{
    static import moo.hash;


    alias MHash = moo.hash.MHash;


    private static MSymbol[MHash] _registry;


    static @trusted MSymbol opIndex(MString str)
    {
        auto norm = str.normalize();
        auto h = moo.hash.hash(norm);
        auto sym = _registry.get(h, new MSymbol(norm, h));
        return sym;
    }


    private @safe this(MString str, MHash h)
    {
        _text = str;
        _hash = h;
        _registry[h] = this;
    }


    private {
        MString _text   ;
        MHash   _hash   ;
    }


    @safe @property MHash hash() const pure nothrow
    {
        return _hash;
    }


    @safe @property MString text() const pure nothrow
    {
        return _text;
    }


    @safe int opCmp(const(MSymbol) other) const pure nothrow
    {
        return _hash < other._hash
            ? -1
            : _hash > other._hash
                ? 1
                : 0
        ;
    }


    @safe bool opEquals(const(Object) other) const pure nothrow
    {
        auto tmp = cast(const(MSymbol)) other;
        return tmp !is null ? opEquals(tmp) : false;
    }


    @safe bool opEquals(const(MSymbol) other) const pure nothrow
    {
        return this is other;
    }
}


/**
 * 
 */
enum MType : ubyte
{
    Int,
    Obj,
    String,
    Err,
    List,
    Clear,
    None,
    Catch,
    Finally,
    Float,
    Symbol,
    ObjRef
}


/**
 * 
 */
struct MValue
{
    union
    {
        MInt    i; // int, obj
        MString s; // string
        MError  e; // err
        MList   l; // list
        MFloat  f; // float
        MSymbol y; // symbol
        MObject o; // objref
    }

    MType type = MType.None;


    static @safe MValue Clear() pure nothrow
    {
        MValue result;
        result.type = MType.Clear;
        result.i = 0;
        return result;
    }


    static @safe MValue Obj(MInt val) pure nothrow
    {
        MValue result;
        result.type = MType.Obj;
        result.i = val;
        return result;
    }


    @safe this(MInt val) pure nothrow
    {
        type = MType.Int;
        i = val;
    }


    @safe this(MString val) pure nothrow
    {
        type = MType.String;
        s = val;
    }


    @safe this(MError val) pure nothrow
    {
        type = MType.Err;
        e = val;
    }


    @safe this(in MList val) pure
    {
        type = MType.List;
        l = val.dup;
    }


    @safe this(MFloat val) pure nothrow
    {
        type = MType.Float;
        f = val;
    }


    @safe this(MSymbol val) pure nothrow
    {
        type = MType.Symbol;
        y = val;
    }


    @safe this(MObject val) pure nothrow
    {
        if ( val !is null ) {
            type = MType.ObjRef;
            o = val;
        }
        else {
            type = MType.Obj;
            i = -1;
        }
    }


    /**
     *
     */
    @safe ~this () const pure nothrow
    {}


    /**
     *
     */
    @trusted this ( ref const this ) const pure
    {
        if (type == MType.List)
        {
            l = l.dup;
        }
    }


    /**
     *
     */
    @trusted MString toLiteral() const
    {
        import std.conv;

        import std.algorithm    : map;
        import std.string       : format;

        final switch (type) with (MType)
        {
            case Int        : return to!MString(i);
            case Obj        : return dtext('#', i);
            case String     : return dtext('"', s, '"');
            case Err        : return to!MString(e);
            case List       : return to!MString(`{%(%s%|, %)}`.format(l.map!(elem => elem.toLiteral())));
            case Clear      : return "<clear>"d;
            case None       : return "<none>"d;
            case Catch      : return "<catch>"d;
            case Finally    : return "<finally>"d;
            case Float      : return to!MString(f);
            case Symbol     : return dtext('"', y.text, '"');
            case ObjRef     : return dtext('#', o.id);
        }
    }


} // end MValue


/**
 *
 */
final class MVerb
{
    mixin Flags!(`0`, q{
        READ    = 0x01,
        WRITE   = 0x02,
        EXECUTE = 0x04,

        DA_MASK = 0x30,
        DA_NONE = 0x00,
        DA_ANY  = 0x10,
        DA_THIS = 0x20,
        DA_OFF  = 4,

        IA_MASK = 0xC0,
        IA_NONE = 0x00,
        IA_ANY  = 0x40,
        IA_THIS = 0x80,
        IA_OFF  = 6
    });
    mixin FlagProperty!(EXECUTE, "executable");
    mixin FlagProperty!(READ, "readable");
    mixin FlagProperty!(WRITE, "writable");


    static enum Arg : size_t
    {
        None,
        Any,
        This
    }


    package @safe this(MString name, MObject owner, MInt flags, MInt preposition) pure nothrow
    {
        this.name           = name;
        this.owner          = owner;
        this.flags          = flags;
        this.preposition    = preposition;
    }


    package {
        MString name            ;
        MObject owner           = null;
        MInt    preposition     ;
        MString source          ;
    }


    @property @safe Arg directObject() const pure nothrow
    {
        return cast(Arg) ((flags & DA_MASK) >>> DA_OFF);
    }


    @property @safe Arg indirectObject() const pure nothrow
    {
        return cast(Arg) ((flags & IA_MASK) >>> IA_OFF);
    }
}


/*
 *
 */
@safe MString normalize(MString str)
{
    static import std.uni;

    return std.uni.normalize!(std.uni.NFKC)(str);
}


/*
 *
 */
private mixin template Flags(string Init, string Members)
{
    mixin(`
        static enum : size_t
        {
            `~ Members ~`
        }
    `);


    package size_t flags = mixin(Init);


    package @safe bool checkFlag(size_t f) const pure nothrow
    {
        return (flags & f) != 0;
    }


    package @safe void setFlag(size_t f) pure nothrow
    {
        flags |= f;
    }


    package @safe void unsetFlag(size_t f) pure nothrow
    {
        flags &= ~f;
    }
}


/*
 *
 */
private mixin template FlagProperties(F...)
{
    static if (F.length != 0)
    {
        import std.string : toUpper;

        mixin FlagProperty!(mixin(F[0].toUpper), F[0]);
        mixin FlagProperties!(F[1 .. $]);
    }
}


/*
 *
 */
private mixin template FlagProperty(alias Flag, string Name)
{
    mixin(q{
        @property @safe bool }~Name~q{() const pure nothrow
        {
            return checkFlag(Flag);
        }


        package @property @safe bool }~Name~q{(bool value) pure nothrow
        {
            if (value)
            {
                setFlag(Flag);
            }
            else
            {
                unsetFlag(Flag);
            }
            return value;
        }
    });
}

