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
    private static __gshared string _path = null;


    /**
     *
     */
    private static __gshared bool _verbose = false;


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
    this (
        string a_label = null
    )

    body {
        _label = a_label;
    }


    //==========================================================================================
    public:


    /**
     *
     */
    void write (
        string msg
    )

    body {
        import std.file : append;

        auto text = prepare( msg );
        synchronized {
            _path.append( text );
        }
    }


    /**
     *
     */
    void verboseWrite (
        lazy string msg
    )

    body {
        if ( _verbose ) {
            write( msg() );
        }
    }


    /**
     *
     */
    void writef (
        Args...
    ) (
        string  fmt     ,
        Args    args
    )

    body {
        import std.string : format;

        write( fmt.format( args ) );
    }


    /**
     *
     */
    void verboseWritef (
        Args...
    ) (
        string  fmt     ,
        Args    args
    )

    body {
        if ( _verbose ) {
            writef( fmt, args );
        }
    }


    //==========================================================================================
    private:


    /**
     *
     */
    string _label = null;


    /**
     *
     */
    string prepare (
        string msg
    )

    body {
        import std.array    : appender  ;
        import std.datetime : Clock     ;

        auto result = appender!string();
        result.put( `[` );
        result.put( Clock.currTime().toSimpleString() );
        result.put( `] ` );
        if ( _label != null ) {
            result.put( _label );
            result.put( `: ` );
        }
        result.put( msg );
        result.put( "\n" );
        return result.data;
    }


} // end Logger

