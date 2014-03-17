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
module moo.types;

import moo.db.object;


/**
 * 
 */
alias MFloat    = double    ;
alias MInt      = long      ;
alias MList     = Value[]   ;
alias MStr      = string    ;


/**
 * 
 */
enum MError : MInt {
    None,
    Type,
    Div,
    Perm,
    PropNF, 
    VerbNF, 
    VarNF, 
    InvInd,
    RecMove, 
    MaxRec, 
    Range, 
    Args, 
    NAcc, 
    InvArg, 
    Quota, 
    Float
}


/**
 * 
 */
enum Type : MInt {
    Int,
    Obj,
    Str,
    Err,
    List,
    Clear,
    None,
    Catch,
    Finally,
    Float,
    Symbol,
    ObjRef
}


/**
 * 
 */
struct Value {


    Type type = Type.None;


    union {
        MInt    i; // int, obj
        MStr    s; // str
        MError  e; // err
        MList   l; // list
        MFloat  f; // float
        Symbol  y; // symbol
        MObject o; // objref
    }


    /**
     *
     */
    static Value clear () {
        Value result;
        result.type = Type.Clear;
        result.i = 0;
        return result;
    }


    /**
     *
     */
    static Value obj ( MInt val ) {
        Value result;
        result.type = Type.Obj;
        result.i = val;
        return result;
    }


    /**
     *
     */
    this ( MInt val ) {
        type = Type.Int;
        i = val;
    }

    ///ditto
    this ( MStr val ) {
        type = Type.Str;
        s = val;
    }

    ///ditto
    this ( MError val ) {
        type = Type.Err;
        e = val;
    }

    ///ditto
    this ( const( MList ) val ) {
        type = Type.List;
        l = val.dup;
    }

    ///ditto
    this ( MFloat val ) {
        type = Type.Float;
        f = val;
    }

    ///ditto
    this ( Symbol val ) {
        type = Type.Symbol;
        y = val;
    }

    ///ditto
    this ( MObject val ) {
        type = Type.ObjRef;
        o = val;
    }


} // end Value


/**
 * 
 */
class Symbol {


    private {
        static Symbol[ string ]   registry;

        string _str;
    }


    /**
     *
     */
    static Symbol opIndex ( string str ) {
        return registry.get( str, new Symbol( str ) );
    }


    /**
     *
     */
    override pure nothrow @safe
    string toString () {
        return _str;
    }


    //==========================================================================================
    private:


    /**
     *
     */
    nothrow @safe
    this ( string str ) {
        _str = str;
        registry[ str ] = this;
    }


} // end Symbol

