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
 *
 */
module moo.db.types;


/**
 * 
 */
alias MFloat    = double    ;
alias MInt      = long      ;
alias MList     = MValue[]  ;
alias MString   = dstring   ;


/**
 * 
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
 *
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


    package {
        MInt                    id          ;
        MObject                 child       ;
        MObject                 content     ;
        MObject                 location    ;
        MString                 name        ;
        MObject                 next        ;
        MObject                 owner       ;
        MObject                 parent      ;
        MProperty[MSymbol]      properties  ;
        MObject                 sibling     ;
        MVerb[]                 verbs       ;
    }


    package @safe this(MInt id) pure nothrow
    {
        this.id = id;
    }


    package @safe this(MInt id, MObject parent, MString name) pure nothrow
    {
        this.id     = id;
        this.parent = parent;
        this.name   = name;
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


    @safe inout(MVerb) selectVerb(MInt vid) inout nothrow
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


    static @trusted MSymbol opIndex ( MString str )
    {
        str = normalize( str );
        auto h = moo.hash.hash( str );
        auto sym = registry.get( h, new MSymbol( str, h ) );
        return sym;
    }


    @safe @property MHash hash () const
    {
        return _hash;
    }


    @safe @property MString text () const pure nothrow
    {
        return _text;
    }


    @safe int opCmp ( const( MSymbol ) other ) const pure nothrow
    {
        return (
            _hash < other._hash
            ? -1
            : (
                _hash > other._hash
                ? 1
                : 0
            )
        );
    }


    @safe bool opEquals ( const( Object ) other ) const pure nothrow
    {
        auto tmp = cast( const( MSymbol ) ) other;
        return tmp !is null ? opEquals( tmp ) : false;
    }


    @safe bool opEquals ( const( MSymbol ) other ) const pure nothrow
    {
        return this is other;
    }


    private:


    static MSymbol[ MHash ] registry;


    MString _text   ;
    MHash   _hash   ;


    @safe this ( MString str, MHash h )
    {
        _text = str;
        _hash = h;
        registry[ h ] = this;
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


    static @safe MValue Clear () nothrow
    {
        MValue result;
        result.type = MType.Clear;
        result.i = 0;
        return result;
    }


    static @safe MValue Obj ( MInt val ) nothrow
    {
        MValue result;
        result.type = MType.Obj;
        result.i = val;
        return result;
    }


    @safe this ( MInt val ) pure nothrow
    {
        type = MType.Int;
        i = val;
    }


    @safe this ( MString val ) pure nothrow
    {
        type = MType.String;
        s = val;
    }


    @safe this ( MError val ) pure nothrow
    {
        type = MType.Err;
        e = val;
    }


    @safe this ( const( MList ) val ) pure
    {
        type = MType.List;
        l = val.dup;
    }


    @safe this ( MFloat val ) pure nothrow
    {
        type = MType.Float;
        f = val;
    }


    @safe this ( MSymbol val ) nothrow
    {
        type = MType.Symbol;
        y = val;
    }


    @safe this ( MObject val ) nothrow
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

