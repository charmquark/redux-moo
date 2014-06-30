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
module moo.db.load_remoo;

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
    log("Will load ReduxMOO database from %s", file.name);
    auto lines = file.byLine;
    Loader!(typeof(lines))(lines).load();
    log("Finished reading database");
}


/**
 *  ReduxMOO loader implementation.
 */
private struct Loader(R)
if (isInputRange!R && isSomeString!(ElementType!R))
{
    R source;


    @trusted this(R source)
    {
        this.source = source;
    }


    @safe void load()
    {
    }
}

