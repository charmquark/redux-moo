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


/**
 *  The logger interface.
 */
struct Logger
{


    alias opCall = write;


    /**
     *  Constructor.
     *
     *  Params:
     *      a_label = copy-local log message label
     */
    this ( string a_label = null ) {
        _label = a_label;
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
        static if ( Args.length == 0 ) {
            log_write( prepare( msg ) );
        }
        else {
            import std.string : format;

            log_write( prepare( msg.format( args ) ) );
        }
    }


    /**
     *  Writes a message to the log only if the verbosity flag is set true.  Takes the same
     *  parameters as write.
     *
     *  Params:
     *      msg     = log message, or format string
     *      args    = formatting arguments
     */
    void verbose ( Args... ) ( lazy string msg, Args args ) {
        if ( verbosity ) {
            write( msg(), args );
        }
    }


    //==========================================================================================
    private:


    string _label = null;   /// Copy-local log message label.


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
        exitCodeEnforce!`GENERIC`( !active, `Tried to start logger twice.` );
        path = logPath;
        verbosity = verbosityFlag;
        active = true;
    }
}


/**
 *  Stop the logger system.
 */
void log_stop () {
    import std.file : append;

    synchronized ( mutex ) {
        if ( active ) {
            log_write( `==================================================` );
            active = false;
        }
    }
}


//==================================================================================================
private:


enum SEPARATOR = ` -- `;


shared static this () {
    mutex = new Mutex;
}


__gshared bool      active      = false ;   /// 
__gshared Mutex     mutex       = null  ;   /// 
__gshared string    path        = null  ;   /// Global shared log file path.
__gshared bool      verbosity   = false ;   /// Global shared verbosity flag.


/**
 *  Actually writes text to the log file.
 *
 *  Params:
 *      text = the text to be written
 */
void log_write ( string text ) {
    import std.file : append;

    synchronized ( mutex ) {
        path.append( text );
        path.append( "\n" );
    }
}
