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
module moo.app;

import moo.exception;


/**
 *
 */
enum APP_VERSION = `0.1.0-alpha`;


/**
 *
 */
int main (
    string[] args
)

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
            startup( options );
            shutdown();
        }
    }
    catch ( Exception x ) {
        exitCode = uncaughtException( x );
        if ( options.help ) {
            try {
                options.showHelp();
            }
            catch ( Exception ignore ) {}
        }
    }

    return exitCode;
}


////////////////////////////////////////////////////////////////////////////////////////////////////
private:
////////////////////////////////////////////////////////////////////////////////////////////////////


/**
 *
 */
struct Options
{
    import std.getopt;


    /**
     *
     */
    enum DEFAULT_DB = `moo.db`;


    /**
     *
     */
    enum DEFAULT_PORT = 11000;


    /**
     *
     */
    enum HELP_FMT = 
        "USAGE: %s <options>\n"
        "\n"
        "OPTIONS:\n"
        "    -?  --help         Show this help text.\n"
        "    -f  --file=PATH    Path to database. (default %s; current %s)\n"
        "    -l  --log=PATH     Path to logfile. If not given, derived from db path. (current %s)\n"
        "    -p  --port=NUM     System listener port. (default %s; current %s)\n"
        "    -v  --verbose      Verbose program output.\n"
    ;


    /**
     *
     */
    string  command = void,
            db      = DEFAULT_DB,
            log     = null;
    ushort  port    = DEFAULT_PORT;
    bool    help    = false,
            verbose = false;


    /**
     *
     */
    void parse (
        string[]    args
    )

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
     *
     */
    void showHelp ()

    body {
        import std.stdio : writeln, writefln;
        writefln( HELP_FMT, command, DEFAULT_DB, db, log, DEFAULT_PORT, port );
    }


} // end Options


/**
 *
 */
void shutdown ()

body {
    import moo.log;
    import moo.db.db;

    Database.instance.stop();
    Logger( `shutdown` ).write( `Goodbye.` );
}


/**
 *
 */
void startup (
    Options options
)

body {
    import moo.log;
    import moo.db.db;
    
    Logger.start( options.log, options.verbose );
    Logger( `startup` ).writef( `Starting ReduxMOO %s`, APP_VERSION );
    Database.instance.start( options.db, options.verbose );
}


/**
 *
 */
ExitCode uncaughtException (
    Exception x
)

in {
    assert( x !is null );
}

body {
    import  std.stdio : stderr  ;

    debug {
        stderr.writeln( x.toString() );
    }
    else {
        stderr.writeln( "ERROR: ", x.msg );
    }
    if ( auto xx = cast( ExitCodeException ) x ) {
        return xx.code;
    }
    return ExitCode.GENERIC;
}

