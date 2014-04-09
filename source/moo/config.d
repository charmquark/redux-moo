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
immutable DEFAULT_DB_PATH = `remoo.db`;


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
ExitCode exitCode = ExitCode.Ok;


/**
 *
 */
bool shouldContinue = true;


/**
 *
 */
@safe @property string dbPath () nothrow
{
    return dbPath_;
}


/**
 *
 */
@safe @property string logPath () nothrow
{
    return logPath_;
}


/**
 *
 */
@safe @property ushort port () nothrow
{
    return port_;
}


/**
 *
 */
@safe @property bool shouldStart () nothrow
{
    return shouldStart_;
}


/**
 *
 */
@safe @property bool verbose () nothrow
{
    return verbose_;
}


/**
 *
 */
void checkUncaughtException ( Exception x )
{
    import moo.exception;

    if ( auto xcx = cast( ExitCodeException ) x ) {
        exitCode = xcx.exitCode;
    }
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

    bool helpWanted = false;
    getopt(
        args,
        std.getopt.config.passThrough,
        `help|?`    , &helpWanted   ,
        `file|f`    , &dbPath_      ,
        `log|l`     , &logPath_     ,
        `port|p`    , &port_        ,
        `verbose|v` , &verbose_
    );
    if ( logPath_ == null ) {
        logPath_ = dbPath_.setExtension( `log` );
    }
    if ( helpWanted ) {
        stdout.writef(
            "USAGE: %s [options]\n"
            "\n"
            "OPTIONS:\n"
            "    -?  --help         Show this help text.\n"
            "    -f  --file=PATH    Set path to database. (default: %s) (current: %s)\n"
            "    -l  --log=PATH     Set path to log. If omitted, derived from db path. (current: %s)\n"
            "    -p  --port=NUM     System listener port. (default: %s) (current: %s)\n"
            "    -v  --verbose      Verbose program output; rarely useful.\n",
            args[ 0 ],
            DEFAULT_DB_PATH, dbPath,
            logPath,
            DEFAULT_PORT, port
        );
    }
    else if ( args.length > 1 ) {
        throw new ExitCodeException( ExitCode.InvalidArg, `Unrecognized argument(s).` );
    }
}


//--------------------------------------------------------------------------------------------------
private:


/**
 *
 */
string dbPath_ = DEFAULT_DB_PATH;


/**
 *
 */
string logPath_ = null;


/**
 *
 */
ushort port_ = DEFAULT_PORT;


/**
 *
 */
bool shouldStart_ = false;


/**
 *
 */
bool verbose_ = false;

