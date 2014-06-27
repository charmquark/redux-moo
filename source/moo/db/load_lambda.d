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

    import moo.log;
    import moo.db.types;

    import db = moo.db ;


    R                   src         ; /// source input
    MSymbol[][MInt]     defCache    ; /// property definition cache
    MProperty[][MInt]   valueCache  ; /// property value cache (values include owner/perms as well)


    /**
     *  Map properties to their respective objects. This is done in a funky way because the
     *  LambdaMOO database format is based around some assumptions about ordering, and those
     *  assumptions do not hold under ReduxMOO.
     *
     *  See_Also: loadProperties
     *
     *  Params:
     *      objectCount = number of objects to seek properties for; we use this rather than relying
     *          on the cache keys because, contrary to popular belief, MOO does not actually dictate
     *          a strict hierarchy
     */
    @safe void applyProperties(MInt objectCount) nothrow
    {
        MObject[] tree;
        MSymbol[] defs;

        ulong total = 0;
        foreach (oid; 0 .. objectCount) {
            auto obj = db.mutableSelect(oid);
            if (obj is null)
            {
                continue;
            }
            foreach (x; obj.inheritanceHierarchy)
            {
                tree ~= x;
            }
            foreach_reverse (x; tree)
            {
                defs ~= defCache[x.id];
            }
            foreach (i, x; valueCache[oid])
            {
                obj.properties[defs[i]] = x;
                ++total;
            }
            tree.length = 0;
            defs.length = 0;
        }
        log( `Applied %d properties.`, total );
    }


    /**
     *  Run the loading procedure. Pure madness.
     */
    @safe void load()
    {
        nextLine();                     // skip metaline
        auto objectCount = readSize();
        auto programCount = readSize();
        nextLine();                     // skip meaningless line

        auto playerCount = readSize();
        auto playerIds = new MInt[]( playerCount );
        foreach (ref elem; playerIds)
        {
            elem = readInt();
        }

        log(`Reading %s objects.`, objectCount);
        db.reserve(objectCount);
        foreach (i; 0 .. objectCount)
        {
            loadObject();
        }

        log(`Reading %s verb programs.`, programCount);
        foreach (i; 0 .. programCount)
        {
            loadProgram();
        }

        log(`Applying properties to objects (Lambda conversion)`);
        applyProperties(objectCount);

        log(`Finished reading database`);
    }


    /**
     *  Load an object, if it is valid (ie, not recycled).
     */
    @trusted void loadObject()
    {
        auto buf = nextLine();
        if (buf.length > 10 && buf[$ - 8 .. $] == `recycled` )
        {
            return;
        }
        MInt oid;
        buf.formattedRead(`#%d`, &oid);
        auto obj = db.mutableSelect(oid, true);

        obj.recycled    = false;
        obj.name        = readString();
        nextLine(); // this line is always blank
        obj.flags       = readFlags();

        obj.owner       = readObjRef();
        obj.location    = readObjRef();
        obj.content     = readObjRef();
        obj.next        = readObjRef();
        obj.parent      = readObjRef();
        obj.child       = readObjRef();
        obj.sibling     = readObjRef();

        foreach (i; 0 .. readSize())
        {
            obj.verbs ~= loadVerb();
        }
        loadProperties(oid);
    }


    /**
     *  Load a verb program.
     *
     *  Throws: an ExitCodeException if the verb cannot be found.
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
        formattedRead(buf, `#%d:%d`, &oid, &vid);
        auto verb = exitCodeEnforce!`InvalidDb`(
            db.mutableSelectVerb(oid, vid),
            `Program listing found for nonexistant verb #%d:%d`.format(oid, vid)
        );
        for (buf = readString(); buf != "."d; buf = readString())
        {
            source.put( buf );
            source.put( '\n' );
        }
        verb.source = source.data;
        source.clear();
    }


    /**
     *  Load and cache the properties of an object. We do this silliness because LambdaMOO and
     *  ReduxMOO handle properties differently.
     *
     *  See_Also: applyProperties
     *
     *  Params:
     *      oid = object #id whose properties we are reading
     */
    @safe void loadProperties(MInt oid)
    {
        auto defs = new MSymbol[](readSize());
        foreach (ref elem; defs )
        {
            elem = MSymbol[readString()];
        }
        defCache[oid] = defs;

        auto vals = new MProperty[](readSize());
        foreach (ref elem; vals)
        {
            elem.value = readValue();
            elem.owner = readObjRef();
            elem.flags = readFlags();
        }
        valueCache[oid] = vals;
    }


    /**
     *  Load a verb. As this is a LambdaMOO database, this does not include the verb's program.
     *
     *  Returns: the verb (duh).
     */
    @safe MVerb loadVerb()
    {
        auto vb = new MVerb;
        vb.name         = readString();
        vb.owner        = readObjRef();
        vb.flags        = readFlags();
        vb.preposition  = readInt();
        return vb;
    }


    /**
     *  Read the next line from the source file.
     *
     *  Returns: a const view of the source line.
     *
     *  Throws: an ExitCodeException if the source is empty.
     */
    @trusted const(char)[] nextLine()
    {
        import moo.exception;

        exitCodeEnforce!`InvalidDb`(!src.empty, `Unexpected end of database file`);
        auto result = src.front.dup;
        src.popFront();
        return result;
    }


    /**
     *  Read a value of type T from the source.
     *
     *  Returns: the read and converted value.
     */
    @safe T read(T)()
    {
        return nextLine.to!T();
    }


    alias readFlags     = read!size_t   ; /// convenience alias for read!T
    alias readInt       = read!MInt     ; /// ditto
    alias readSize      = read!size_t   ; /// ditto
    alias readString    = read!MString  ; /// ditto


    /**
     *  Reads an object #id from the source, and selects that object.
     *
     *  Returns: the selected object.
     */
    @safe MObject readObjRef()
    {
        return db.mutableSelect(readInt(), true);
    }


    /**
     *  Reads a MOO value from the database.
     *
     *  Returns: the value (c'mon, really).
     *
     *  Throws: an ExitCodeException if the value's type is malformed/unrecognized.
     */
    @safe MValue readValue()
    {
        import std.conv;
        import moo.exception;

        switch (readInt().to!MType()) with (MType) {
            case Int    : return MValue(readInt());
            case Obj    : return MValue.Obj(readInt());
            case String : return MValue(readString());
            case Err    : return MValue(readInt().to!MError());
            case Clear  : return MValue.Clear();
            case Float  : return MValue(read!MFloat());

            case List:
                auto data = new MList(readSize());
                foreach (ref elem; data)
                {
                    elem = readValue();
                }
                return MValue(data);

            default:
                throw new ExitCodeException( ExitCode.InvalidDb, `Malformed property value type` );
        }
    }


} // end Loader

