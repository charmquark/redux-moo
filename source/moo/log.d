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
module moo.log;


/**
 *
 */
struct Logger
{


    /**
     *
     */
    static enum SEP = ` -- `;


    /**
     *
     */
    static void start (
        string  path,
        bool    verbose
    )

    in {
        assert( path != null );
        assert( path != `` );
    }

    body {
        import moo.exception;

        synchronized {
            exitCodeEnforce!`GENERIC`( _path == null, `Tried to start logger twice.` );
            _path = path;
            _verbose = verbose;
        }
    }


    /**
     *
     */
     static void stop () {
        import std.file : append;
        
        if ( _path != null ) {
            synchronized {
                _path.append( `==================================================` );
            }
        }
     }


    /**
     *
     */
    this ( string a_label = null ) {
        _label = a_label;
    }


    /**
     *
     */
    void write ( string msg ) {
        _write( prepare( msg ) );
    }


    /**
     *
     */
    void verboseWrite ( lazy string msg ) {
        if ( _verbose ) {
            write( msg() );
        }
    }


    /**
     *
     */
    void writef ( Args... ) (
        string  fmt     ,
        Args    args
    ) {
        import std.string : format;

        write( fmt.format( args ) );
    }


    /**
     *
     */
    void verboseWritef ( Args... ) (
        string  fmt     ,
        Args    args
    ) {
        if ( _verbose ) {
            writef( fmt, args );
        }
    }


    //==========================================================================================
    private:


    /**
     *
     */
    static __gshared string _path = null;


    /**
     *
     */
    static __gshared bool _verbose = false;


    /**
     *
     */
    static void _write ( string text ) {
        import std.file : append;

        synchronized {
            _path.append( text );
            _path.append( "\n" );
        }
    }


    /**
     *
     */
    string _label = null;


    /**
     *
     */
    string prepare ( string msg ) {
        import std.array    : appender  ;
        import std.datetime : Clock     ;

        auto result = appender!string();
        result.put( Clock.currTime().toSimpleString() );
        result.put( SEP );
        if ( _label != null ) {
            result.put( _label );
            result.put( SEP );
        }
        result.put( msg );
        return result.data;
    }


} // end Logger

