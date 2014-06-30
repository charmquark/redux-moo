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
module moo.config;

import ErrNo = core.stdc.errno;


/**
 *  Program semantic version string.
 */
immutable APP_VERSION = `0.3.0-alpha`;


/**
 *  Default path to look for the database.
 */
immutable DEFAULT_DB_PATH = `remoo.rdb`;


/**
 *  Default port for the main listener.
 */
immutable ushort DEFAULT_PORT = 11000_u;


/**
 *  Possible program termination codes.
 */
enum ExitCode : int {
    Ok              = 0,            /// indicates success (the non-error)
    Generic         = 1,            /// an unspecified error has occurred
    Perms           = ErrNo.EPERM,  /// the program lacks needed filesystem/network permissions
    FileNotFound    = ErrNo.ENOENT, /// a file (likely the database file) was not found
    InvalidArg      = ErrNo.EINVAL, /// an invalid command line argument was provided
    Internal        = 253,          /// an unspecified internal error has occurred
    InvalidDb       = 254,          /// a loaded database failed validation
    Unknown         = 255           /// something seriously went wrong, so wrong we don't know what
}


/**
 *
 */
struct Config
{
    ExitCode    exitCode        = ExitCode.Ok   ; /// 
    bool        shouldContinue  = true          ; /// 


    /**
     *
     */
    @safe @property string dbPath () const pure nothrow
    {
        return dbPath_;
    }


    /**
     *
     */
    @safe @property bool helpWanted () const pure nothrow
    {
        return helpWanted_;
    }


    /**
     *
     */
    @safe @property bool lambda () const pure nothrow
    {
        return lambda_;
    }


    /**
     *
     */
    @safe @property string logPath () const pure nothrow
    {
        return logPath_;
    }


    /**
     *
     */
    @safe @property ushort port () const pure nothrow
    {
        return port_;
    }


    /**
     *
     */
    @safe @property bool shouldStart () const pure nothrow
    {
        return shouldStart_;
    }


    /**
     *
     */
    @safe void changeDBPathExtension(string ext = "rdb") pure nothrow
    {
        import std.path : setExtension;

        dbPath_ = dbPath_.setExtension(ext);
    }


    /**
     *
     */
    void parseArgs ( string[] args )
    {
        import std.getopt;
        import std.path : setExtension;
        import std.stdio : stdout;
        import moo.exception;

        getopt(
            args,
            std.getopt.config.passThrough,
            `help|?`    , &helpWanted_  ,
            `file|f`    , &dbPath_      ,
            `log|l`     , &logPath_     ,
            `lambda`    , &lambda_      ,
            `port|p`    , &port_
        );
        if ( logPath_ == null ) {
            logPath_ = dbPath_.setExtension( `log` );
        }
        if ( args.length > 1 ) {
            helpWanted_ = true;
            exitCode = ExitCode.InvalidArg;
        }
        shouldStart_ = !helpWanted_;
    }


    //------------------------------------------------------------------------------------------
    private:


    string  dbPath_         = DEFAULT_DB_PATH   ; /// 
    string  logPath_        = null              ; /// 
    ushort  port_           = DEFAULT_PORT      ; /// 
    bool    helpWanted_     = false             ; /// 
    bool    lambda_         = false             ; /// 
    bool    shouldStart_    = false             ; /// 

}


/**
 *
 */
Config config;


/**
 *
 */
@safe void checkUncaughtException ( in Exception x ) nothrow
{
    import moo.exception;

    if ( auto xcx = cast( const ExitCodeException ) x ) {
        config.exitCode = xcx.code;
    }
}

