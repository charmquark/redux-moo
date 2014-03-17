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
module moo.db.verb;

import moo.db.object;
import moo.patterns.properties;


/**
 *  
 */
enum VerbFlags : ubyte {
    Read       = 0x01, // read perm
    Write      = 0x02, // write/compile perm
    Execute    = 0x04, // execute perm
    Debug      = 0x08, // debug perm

    DOBJ_MASK  = 0x30, // direct object flags mask
    DObjNone   = 0x00, // direct object arg 'none'
    DObjAny    = 0x10, // direct object arg 'any'
    DObjThis   = 0x20, // direct object arg 'this'

    IOBJ_MASK  = 0xC0, // indirect object flags mask
    IObjNone   = 0x00, // indirect object arg 'none'
    IObjAny    = 0x40, // indirect object arg 'any'
    IObjThis   = 0x80, // indirect object arg 'this'
}


/**
 *  
 */
final class Verb {


    private {
        VerbFlags   _flags  ;
        string      _name   ;
        MObject     _owner  ;
        long        _prep   ;
        string      _source ;
    }


    //============================================================================================
    package:


    /**
     *
     */
    this ( string nm ) {
        _name = nm;
    }


    /**
     *
     */
    const pure nothrow @property @safe
    string name () {
        return _name;
    }


    /**
     *
     */
    const pure nothrow @property @safe
    string source () {
        return _source;
    }


    /**
     *
     */
    pure nothrow @property @safe
    string source ( string val ) {
        return _source = val;
    }


    /**
     *
     */
    mixin SimpleSettorGroup!( _flags, _name, _owner, _prep, _source );


} // end Verb

