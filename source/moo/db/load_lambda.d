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
 *  Loads and converts a LambdaMOO database.
 */
module moo.db.load_lambda;

import std.range;
import std.traits;
import std.stdio : File;


/**
 *  Loader driver function.
 *
 *  Params:
 *      file    = source file
 */
void load ( ref File file )
in {
    assert( file.isOpen );
}
body {
    auto lines = file.byLine;
    Loader!( typeof( lines ) ) loader;
    loader.src = lines;
    loader.load();
}


//--------------------------------------------------------------------------------------------------
private:


/**
 *  LambdaMOO loader implementation.
 */
struct Loader ( R )
if ( isInputRange!R && isSomeString!( ElementType!R ) )
{
    import std.conv;
    import std.format : formattedRead;

    import moo.types;
    import moo.db.types;
    import db  = moo.db ;
    import log = moo.log;


    R                   src         ; /// source input
    MSymbol[][ MInt ]   defCache    ; /// property definition cache
    MProperty[][ MInt ] valueCache  ; /// property value cache (values include owner/perms as well)


    /**
     *  Map properties to their respective objects. This is done in a funky way because the
     *  LambdaMOO database format is based around some assumptions about ordering, and those
     *  assumptions do not hold under ReduxMOO.
     *
     *  Params:
     *      objectCount = number of objects to seek properties for; we use this rather than relying
     *          on the cache keys because, contrary to popular belief, MOO does not actually dictate
     *          a strict hierarchy
     */
    @safe void applyProperties ( MInt objectCount ) nothrow
    {
        MObject*[] tree;
        MSymbol[] defs;

        ulong total = 0;
        foreach ( oid ; 0 .. objectCount ) {
            auto obj = db.unsafeSelect( oid );
            if ( obj == null || obj.recycled ) {
                continue;
            }

            for ( auto o = obj ; o != null ; o = o.parent ) {
                tree ~= o;
            }
            foreach_reverse ( o ; tree ) {
                defs ~= defCache[ o.id ];
            }
            foreach ( i, ref x ; valueCache[ oid ] ) {
                obj.properties[ defs[ i ] ] = x;
                ++total;
            }

            tree.length = 0;
            defs.length = 0;
        }
        log.info( `Applied %d properties.`, total );
    }


    /**
     *
     */
    @safe void load ()
    {
        nextLine();                     // skip metaline
        auto objectCount = readSize();
        auto programCount = readSize();
        nextLine();                     // skip meaningless line

        auto playerCount = readSize();
        auto playerIds = new MInt[]( playerCount );
        foreach ( ref elem ; playerIds ) {
            elem = readInt();
        }

        log.info( `Reading %s objects.`, objectCount );
        db.reserve( objectCount );
        foreach ( i ; 0 .. objectCount ) {
            loadObject();
        }

        log.info( `Reading %s verb programs.`, programCount );
        foreach ( i ; 0 .. programCount ) {
            loadProgram();
        }

        log.info( `Applying properties to objects (Lambda conversion)` );
        applyProperties( objectCount );

        log.info( `Finished reading database` );
    }


    /**
     *
     */
    @trusted void loadObject ()
    {
        auto buf = nextLine();
        MInt oid;
        buf.formattedRead( `#%d`, &oid );
        auto obj = db.unsafeSelect( oid );
        obj.id = oid;
        if ( buf.length > 10 && buf[ $ - 8 .. $ ] == `recycled` ) {
            return;
        }

        obj.recycled = false;
        obj.name = readString();
        nextLine(); // this line is always blank
        loadObjectFlags( obj );
        obj.owner       = readObjRef();
        obj.location    = readObjRef();
        obj.content     = readObjRef();
        obj.next        = readObjRef();
        obj.parent      = readObjRef();
        obj.child       = readObjRef();
        obj.sibling     = readObjRef();

        foreach ( i ; 0 .. readSize() ) {
            obj.add( loadVerb() );
        }
        loadProperties( oid );
    }


    /**
     *
     */
    @safe void loadObjectFlags ( MObject* obj )
    {
        enum {
            PLAYER     = 0x01,
            PROGRAMMER = 0x02,
            WIZARD     = 0x04,
            READ       = 0x10,
            WRITE      = 0x20,
            FERTILE    = 0x80
        }

        auto flags = readFlags();
        obj.player      = ( flags & PLAYER     ) != 0;
        obj.programmer  = ( flags & PROGRAMMER ) != 0;
        obj.wizard      = ( flags & WIZARD     ) != 0;
        obj.readable    = ( flags & READ       ) != 0;
        obj.writable    = ( flags & WRITE      ) != 0;
        obj.fertile     = ( flags & FERTILE    ) != 0;
    }


    /**
     *
     */
    @trusted void loadProgram ()
    {
        import std.array  : Appender;
        import std.format : formattedRead;
        import std.string : format;

        import moo.exception;

        static Appender!MString source;

        MInt    oid;
        size_t  vid;
        auto buf = readString();
        formattedRead( buf, `#%d:%d`, &oid, &vid );
        auto verb = exitCodeEnforce!`InvalidDb`(
            db.unsafeSelectVerb( oid, vid ),
            `Program listing found for nonexistant verb #%d:%d`.format( oid, vid )
        );
        for ( buf = readString() ; buf != "."d; buf = readString() ) {
            source.put( buf );
            source.put( '\n' );
        }
        verb.source = source.data;
        source.clear();
    }


    /**
     *
     */
    @safe void loadProperties ( MInt oid )
    {
        auto defs = new MSymbol[]( readSize() );
        foreach ( ref elem ; defs ) {
            elem = MSymbol[ readString() ];
        }
        defCache[ oid ] = defs;

        enum {
            READ    = 0x01,
            WRITE   = 0x02,
            CHOWN   = 0x04
        }
        auto vals = new MProperty[]( readSize() );
        foreach ( ref elem ; vals ) {
            elem.value = readValue();
            elem.owner = readObjRef();
            auto flags = readFlags();
            elem.readable   = ( flags & READ  ) != 0;
            elem.writable   = ( flags & WRITE ) != 0;
            elem.chownable  = ( flags & CHOWN ) != 0;
        }
        valueCache[ oid ] = vals;
    }


    /**
     *
     */
    @safe MVerb loadVerb ()
    {
        import std.conv;

        enum {
            READ    = 0x01,
            WRITE   = 0x02,
            EXEC    = 0x04,

            DA_MASK = 0x30,
            DA_NONE = 0x00,
            DA_ANY  = 0x10,
            DA_THIS = 0x20,

            IA_MASK = 0xC0,
            IA_NONE = 0x00,
            IA_ANY  = 0x40,
            IA_THIS = 0x80
        }

        MVerb vb;
        vb.name = readString();
        vb.owner = readObjRef();
        auto flags = readFlags();
        vb.readable         = ( flags & READ  ) != 0;
        vb.writable         = ( flags & WRITE ) != 0;
        vb.executable       = ( flags & EXEC  ) != 0;
        vb.directObject     = to!MVerbArgument( ( flags & DA_MASK ) / DA_ANY );
        vb.indirectObject   = to!MVerbArgument( ( flags & IA_MASK ) / IA_ANY );
        vb.preposition      = readInt();
        return vb;
    }


    /**
     *
     */
    @trusted const( char )[] nextLine ()
    {
        import moo.exception;

        exitCodeEnforce!`InvalidDb`( !src.empty, `Unexpected end of database file` );
        auto result = src.front.dup;
        src.popFront();
        return result;
    }


    /**
     *
     */
    @safe T read ( T ) ()
    {
        return nextLine.to!T();
    }


    /**
     *
     */
    alias readFlags     = read!ubyte    ;
    alias readInt       = read!MInt     ;
    alias readSize      = read!size_t   ;
    alias readString    = read!MString  ;


    /**
     *
     */
    @safe MObject* readObjRef ()
    {
        return db.unsafeSelect( readInt() );
    }


    /**
     *
     */
    @safe MValue readValue ()
    {
        import std.conv;
        import moo.exception;

        MValue result;
        auto t = readInt().to!MType();
        final switch ( t ) with ( MType ) {
            case Int    : result = MValue( readInt() );             break;
            case Obj    : result = MValue.obj( readInt() );         break;
            case String : result = MValue( readString() );          break;
            case Err    : result = MValue( readInt().to!MError() ); break;
            case Clear  : result = MValue.clear();                  break;
            case Float  : result = MValue( read!MFloat() );         break;

            case List:
                result.type = List;
                auto data = new MList( readSize() );
                foreach ( ref elem ; data ) {
                    elem = readValue();
                }
                result.l = data;
                break;

            case None       : goto case;
            case Catch      : goto case;
            case Finally    : goto case;
            case Symbol     :
            //default         :
                throw new ExitCodeException( ExitCode.InvalidDb, `Malformed property value` );
        }
        return result;
    }


} // end Loader

