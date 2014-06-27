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
 *  ReduxMOO is a reimplementation and expansion of the LambdaMOO server.
 */
module moo.app;


/**
 *  Main function.
 *
 *  Params:
 *      args = command line arguments
 *
 *  Returns: program exit code; 0 meaning success, >0 meaning error.  See module moo.config for
 *      details.
 */
int main ( string[] args )
in {
    // there's something seriously wonky if this ever trips...
    assert( args.length > 0 );
}
body {
    import moo.config;

    config.parseArgs( args );
    if ( config.shouldStart ) {
        import moo.log;

        import sig  = moo.native.signal ;
        import db   = moo.db            ;
        import net  = moo.net           ;
        import vm   = moo.vm            ;

        try {
            startLog();
            log( `Starting ReduxMOO %s`, APP_VERSION );

            db.start();
            vm.start();
            net.start();

            sig.registerSignalHandlers();

            while ( config.shouldContinue ) {
                net.run();
                vm.run();
                db.run();
            }
        }
        catch ( Exception x ) {
            checkUncaughtException( x );
            logError( x );
        }
        finally {
            net.stop();
            vm.stop();
            db.stop();

            log( `Goodbye.` );
            stopLog();
        }
    }
    else {
        showHelp( args[ 0 ] );
    }
    return config.exitCode;
}


/**
 *
 */
void showHelp ( in string cmd )
{
    import std.stdio : stdout;

    stdout.write(
        "USAGE: ", cmd, " [options]\n\n"
        "OPTIONS:\n"
        "    -?  --help         Show this help text\n"
        "    -f  --file=PATH    Set path to database file\n"
        "    -l  --log=PATH     Set path to log file; defaults to <db basename>.log\n"
        "    -L  --lambda       Load and convert a LambdaMOO database\n"
        "    -p  --port=NUM     System listener port\n"
    );
}

