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
 *  ReduxMOO is an implementation and expansion of the LambdaMOO server.
 */
module moo.app;

import moo.exception;


/**
 *  Application version.
 */
enum APP_VERSION = `0.1.0-alpha`;


/**
 *  Main function.
 *
 *  Params:
 *      args = command line arguments
 *
 *  Returns: program exit code; 0 meaning success, >0 meaning error.  See module moo.exception for
 *      details.
 */
int main ( string[] args )

in {
    // there's something seriously wonky if this ever trips...
    assert( args.length != 0 );
}

body {
    auto    exitCode    = ExitCode.OK;
    Options options     ;

    try {
        options.parse( args );
        if ( options.help ) {
            options.showHelp();
        }
        else {
            app_startup( options );
            app_shutdown();
        }
    }
    catch ( Exception x ) {
        import std.stdio : stderr;

        if ( auto xx = cast( ExitCodeException ) x ) {
            exitCode = xx.code;
        }
        else {
            exitCode = ExitCode.GENERIC;
        }

        Throwable curr = x;
        while ( curr !is null ) {
            debug   { stderr.writeln( curr.toString() );       }
            else    { stderr.writeln( `ERROR: `, curr.msg );   }
            curr = curr.next;
        }

        if ( options.help ) {
            options.showHelp( true /*ignore exceptions*/ );
        }
    }

    return exitCode;
}


//==================================================================================================
private:


/**
 *  Program options.
 */
struct Options
{
    import std.getopt;

    enum DEFAULT_DB     = `moo.db`;
    enum DEFAULT_PORT   = 11000;
    enum HELP_FMT       =
        "USAGE: %s <options>\n"
        "\n"
        "OPTIONS:\n"
        "    -?  --help         Show this help text.\n"
        "    -f  --file=PATH    Path to database. (default %s; current %s)\n"
        "    -l  --log=PATH     Path to logfile. If not given, derived from db path. (current %s)\n"
        "    -p  --port=NUM     System listener port. (default %s; current %s)\n"
        "    -v  --verbose      Verbose program output.\n"
    ;

    public {
        string  command = void,         /// actual system command used to execute the server
                db      = DEFAULT_DB,   /// path to database
                log     = null;         /// path to log file
        ushort  port    = DEFAULT_PORT; /// port to bind the default listener
        bool    help    = false,        /// whether to show the help/usage text
                verbose = false;        /// whether to log verbose messages
    }


    //==========================================================================================
    private:


    /**
     *  Parse options from the command line.
     *
     *  Params:
     *      args = command line
     */
    void parse ( string[] args )

    in {
        assert( args.length != 0 );
    }

    body {
        import std.getopt   ;
        import std.path     : setExtension      ;
        import std.string   : format            ;

        command = args[ 0 ];
        getopt(
            args,
            config.passThrough,
            "file|f"    , &db       ,
            "log|l"     , &log      ,
            "port|p"    , &port     ,
            "help|?"    , &help     ,
            "verbose|v" , &verbose  
        );
        {
            scope( failure ) help = true;
            exitCodeEnforce!`INVALID_ARG`( args.length <= 1, `Unrecognized argument(s).` );
        }
        if ( log == null ) {
            log = db.setExtension( `log` );
        }
    }


    /**
     *  Write the help/usage text to stdout.
     */
    void showHelp ( bool ignoreExceptions = false ) {
        import std.stdio : stdout;

        try {
            stdout.writefln( HELP_FMT, command, DEFAULT_DB, db, log, DEFAULT_PORT, port );
        }
        catch ( Exception x ) {
            if ( !ignoreExceptions ) {
                throw x;
            }
        }
    }


} // end Options


/**
 *  Stop the server.
 */
void app_shutdown () {
    import moo.log;
    import moo.db.db;

    db_stop();
    Logger( `shutdown` )( `Goodbye.` );
}


/**
 *  Start the server.
 */
void app_startup ( Options options ) {
    import moo.log;
    import moo.db.db;

    log_start( options.log, options.verbose );
    Logger( `startup` )( `Starting ReduxMOO %s`, APP_VERSION );
    db_start( options.db );
}

