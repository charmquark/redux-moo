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
module moo.db.object;

import moo.types;
import moo.db.verb;
import moo.patterns.properties;


/**
 *  
 */
enum ObjFlags : ubyte {
    Player     = 0x01,
    Programmer = 0x02,
    Wizard     = 0x04,
    Read       = 0x10,
    Write      = 0x20,
    Fertile    = 0x80,
}


/**
 *  
 */
final class MObject
{


    private {
        MObject     _child      ;
        MObject     _content    ;
        Symbol[]    _defines    ;
        ObjFlags    _flags      ;
        MInt        _id         ;
        MObject     _location   ;
        string      _name       ;
        MObject     _next       ;
        MObject     _owner      ;
        MObject     _parent     ;
        MObject     _sibling    ;
        Verb[]      _verbs      ;
    }


    /**
     *
     */
    pure nothrow @property @safe
    string name () {
        return _name;
    }


    //==========================================================================================
    package:


    /**
     *
     */
    @safe pure nothrow
    this ( long a_id ) {
        _id = a_id;
    }


    /**
     *
     */
    mixin SimpleSettorGroup!(
        _child, _content, _flags, _id, _location, _name, _next, _owner, _parent, _sibling
    );


    /**
     *
     */
    /*pure*/
    void addDefinition ( Symbol def ) {
        import std.algorithm;
        import std.exception;

        enforce( !_defines.canFind( def ) );
        _defines ~= def;
    }


    /**
     *
     */
    @safe pure
    void addVerb ( Verb v ) {
        import std.algorithm;
        import std.exception;

        //enforce( !_verbs.canFind( v ) );//TODO make this work
        _verbs ~= v;
    }


    /**
     *
     */
    pure nothrow @property @safe
    string name ( string val ) {
        return _name = val;
    }


    /**
     *
     */
    pure nothrow @safe
    Verb verb ( size_t idx ) {
        return ( idx < _verbs.length ) ? _verbs[ idx ] : null;
    }


} // end MObject

