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
 *  Application-specific exception handling code.
 */
module moo.exception;


/**
 *  An exception class that carries an exit code.
 */
class ExitCodeException : Exception
{
    import moo.config : ExitCode;

    /**
     *
     */
    ExitCode code = ExitCode.Generic;


    /**
     *  Constructor.
     *
     *  Params:
     *      code    = exit code payload
     *      msg     = (hopefully) meaningful description of what went wrong
     *      file    = (normally left defaulted) the file (module) where the exception occurred
     *      line    = (normally left defaulted) the line where the exception occurred
     *      next    = an exception to be considered the 'cause' of this one, or otherwise related
     */
    @safe this pure nothrow
    (
        ExitCode    code    ,
        string      msg     ,
        string      file    = __FILE__,
        size_t      line    = __LINE__,
        Throwable   next    = null
    )
    {
        super( msg, file, line, next );
        this.code = code;
    }


    ///ditto
    @safe this pure nothrow
    (
        ExitCode    code    ,
        string      msg     ,
        Throwable   next    ,
        string      file    = __FILE__,
        size_t      line    = __LINE__
    ) {
        this( code, msg, file, line, next );
    }

} // end ExitCodeException


/**
 *  A specialization of std.exception.enforceEx that appropriately handles the ExitCodeException, by
 *  accepting an ExitCode before the message.  Normally, this won't be used directly, but instead
 *  the exitCodeEnforce function would be used.
 */
template enforceEx ( E )
{
    static import std.exception;

    static if ( is( E : ExitCodeException ) ) {
        @safe T enforceEx pure ( T )
        (
            T           value   ,
            ExitCode    code    ,
            lazy string msg     = ``,
            string      file    = __FILE__,
            size_t      line    = __LINE__
        )
        {
            if ( !value )
                throw new E( code, msg(), file, line );
            return value;
        }
    }
    else {
        alias enforceEx = std.exception.enforceEx!E;
    }
}


/**
 *  Mimics std.exception.enforce but throws an ExitCodeException.  May be instantiated with either
 *  an ExitCode or a string reflecting a member of the ExitCode enum.
 *
 *  ---
 *  exitCodeEnforce!`InvalidDb`( validate(), `Database in ` ~ path ~ ` fails validation.`);
 *  ---
 */
template exitCodeEnforce ( string CodeName )
{
    static if ( __traits( hasMember, ExitCode, CodeName ) ) {
        alias exitCodeEnforce = exitCodeEnforce!( __traits( getMember, ExitCode, CodeName ) );
    }
    else {
        static assert( false, `Undefined exit code name: ` ~ CodeName );
    }
}

///ditto
template exitCodeEnforce ( ExitCode Code )
{
    @safe T exitCodeEnforce pure ( T )
    (
        T           value   ,
        lazy string msg     = ``,
        string      file    = __FILE__,
        size_t      line    = __LINE__
    )
    {
        return enforceEx!ExitCodeException( value, Code, msg, file, line );
    }
}

