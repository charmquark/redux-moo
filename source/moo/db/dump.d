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
    Dumper(file).dump();
    log("Finished writing database.");
}


private struct Dumper
{
    import  std.conv    ;

    import  std.format  : formattedWrite, text;


    this(File dest)
    {
        this.dest = dest;
    }


    File dest;


    void dump()
    {
        dumpHeader();
        dumpSymbols();
        dumpObjects();
        dumpTasks();
    }


    void dumpHeader()
    {
        dest.rawWrite("rxdb");              // tag
        dest.rawWrite([cast(uint) 1]);      // format version
        writeSize(maxValidObjectID + 1);    // world reserve
    }


    void dumpObjects()
    {
        dest.rawWrite("----objs");
        foreach (const obj; allObjects)
        {
            dest.rawWrite("cont");
            dest.rawWrite([obj.id]);
            writeString(obj.name);
            dest.rawWrite([obj.flags]);
            writeObjectRef(obj.owner, obj.parent, obj.child, obj.sibling, obj.location, obj.content, obj.next);
            dumpProperties(obj);
            dumpVerbs(obj);
        }
        dest.rawWrite("stop");
    }


    void dumpProperties(in MObject obj)
    {
        writeSize(obj.properties.length);
        foreach (const label, const ref prop; obj.properties)
        {
            dest.rawWrite([label.hash]);
            dest.rawWrite([prop.flags]);
            writeObjectRef(prop.owner);
            writeValue(prop.value);
        }
    }


    void dumpSymbols()
    {
        auto reg = MSymbol.registry;
        dest.rawWrite("----syms");
        writeSize(reg.length);
        foreach (const h, const s; reg)
        {
            dest.rawWrite([h]);
            writeString(s.text);
        }
    }


    void dumpTasks()
    {
        dest.rawWrite("----tasks");
        dest.rawWrite("stop");
    }


    void dumpVerbs(in MObject obj)
    {
        writeSize(obj.verbs.length);
        foreach (const ref verb; obj.verbs)
        {
            writeString(verb.name);
            dest.rawWrite([verb.flags, verb.preposition]);
            writeObjectRef(verb.owner);
            writeString(verb.source);
        }
    }


    void writeObjectRef(in MObject[] refs...)
    {
        import  std.algorithm   ;

        import  std.array       : array;

        dest.rawWrite(refs.map!(x => x is null ? -1 : x.id).array);
    }


    void writeSize(in MInt sz)
    {
        dest.rawWrite([sz]);
    }


    void writeSize(in size_t sz)
    {
        dest.rawWrite([sz.to!MInt]);
    }


    void writeString(in dstring str)
    {
        writeString(str.to!string);
    }


    void writeString(in string str)
    {
        dest.rawWrite([str.length.to!uint]);
        dest.rawWrite(str);
    }


    void writeValue(in ref MValue val)
    {
        dest.rawWrite([val.type]);
        switch (val.type) with (MType)
        {
            case Int:
            case Obj:
                dest.rawWrite([val.i]);
                break;

            case String:
                writeString(val.s);
                break;

            case Err:
                dest.rawWrite([val.e]);
                break;

            case List:
                writeSize(val.l.length);
                foreach (const ref elem; val.l)
                {
                    writeValue(elem);
                }
                break;

            case Float:
                dest.rawWrite([val.f]);
                break;

            case Symbol:
                dest.rawWrite([val.y.hash]);
                break;

            case ObjRef:
                writeObjectRef(val.o);
                break;

            default:
        }
    }
}