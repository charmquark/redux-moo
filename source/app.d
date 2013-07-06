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
module app;


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
    import exception : ExitCodeException ;

    int     exitCode    = ExitCodeException.GEN;
    Options options     ;

    try {
        options.parse( args );
        exitCode = ExitCodeException.OK;
    }
    catch ( Exception x ) {
        uncaughtException( x );
        if ( auto xx = cast( ExitCodeException ) x ) {
            exitCode = xx.code;
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
    string  command = void,
            db      = `moo.db`,
            log     = null;
    ushort  port    = 11000;
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
        import exception    : ExitCodeException ;
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
        if ( args.length > 1 ) {
            throw new ExitCodeException(
                ExitCodeException.INV_ARG,
                `Unrecognized argument(s): %(%s%| %)`.format( args[ 1 .. $ ] )
            );
        }
        if ( log == null ) {
            log = db.setExtension( `log` );
        }
    }


} // end Options
/+            "file|f",   &dbFile,
            "log|l",    &logFile,
            "port|p",   &port,
            "help|?",   &help,
            "verbose|v",    &verbose,
+/


/**
 *
 */
void uncaughtException (
    Exception x
)

in {
    assert( x !is null );
}

body {
    import  std.stdio : stderr  ;

    stderr.writeln();
    stderr.writeln( x.toString() );
}

