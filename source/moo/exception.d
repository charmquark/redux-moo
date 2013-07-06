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


/**
 *
 */
class ExitCodeException : Exception
{
    import ErrNo = core.stdc.errno;


    /**
     *
     */
    enum : int {
        OK      = 0,
        GEN     = 1,
        PERM    = ErrNo.EPERM,
        FILE_NF = ErrNo.ENOENT,
        INV_ARG = ErrNo.EINVAL,
        INV_DB  = 254,
        UNKNOWN = 255
    }


    /**
     *
     */
    this (
        int         code    ,
        string      msg     ,
        string      file    = __FILE__,
        size_t      line    = __LINE__,
        Throwable   next    = null
    ) 
    @safe pure nothrow

    body {
        super( msg, file, line, next );
        this.code = code;
    }


    this (
        int         code    ,
        string      msg     ,
        Throwable   next    ,
        string      file    = __FILE__,
        size_t      line    = __LINE__
    )
    @safe pure nothrow

    body {
        this( code, msg, file, line, next );
    }


    /**
     *
     */
    int code;


} // end ExitCodeException
