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
void error ( Args... ) ( string label, string msg, Args args )
{
    write( `ERROR`, label, msg, args );
}

///ditto
void error () ( string label, Exception x )
{
    write( `ERROR`, label, x.toString() );
    auto cause = x.next;
    while ( cause !is null ) {
        writePlain( cause.toString() );
        cause = cause.next;
    }
}


/**
 *
 */
void info ( Args... ) ( string label, string msg, Args args )
{
    write( `info`, label, msg, args );
}


/**
 * Start the logger system.
 */
void start ()
{
    import config = moo.config;

    assert( !file.isOpen );
    file.open( config.logPath, `a` );
}


/**
 *
 */
void stop ()
{
    assert( file.isOpen );
    file.close();
}


//--------------------------------------------------------------------------------------------------
private:


/**
 *
 */
File file;


/**
 *
 */
void write ( Args... ) ( string prefix, string label, string msg, Args args )
{
    import std.array : appender;
    import std.datetime : Clock;
    import std.string : sformat;

    static text = appender!string();
    static char[ 1024 ] buffer;

    if ( file.isOpen ) {
        text.put( Clock.currTime().toSimpleString() );
        text.put( SEPARATOR );
        text.put( prefix );
        text.put( SEPARATOR );
        if ( label != null ) {
            text.put( label );
            text.put( SEPARATOR );
        }

        static if ( Args.length == 0 ) {
            text.put( msg );
        }
        else {
            text.put( sformat( buffer, msg, args ) );
        }

        file.writeln( text.data );
        text.clear();
    }
}


/**
 *
 */
void writePlain ( string msg )
{
    if ( file.isOpen ) {
        file.write( SEPARATOR );
        file.writeln( msg );
    }
}

