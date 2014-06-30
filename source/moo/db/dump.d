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
module moo.db.dump;

import  std.range   ;
import  moo.db      ;
import  moo.log     ;

import  std.stdio : File;


/**
 *  
 */
void dump(ref File file)
in
{
    assert(file.isOpen);
}
body
{
    log("Will write database to %s", file.name);
    auto writer = file.lockingTextWriter();
    Dumper!(typeof(writer))(writer).dump();
    //writer.writeHeader();
    //writer.writeObjects();
    log("Finished writing database.");
}


private struct Dumper(R)
if (isOutputRange!(R, string))
{
    import  std.format : formattedWrite, text;


    this(R dest)
    {
        this.dest = dest;
    }


    R dest;


    void dump()
    {
        writeHeader();
        writeObjects();
    }


    string objectIDText(in MObject obj)
    {
        return text(obj is null ? -1 : obj.id);
    }


    void writeHeader()
    {
        dest.formattedWrite("#!remoo\n#rdb format 1.0\nworld size %d\n", maxValidObjectID + 1);
    }


    void writeObjectID(in MObject obj)
    {
        put(dest, objectIDText(obj));
    }


    void writeObjects()
    {
        import std.algorithm : map;

        foreach (const obj; allObjects)
        {
            // tag line
            dest.formattedWrite("\nobject %d %X \"%s\"\n", obj.id, obj.flags, obj.name);

            // hierarchies
            put(dest, "\t");
            writeObjectID(obj.parent);
            put(dest, " -- ");
            dest.formattedWrite(`%(%d%| %)`, obj.children.map!(x => x.id));
            put(dest, "\n\t");
            writeObjectID(obj.location);
            put(dest, " -- ");
            dest.formattedWrite(`%(%d%| %)`, obj.contents.map!(x => x.id));
            put(dest, "\n");

            // properties
            dest.formattedWrite("\t%d properties\n", obj.properties.length);
            foreach (label, const ref prop; obj.properties)
            {
                writeProperty(label, prop);
            }

            // verbs
            dest.formattedWrite("\t%d verbs\n", obj.verbs.length);
            foreach (const verb; obj.verbs)
            {
                writeVerb(verb);
            }

            put(dest, "end objects\n");
        }
    }


    void writeProperty(MSymbol label, in ref MProperty prop)
    {
        dest.formattedWrite("\t\t\"%s\" %s %X %s\n", label.text, objectIDText(prop.owner), prop.flags, prop.value.toLiteral(true, true));
    }


    void writeVerb(in MVerb verb)
    {
        import std.string : splitLines;

        auto code = verb.source.splitLines;
        dest.formattedWrite("\t\t\"%s\" %s %X %d %s\n", verb.name, objectIDText(verb.owner), verb.flags, verb.preposition, code.length);
        foreach (line; code)
        {
            put(dest, "\t\t\t");
            put(dest, line);
            put(dest, "\n");
        }
    }
}
/+

string flagsToString(in MObject obj)
{
    if (obj.flags == 0) return "-";
    if (obj.recycled    ) result ~= 'x';
    if (obj.fertile     ) result ~= 'f';
    if (obj.readable    ) result ~= 'r';
    if (obj.writable    ) result ~= 'w';
    if (obj.player      ) result ~= 'p';
    if (obj.programmer  ) result ~= 'c';
    if (obj.wizard      ) result ~= 'w';
    return result;
}


void writeHeader(T)(ref File file)
in
{
    assert(file.isOpen);
}
body
{
    file.writefln("#!remoo");
    file.writefln("#rdb format 1.0");
    file.writeln("world size ", maxValidObjectID + 1);
    file.writeln();
}


void writeObjects(ref File file)
in
{
    assert(file.isOpen);
}
body
{
    foreach (const obj; allObjects)
    {
        file.writefln(`object #%d %s`, obj.id, obj.name);
        file.writeln("\t", flagsToString(obj));
        file.write("\t#");
        if (auto parent = obj.parent)
        {
            file.write(parent.id);
        }
        else
        {
            file.write(-1);
        }
        file.write(" #");
        if (auto loc = obj.location)
        {
            file.write(
        }
        else
        {
            file.write(-1);
        }
        file.writeln();
    }
}


void writeObjectRef(ref File file, in MObject obj)
in
{
    assert(file.isOpen);
}
body
{
    file.write('#');
    if (obj !is null)
    {
        file.write(obj.id);
    }
    else
    {
        file.write(-1);
    }
}

+/