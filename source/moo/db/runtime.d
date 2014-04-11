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
module moo.db.runtime;

import moo.exception;
import moo.types;
import moo.db.types;

import config   = moo.config    ;
import log      = moo.log       ;


/**
 *
 */
void run ()
{
}


/**
 *
 */
void start ()
{
    exitCodeEnforce!`Internal`( !active, `start() called on active database system` );
    log.info( `Starting database system.` );
    load();
    validate();
    active = true;
}


/**
 *
 */
void stop ()
{
    if ( active ) {
        log.info( `Stopping database system.` );
        active = false;
    }
}


//--------------------------------------------------------------------------------------------------
package:


/**
 *
 */
void reserve ( MInt requestedSize )
{
    if ( world.length < requestedSize ) {
        world.length = requestedSize;
    }
}


/**
 *
 */
MObject* unsafeSelect ( MInt oid )
{
    MObject* ptr = null;
    if ( oid >= 0 && oid < world.length ) {
        ptr = &world[ oid ];
    }
    return ptr;
}


/**
 *
 */
MVerb* unsafeSelectVerb ( MInt oid, MInt vid )
{
    auto obj = unsafeSelect( oid );
    if ( vid >= 0 && vid < obj.verbs.length ) {
        return &obj.verbs[ vid ];
    }
    else {
        return null;
    }
}


//--------------------------------------------------------------------------------------------------
private:


/**
 *
 */
bool active = false;


/**
 *
 */
MObject[] world;


/**
 *
 */
void load ()
{
    import std.file : exists;
    import std.stdio : File;

    import lloader = moo.db.load_lambda;
    import rloader = moo.db.load_remoo;

    exitCodeEnforce!`FileNotFound`(
        config.dbPath.exists(),
        `Did not find database file ` ~ config.dbPath
    );
    auto file = File( config.dbPath, `r` );
    try {
        if ( config.lambda ) {
            log.info( `Will load LambdaMOO database from %s`, config.dbPath );
            lloader.load( file );
        }
        else {
            log.info( `Will load ReduxMOO database from %s`, config.dbPath );
            rloader.load( file );
        }
    }
    catch ( ExitCodeException xcx ) {
        throw xcx;
    }
    catch ( Exception x ) {
        throw new ExitCodeException( ExitCode.Generic, `Failed loading database`, x );
    }
}


/**
 *
 */
@safe void validate () pure nothrow
{
}

