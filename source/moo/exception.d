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
module moo.exception;

import ErrNo = core.stdc.errno;


/**
 *
 */
enum ExitCode : int {
    OK              = 0,
    GENERIC         = 1,
    PERMS           = ErrNo.EPERM,
    FILE_NOT_FOUND  = ErrNo.ENOENT,
    INVALID_ARG     = ErrNo.EINVAL,
    INTERNAL        = 253,
    INVALID_DB      = 254,
    UNKNOWN         = 255
}


/**
 *
 */
class ExitCodeException : Exception
{


    /**
     *
     */
    @safe pure nothrow
    this (
        ExitCode    code    ,
        string      msg     ,
        string      file    = __FILE__,
        size_t      line    = __LINE__,
        Throwable   next    = null
    ) {
        super( msg, file, line, next );
        this.code = code;
    }

    
    ///ditto
    @safe pure nothrow
    this (
        ExitCode    code    ,
        string      msg     ,
        Throwable   next    ,
        string      file    = __FILE__,
        size_t      line    = __LINE__
    ) {
        this( code, msg, file, line, next );
    }


    /**
     *
     */
    ExitCode code;


} // end ExitCodeException


/**
 *
 */
template enforceEx ( E ) {
    static import std.exception;

    static if ( is( E : ExitCodeException ) ) {
        @safe pure
        T enforceEx ( T ) (
            T           value   ,
            ExitCode    code    ,
            lazy string msg     = ``,
            string      file    = __FILE__,
            size_t      line    = __LINE__
        ) {
            if ( !value ) {
                throw new E( code, msg(), file, line );
            }
            return value;
        }
    }
    else {
        alias enforceEx = std.exception.enforceEx!E;
    }
}


/**
 *
 */
template exitCodeEnforce ( string CodeName ) {
    static if ( __traits( hasMember, ExitCode, CodeName ) ) {
        alias exitCodeEnforce = exitCodeEnforce!( __traits( getMember, ExitCode, CodeName ) );
    }
    else {
        static assert( false, `Undefined exit code name: ` ~ CodeName );
    }
}

///ditto
template exitCodeEnforce ( ExitCode Code ) {
    @safe pure
    T exitCodeEnforce ( T ) (
        T           value   ,
        lazy string msg     = ``,
        string      file    = __FILE__,
        size_t      line    = __LINE__
    ) {
        return enforceEx!ExitCodeException( value, Code, msg, file, line );
    }
}

