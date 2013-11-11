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
 *  Primary database interface.
 */
module moo.db.db;

import moo.log;
import moo.db.object;
import moo.db.loader;


/**
 *  Start the database subsystem.
 *
 *  Params:
 *      path = file path to the database
 *
 *  Throws: ExitCodeException if called on an active database, or if the database fails to load and
 *      validate.
 */
void db_start ( string path ) {
    import moo.exception;

    exitCodeEnforce!`UNKNOWN`( !active, `db_start() called on an active database.` );
    log = Logger( `database` );
    db_load( path );
    exitCodeEnforce!`INVALID_DB`( db_validate(), `Database in ` ~ path ~ ` fails validation.` );
    active = true;
}


/**
 *  Stop the database system.
 */
void db_stop () {
    if ( active ) {
        active = false;
    }
}


//==================================================================================================
package:


/**
 *  Reserves a minimum number of slots in the database.  Primarily intended for use by loaders.
 *  Does nothing if at least requestedSize slots are already available.
 *
 *  Params:
 *      requestedSize     = requested minimum size
 *      shouldInstantiate = whether to create object to fill any new slots created (default true)
 */
void db_reserve (
    size_t requestedSize, 
    bool shouldInstantiate = true
)

in {
    assert( requestedSize > 0, `Tried to reserve a zero-length database.` );
}

body {
    if ( world.length < requestedSize ) {
        log.verbose( `Reserving %s slots.`, requestedSize );
        auto oldLength = world.length;
        world.length = requestedSize;
        if ( shouldInstantiate ) {
            foreach ( index, ref elem ; world[ oldLength .. $ ] ) {
                elem = new MObject( index );
            }
        }
    }
}


//==================================================================================================
private:


bool        active  = false ;   ///
Logger      log             ;   /// Logger interface.
MObject[]   world           ;   ///


/**
 *  Load a database from disc.
 *
 *  Params:
 *      path = file path to the database
 */
void db_load ( string path ) {
    import std.stdio;
    import moo.exception;

    {
        import std.file : exists;
        exitCodeEnforce!`FILE_NOT_FOUND`( path.exists(), `Did not find database file ` ~ path ~ `.` );
    }

    log.verbose( `Loading database from %s`, path );
    auto file = File( path, `r` );

    Loader loader;
    try {
        loader = db_selectLoader( file );
        loader.load();
    }
    catch ( Exception x ) {
        throw new ExitCodeException( ExitCode.UNKNOWN, `Database loader failed.`, x );
    }
    finally {
        if ( loader !is null ) {
            loader.destroy();
        }
    }
}


/**
 *  Validate a loaded database.
 *
 *  Returns: true for a verifiably valid database, false otherwise.
 */
bool db_validate () {  //TODO
    debug { return true; } else { return false; }
}

