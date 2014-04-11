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
 *  The logger interface.
 */
module moo.log;

import std.stdio : File;


/**
 *
 */
immutable SEPARATOR = ` -- `;


/**
 *
 */
@safe void error ( Args... ) ( string msg, Args args ) nothrow
{
    write( `ERROR`, msg, args );
}

///ditto
@trusted void error () ( Exception x ) nothrow
{
    try {
        write( `ERROR`, x.toString() );
        auto cause = x.next;
        while ( cause !is null ) {
            writePlain( cause.toString() );
            cause = cause.next;
        }
    }
    catch ( Exception x ) {}
}


/**
 *
 */
@safe void info ( Args... ) ( string msg, Args args ) nothrow
{
    write( `info`, msg, args );
}


/**
 * Start the logger system.
 */
void start ()
{
    import core.stdc.stdio : _IOLBF;
    import config = moo.config;

    assert( !file.isOpen );
    file.open( config.logPath, `w` );
    file.setvbuf( 1024_u, _IOLBF );
}


/**
 *
 */
void stop ()
{
    file.close();
}


//--------------------------------------------------------------------------------------------------
private:


File file; /// 


/**
 *
 */
@trusted void fail () nothrow
{
    import std.stdio : stderr;

    import config = moo.config;

    try {
        stderr.writeln( `### ReduxMOO error ### Can no longer reach log file...? Server shutting down.` );
    }
    catch ( Throwable t ) {}
    config.shouldContinue = false;
}


/**
 *
 */
@trusted void write ( Args... ) ( string prefix, string msg, Args args ) nothrow
{
    import std.datetime : Clock;
    import std.format : formattedWrite;

    try {
        if ( file.isOpen ) {
            auto w = file.lockingTextWriter();
            w.put( Clock.currTime().toSimpleString() );
            w.put( SEPARATOR );
            w.put( prefix );
            w.put( SEPARATOR );
            static if ( Args.length == 0 ) {
                w.put( msg );
            }
            else {
                formattedWrite( w, msg, args );
            }
            w.put( '\n' );
        }
    }
    catch ( Exception x ) {
        fail();
    }
}


/**
 *
 */
@trusted void writePlain ( string msg ) nothrow
{
    try {
        if ( file.isOpen ) {
            file.writeln( SEPARATOR, msg );
        }
    }
    catch ( Exception x ) {
        fail();
    }
}

