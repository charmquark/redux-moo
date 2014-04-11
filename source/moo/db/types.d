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
module moo.db.types;

import moo.types;


/**
 *
 */
struct MObject
{
    /**
     *
     */
    MProperty[ MSymbol ] properties;


    /**
     *
     */
    MString name;


    /**
     *
     */
    MVerb[] verbs;


    /**
     *
     */
    MInt id;


    /**
     *
     */
    MObject* child = null;


    /**
     *
     */
    MObject* content = null;


    /**
     *
     */
    MObject* location = null;


    /**
     *
     */
    MObject* next = null;


    /**
     *
     */
    MObject* owner = null;


    /**
     *
     */
    MObject* parent = null;


    /**
     *
     */
    MObject* sibling = null;


    /**
     *
     */
    bool fertile = false;


    /**
     *
     */
    bool player = false;


    /**
     *
     */
    bool programmer = false;


    /**
     *
     */
    bool readable = false;


    /**
     *
     */
    bool recycled = true;


    /**
     *
     */
    bool wizard = false;


    /**
     *
     */
    bool writable = false;


    /**
     *
     */
    void add ( MVerb v )
    {
        verbs ~= v;
    }


} // end MObject


/**
 *
 */
struct MProperty
{
    /**
     *
     */
    MValue value;


    /**
     *
     */
    MObject* owner;


    /**
     *
     */
    bool chownable = false;


    /**
     *
     */
    bool readable = false;


    /**
     *
     */
    bool writable = false;


}


/**
 *
 */
struct MVerb
{
    /**
     *
     */
    MString name;


    /**
     *
     */
    MString source;


    /**
     *
     */
    MInt preposition;


    /**
     *
     */
    MObject* owner;


    /**
     *
     */
    bool executable = false;


    /**
     *
     */
    bool readable = false;


    /**
     *
     */
    bool writable = false;


    /**
     *
     */
    MVerbArgument directObject;


    /**
     *
     */
    MVerbArgument indirectObject;


}


/**
 *
 */
enum MVerbArgument : ubyte
{
    None,
    Any,
    This
}

///ditto
alias MVerbArg = MVerbArgument;

