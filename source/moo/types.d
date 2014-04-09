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
module moo.types;

//import moo.db.object;


/**
 * 
 */
alias MFloat    = double    ;
alias MInt      = long      ;
alias MList     = Value[]   ;
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
enum Type : MInt
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
    Symbol/+,
    ObjRef+/
}


/**
 * 
 */
struct Value
{


    Type type = Type.None;


    union
    {
        MInt    i; // int, obj
        MString s; // string
        MError  e; // err
        MList   l; // list
        MFloat  f; // float
        MSymbol y; // symbol
        //MObject o; // objref
    }


    /**
     *
     */
    static @safe Value clear () nothrow
    {
        Value result;
        result.type = Type.Clear;
        result.i = 0;
        return result;
    }


    /**
     *
     */
    static @safe Value obj ( MInt val ) nothrow
    {
        Value result;
        result.type = Type.Obj;
        result.i = val;
        return result;
    }


    /**
     *
     */
    @safe this ( MInt val ) pure nothrow
    {
        type = Type.Int;
        i = val;
    }

    ///ditto
    @safe this ( MString val ) pure nothrow
    {
        type = Type.String;
        s = val;
    }

    ///ditto
    @safe this ( MError val ) pure nothrow
    {
        type = Type.Err;
        e = val;
    }

    ///ditto
    @safe this ( const( MList ) val ) pure
    {
        type = Type.List;
        l = val.dup;
    }

    ///ditto
    @safe this ( MFloat val ) pure nothrow
    {
        type = Type.Float;
        f = val;
    }

    ///ditto
    @safe this ( MSymbol val ) nothrow
    {
        type = Type.Symbol;
        y = val;
    }

    /+///ditto
    this ( MObject val ) pure
    {
        type = Type.ObjRef;
        o = val;
    }+/


    /**
     *
     */
    @safe ~this () pure nothrow
    {}


    /**
     *
     */
    @safe this ( const this ) nothrow
    {}


} // end Value


/**
 * 
 */
struct MSymbol
{
    static import moo.hash;


    /**
     *
     */
    alias MHash = moo.hash.MHash;


    /**
     *
     */
    static @trusted MSymbol opIndex ( MString str )
    {
        str = normalize( str );
        auto h = moo.hash.hash( str );
        auto sym = registry.get( h, createEntry( str, h ) );
        return MSymbol( sym );
    }


    /**
     *
     */
    @safe this ( this ) pure nothrow
    {
        ++entry.refs;
    }


    /**
     *
     */
    @safe ~this () nothrow
    {
        --entry.refs;
        if ( entry.refs == 0 ) {
            destroyEntry( entry );
        }
    }


    /**
     *
     */
    @safe @property MHash hash () const
    {
        return entry.hash;
    }


    /**
     *
     */
    @safe @property MString text () const pure nothrow
    {
        return entry.text;
    }


    /**
     *
     */
    @safe int opCmp ( ref const( MSymbol ) other ) const pure nothrow
    {
        return (
            entry.hash < other.entry.hash
            ? -1
            : (
                entry.hash > other.entry.hash
                ? 1
                : 0
            )
        );
    }


    /**
     *
     */
    @safe bool opEquals ( ) ( auto ref const( MSymbol ) other ) const pure nothrow
    {
        return entry == other.entry;
    }


    //------------------------------------------------------------------------------------------
    private:


    /**
     *
     */
    static Entry*[ MHash ] registry;


    /**
     *
     */
    static @safe Entry* createEntry ( MString str, MHash h ) nothrow
    out ( result ) {
        assert( result != null );
    }
    body {
        auto e = new Entry( str, h, 0 );
        registry[ h ] = e;
        return e;
    }


    /**
     *
     */
    static @safe void destroyEntry ( Entry* e ) nothrow
    in {
        assert( e != null );
    }
    body {
        registry.remove( e.hash );
        e.destroy();
    }


    /**
     *
     */
    static struct Entry
    {
        /**
         *
         */
        MString text;


        /**
         *
         */
        MHash hash;


        /**
         *
         */
        size_t refs = 0;
    }


    /**
     *
     */
    @safe this ( Entry* e ) pure nothrow
    {
        entry = e;
        ++entry.refs;
    }


    /**
     *
     */
    Entry* entry;


} // end MSymbol


/*
 *
 */
@safe MString normalize ( MString str )
{
    static import std.uni;

    return std.uni.normalize!( std.uni.NFKC )( str );
}

