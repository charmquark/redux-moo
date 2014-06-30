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

import  std.range   ;
import  std.traits  ;
import  moo.log     ;

import  std.stdio : File;


/**
 *  Loader driver function.
 *
 *  Params:
 *      file    = source file
 */
package void load(ref File file)
in
{
    assert( file.isOpen );
}
body
{
    log("Will load LambdaMOO database from %s", file.name);
    auto lines = file.byLine;
    Loader!(typeof(lines))(lines).load();
    log("Finished reading database");
}


/**
 *  LambdaMOO loader implementation.
 */
private struct Loader(R)
if (isInputRange!R && isSomeString!(ElementType!R))
{
    import  std.conv        ;
    import  moo.db          ;
    import  moo.exception   ;

    import  std.array   : Appender, appender;
    import  std.format  : formattedRead;
    import  std.string  : format;


    R               source      = void; /// source input
    MSymbol[][]     definitions ;       /// property definition cache
    MInt            numObjects  ;       /// number of objects in the database
    MInt            numPrograms ;       /// number of verb programs in the database
    MObject[]       players     ;       /// player objects according to database header
    MProperty[][]   values      ;       /// property value cache


    /**
     *  Constructor
     *
     *  Params:
     *      source = input source
     */
    @trusted this(R source)
    {
        this.source = source;
    }


    /**
     *  Map properties onto their respective objects with the appropriate labels. This is done in a
     *  funky way because the Lambda database format assumes things about how properties are kept in
     *  memory, which are no longer true in Redux.
     *
     *  See_Also: loadProperties
     */
    @safe void applyProperties()
    {
        log("Applying properties to objects (Lambda conversion)");
        MObject[] tree;
        MSymbol[] list;
        foreach (id; 0 .. numObjects)
        {
            if (auto obj = getObject(id))
            {
                foreach (x; obj.inheritanceHierarchy)
                {
                    tree ~= x;
                }
                foreach_reverse (x; tree)
                {
                    list ~= definitions[x.id];
                }
                foreach (i, x; values[id])
                {
                    obj.properties[list[i]] = x;
                }
                tree.length = 0;
                list.length = 0;
            }
        }
    }


    /**
     *  Perform the loading procedure... pure madness.
     */
    @safe void load()
    {
        loadHeader();
        loadObjects();
        loadPrograms();
        applyProperties();
    }


    /**
     *  Load the database header.
     */
    @safe void loadHeader()
    {
        numObjects = readSize();
        definitions.length = numObjects;
        values.length = numObjects;
        numPrograms = readSize();
        readLine(); // skip unused line
        players.length = readSize();
        foreach (ref elem; players)
        {
            getObject(readInt(), true);
        }
    }


    /**
     *  Load each object in the database.
     */
    @safe void loadObjects()
    {
        log("Reading %s objects.", numObjects);
        expandDatabase(numObjects);
        foreach(objiter; 0 .. numObjects)
        {
            auto obj = readObjectHeader();
            obj.name = readString();
            readLine(); // this line is always blank

            obj.flags       = readInt();
            obj.owner       = readObjectRef();
            obj.location    = readObjectRef();
            obj.content     = readObjectRef();
            obj.next        = readObjectRef();
            obj.parent      = readObjectRef();
            obj.child       = readObjectRef();
            obj.sibling     = readObjectRef();

            loadVerbs(obj);
            loadProperties(obj);
        }
    }


    /**
     *  Load each verb program in the database.
     */
    @safe void loadPrograms()
    {
        log(`Reading %s verb programs.`, numPrograms);
        foreach (progiter; 0 .. numPrograms)
        {
            auto verb = readProgramHeader();
            typeof(readLine()) buf;
            auto program = appender!MString();
            for (buf = readLine(); buf != "."; buf = readLine())
            {
                program.put(buf);
                program.put('\n');
            }
            verb.source = program.data;
        }
    }


    /**
     *  Load property definitions and values for the given object. These are cached for now, since
     *  we have to funky stuff to map them onto their object appropriately, and we can't do that
     *  until we have the whole database loaded.
     *
     *  Params:
     *      obj = the object we are concerned with
     *
     *  See_Also: applyProperties
     */
    @safe void loadProperties(MObject obj)
    in
    {
        assert(obj !is null);
    }
    body
    {
        definitions[obj.id].length = readSize();
        foreach (ref elem; definitions[obj.id])
        {
            elem = MSymbol[readString()];
        }

        values[obj.id].length = readSize();
        foreach (ref elem; values[obj.id])
        {
            elem.value  = readValue();
            elem.owner  = readObjectRef();
            elem.flags  = readInt();
        }
    }


    /**
     *  Load verb signatures for the given object. Their programs come later.
     *
     *  Params:
     *      obj = the object we are concerned with
     */
    @safe void loadVerbs(MObject obj)
    in
    {
        assert(obj !is null);
    }
    body
    {
        obj.verbs.length = readSize();
        foreach (ref elem; obj.verbs)
        {
            auto name           = readString();
            auto owner          = readObjectRef();
            auto flags          = readInt();
            auto preposition    = readInt();
            elem = new MVerb(name, owner, flags, preposition);
        }
    }


    /**
     *  Read a value of type T from the source.
     *
     *  Returns: the converted value.
     */
    @safe T read(T)()
    {
        return readLine().to!T();
    }


    alias readInt       = read!MInt     ;   /// ditto
    alias readFloat     = read!MFloat   ;   /// ditto
    alias readSize      = read!size_t   ;   /// ditto
    alias readString    = read!MString  ;   /// ditto


    /**
     *  Read the next line from the source.
     *
     *  Returns: a const view of the line.
     *
     *  Throws: ExitCodeException if the source is empty.
     */
    @trusted const(char)[] readLine()
    {
        // we can begin with a pop front and avoid unnecessary .dup's because there is a skippable
        // line at the beginning of a lambda db file
        source.popFront();
        exitCodeEnforce!`InvalidDb`(!source.empty, "Unexpected end of database file");
        return source.front;
    }


    /**
     *  Read an object header: #id and optional recycled tag.
     *
     *  Returns: the appropriate object, or null if it is recycled.
     *
     *  Throws: ExitCodeException if the header is invalid in any way.
     */
    @trusted MObject readObjectHeader()
    {
        import std.algorithm : endsWith;

        auto buf = readLine();
        if (buf.endsWith(" recycled"))
        {
            return null;
        }
        MInt id;
        exitCodeEnforce!`InvalidDb`(buf.formattedRead(`#%d`, &id) == 1, "Invalid object header in database: " ~ buf);
        auto obj = getObject(id, true);
        obj.recycled = false;
        return obj;
    }


    /**
     *  Reads an object #id from the database file, and fetches the identified object.
     *
     *  Returns: a reference to a database object.
     */
    @safe MObject readObjectRef()
    {
        return getObject(readInt(), true);
    }


    /**
     *  Read a program header (#od:vid).
     *
     *  Returns: the appropriate verb.
     *
     *  Throws: ExitCodeException if the header is invalid in any way.
     */
    @trusted MVerb readProgramHeader()
    {
        auto buf = readLine();
        MInt oid;
        MInt vid;
        exitCodeEnforce!`InvalidDb`(buf.formattedRead(`#%d:%d`, &oid, &vid) == 2, "Invalid program header in database: " ~ buf);
        auto obj = exitCodeEnforce!`InvalidDb`(getObject(oid), "Program found for verb on nonexistant object #%d:%d".format(oid, vid));
        auto verb = exitCodeEnforce!`InvalidDb`(obj.getVerb(vid), "Program found for nonexistant verb #%d:%d".format(oid, vid));
        return verb;
    }


    /**
     *  Read a MOO value from the database.
     *
     *  Returns: an instance of MValue containing the value
     *
     *  Throws: ExitCodeException on an invalid/unrecognized datatype
     */
    @safe MValue readValue()
    {
        switch (readInt().to!MType()) with (MType)
        {
            case Int    : return MValue(readInt());
            case Obj    : return MValue(readObjectRef());
            case String : return MValue(readString());
            case Err    : return MValue(readInt().to!MError());
            case Clear  : return MValue.Clear();
            case Float  : return MValue(readFloat());

            case List:
                auto data = new MList(readSize());
                foreach (ref elem; data)
                {
                    elem = readValue();
                }
                return MValue(data);

            default:
                throw new ExitCodeException(ExitCode.InvalidDb, "Malformed property value type");
        }
    }
}

