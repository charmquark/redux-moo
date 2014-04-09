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
 *  Returns: program exit code; 0 meaning success, >0 meaning error.  See module moo.exception for
 *      details.
 */
int main ( string[] args )
in {
    // there's something seriously wonky if this ever trips...
    assert( args.length > 0 );
}
body {
    import config = moo.config;

    config.parseArgs( args );
    if ( config.shouldStart ) {
        import log = moo.log;

        try {
            import db   = moo.db    ;
            import net  = moo.net   ;
            import vm   = moo.vm    ;

            log.start();
            log.info( `startup`, `Starting ReduxMOO %s`, APP_VERSION );

            db.start();
            vm.start();
            net.start();

            while ( config.shouldContinue ) {
                net.run();
                vm.run();
                db.run();
            }
        }
        catch ( Exception x ) {
            config.checkUncaughtException( x );
            log.error( `uncaught`, x );
        }
        finally {
            net.stop();
            vm.stop();
            db.stop();

            log.info( `shutdown`, `Goodbye.` );
            log.stop();
        }
    }
    return config.exitCode;
}

