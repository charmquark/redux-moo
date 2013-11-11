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
 *  The logger interface.
 */
module moo.log;

import core.sync.mutex;
import std.stdio : File;


private {
    enum SEPARATOR = ` -- `;


    __gshared Mutex     mutex       = null  ;   /// 
    __gshared File      file                ;   /// Global shared log file
    __gshared bool      verbosity   = false ;   /// Global shared verbosity flag.


    debug {
        __gshared bool active = false ;   /// 
    }


    shared
    static this () {
        mutex = new Mutex;
    }
}


/**
 *  The logger interface.
 */
struct Logger
{


    private {
        string _label = null;   /// Copy-local log message label.
    }


    /**
     *  Constructor.
     *
     *  Params:
     *      a_label = copy-local log message label
     */
    this ( string a_label = null ) {
        _label = a_label ~ SEPARATOR;
    }


    /**
     *  Write a message to the log.  May either be just a string, or a format string and arguments.
     *  This is aliased to the call operator.
     *
     *  Params:
     *      msg     = log message, or format string
     *      args    = formatting arguments
     */
    void write ( Args... ) ( string msg, Args args ) {
        log_write( _label, msg, args );
    }

    ///ditto
    alias opCall = write;


    /**
     *  Writes a message to the log only if the verbosity flag is set true.  Takes the same
     *  parameters as write.
     *
     *  Params:
     *      msg     = log message, or format string
     *      args    = formatting arguments
     */
    void verbose ( Args... ) ( lazy string msg, Args args ) {
        if ( verbosity )
            write( msg(), args );
    }


    //==========================================================================================
    private:


    /**
     *  Prepares a log message for writing, by prepending it with the datetime and our label.
     *
     *  Params:
     *      msg = the bare message text (post format() call, if any)
     *
     *  Returns: the final message text.
     */
    string prepare ( string msg ) {
        import std.array    : appender  ;
        import std.datetime : Clock     ;

        auto result = appender!string();
        result.put( Clock.currTime().toSimpleString() );
        result.put( SEPARATOR );
        if ( _label != null ) {
            result.put( _label );
            result.put( SEPARATOR );
        }
        result.put( msg );
        return result.data;
    }


} // end Logger


/**
 *  Start the logger system.
 *
 *  Params:
 *      path    = log file path
 *      verbose = verbosity flag
 *
 *  Throws: ExitCodeException if started twice.
 */
void log_start ( string logPath, bool verbosityFlag )

in {
    assert( logPath != null );
    assert( logPath != `` );
}

body {
    import moo.exception;

    synchronized ( mutex ) {
        debug {
            exitCodeEnforce!`GENERIC`( !active, `Tried to start logger twice.` );
            active = true;
        }
        file = File( logPath, `a` );
        verbosity = verbosityFlag;
    }
}


//==================================================================================================
private:


/**
 *  Actually writes text to the log file.
 *
 *  Params:
 *      text = the text to be written
 */
void log_write ( Args... ) ( string label, string msg, Args args ) {
    import std.array    : appender  ;
    import std.datetime : Clock     ;
    import std.string   : sformat   ;

    import moo.exception;

    static text = appender!string();
    static char[ 1024 ] buffer;

    text.put( Clock.currTime().toSimpleString() );
    text.put( SEPARATOR );
    if ( label != null )
        text.put( label );

    static if ( Args.length == 0 ) {
        text.put( msg );
    }
    else {
        text.put( sformat( buffer, msg, args ) );
    }

    synchronized ( mutex ) {
        debug exitCodeEnforce!`GENERIC`( active, `Tried to use inactive logger.` );
        file.writeln( text.data );
    }

    text.clear();
}

