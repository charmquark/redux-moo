/*//////////////////////////////////////////////////////////////////////////////////////////////////
////                                                                                            ////
////    Copyright 2013 Christopher Nicholson-Sauls                                              ////
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
module moo.db.lambda_loader;

import moo.db;
import moo.db.loader;
import moo.log;
import moo.types;


//==================================================================================================
package:


/**
 *
 */
final class LambdaLoader : Loader {


    private {
        Logger              log         ;
        ByLineRange         source      = void;
        Property[][ long ]  valCache    ;
    }


    /**
     *
     */
    this ( ref File file ) {
        log = Logger( `lambda loader` );
        source = file.byLine();
    }


    /**
     *
     */
    void load () {
        nextLine(); // skip metaline
        auto objectCount = nextInt();
        auto programCount = nextInt();
        nextLine(); // meaningless line

        auto playerCount = nextInt();
        auto playerIds = new long[]( playerCount );
        foreach ( ref elem ; playerIds )
            elem = nextInt();

        log( `Reading %s objects.`, objectCount );
        db_reserve( objectCount );
        foreach ( i ; 0 .. objectCount )
            loadObject();

        log( `Reading %s verb programs.`, programCount );
        foreach ( i ; 0 .. programCount )
            loadProgram();

        applyValues( objectCount );
    }


    //============================================================================================
    private:


    /**
     *
     */
    void applyValues ( long objectCount ) {
        foreach ( oid ; 0 .. objectCount ) {
            auto obj = db_select( oid );
            if ( obj !is null ) {
                auto vals = valCache[ oid ];
            }
            //TODO
        }
    }
/+
        MObject obj;

        foreach ( oid ; 0 .. numObjects )
        {
            obj = Database.select( oid );
            if ( obj !is null )
            {
                auto defs = obj.properties;
                auto vals = objVals[ oid ];
                if ( defs.length != vals.length )
                {
                    throw new DatabaseException( format(
                        "Object #%d: number of property values (%d) does not match number of properties (%d)",
                        oid, vals.length, defs.length
                    ) );
                }

                foreach ( i, d ; defs )
                {
                    obj._values[ d.hash ] = vals[ i ];
                }
            }
        }
+/

    /**
     *
     */
    void loadObject () {
        import std.format : formattedRead;
        import std.string : format;

        auto buf = nextLine();
        long oid;
        buf.formattedRead( "#%d", &oid );
        if ( buf.length > 10 && buf[ $ - 8 .. $ ] == `recycled` ) {
            db_unsafeRecycle( oid );
            return;
        }

        auto obj = db_select( oid );
        obj.name = nextString();
        nextLine(); // always blank
        obj.flags       = next!ObjFlags();
        obj.owner       = nextObjRef();
        obj.location    = nextObjRef();
        obj.content     = nextObjRef();
        obj.next        = nextObjRef();
        obj.parent      = nextObjRef();
        obj.child       = nextObjRef();
        obj.sibling     = nextObjRef();

        auto verbCount = nextInt();
        foreach ( i ; 0 .. verbCount )
            obj.addVerb( loadVerb() );

        auto defCount = nextInt();
        foreach ( i ; 0 .. defCount )
            obj.addDefinition( Symbol[ nextString() ] );

        valCache[ oid ].length = nextInt();
        foreach ( idx, ref elem ; valCache[ oid ] ) {
            elem.value  = nextValue();
            elem.owner  = nextValidObjRef( `Invalid property value owner in #%d, index %d`.format( oid, idx ) );
            elem.flags  = next!PropFlags();
        }
    }


    /**
     *
     */
    void loadProgram () {
        import moo.exception;
        import std.array  : Appender        ;
        import std.format : formattedRead   ;
        import std.string : format          ;

        static Appender!string source;

        long    oid ;
        size_t  vid ;
        auto buf = nextLine();
        formattedRead( buf, `#%d:%d`, &oid, &vid );
        auto verb = exitCodeEnforce!`INVALID_DB`( db_select_verb( oid, vid ), `Program listing found for nonexistant verb #%d:%d`.format( oid, vid ) );
        for ( buf = nextLine() ; buf != `.` ; buf = nextLine() ) {
            source.put( buf );
            source.put( "\n" );
        }
        verb.source = source.data;
        source.clear();
    }


    /**
     *
     */
    Verb loadVerb () {
        import std.string : format;

        auto name = nextString();
        auto verb = new Verb( name );
        verb.owner = nextValidObjRef( `Invalid owner for verb "%s"`.format( name ) );
        verb.flags = next!VerbFlags();
        verb.prep = nextInt();
        return verb;
    }


    /**
     *
     */
    T next ( T ) () {
        import std.conv;

        static if ( is( T == ObjFlags ) || is( T == PropFlags ) || is( T == VerbFlags ) ) {
            return cast( T ) nextLine().to!ubyte();
        }
        else {
            return nextLine().to!T();
        }
    }

    alias nextInt       = next!long     ;
    alias nextFloat     = next!double   ;
    alias nextString    = next!string   ;
    // We use next to read strings, rather than use the value of source.front directly, because
    // File.byLine will reuse its internal buffer, obliterating any data we were using.  Calling
    // to!string on it produces a safe copy.


    /**
     *
     */
    char[] nextLine () {
        import moo.exception;

        exitCodeEnforce!`INVALID_DB`( !source.empty, `Unexpected end of database file.` );
        auto result = source.front.dup;
        source.popFront();
        return result;
    }


    /**
     *
     */
    MObject nextObjRef () {
        return db_select( nextInt() );
    }


    /**
     *
     */
    Value nextValue () {
        import moo.exception;

        final switch ( next!Type() ) with ( Type ) {
            case Int    : return Value( nextInt() );
            case Obj    : return Value.obj( nextInt() );
            case Str    : return Value( nextString() );
            case Err    : return Value( cast( MError ) nextInt() );
            case Clear  : return Value.clear();
            case Float  : return Value( nextFloat() );

            case List:
                Value val;
                val.type = List;
                val.l = new MList( nextInt() );
                foreach ( ref elem ; val.l ) {
                    elem = nextValue();
                }
                return val;

            case None       :
            case Catch      :
            case Finally    :
            case Symbol     :
            case ObjRef     :
            //default:
                throw new ExitCodeException( ExitCode.INVALID_DB, `Malformed property value.` );
        }
    }


    /**
     *
     */
    MObject nextValidObjRef ( lazy string msg ) {
        import moo.exception;

        return exitCodeEnforce!`INVALID_DB`( nextObjRef(), msg );
    }


} // end LambdaLoader