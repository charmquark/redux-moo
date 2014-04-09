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
module moo.native.signal;


version( Posix )
{
    /**
    *
    */
    @system void registerSignalHandlers () nothrow
    {
        import core.stdc.signal;

        signal( SIGTERM, &quit_on_signal );
        signal( SIGINT, &quit_on_signal );
    }


    /**
     *
     */
    private extern( C ) @system void quit_on_signal ( int signo ) nothrow
    {
        import config = moo.config;

        config.shouldContinue = false;
    }
}
else
{
    static assert( "Sorry to say, your platform is not yet supported." );
}

