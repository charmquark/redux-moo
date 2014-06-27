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
 *  Database system runtime and main API.
 */
module moo.db.runtime;

import  moo.config      ,
        moo.exception   ,
        moo.log         ,
        moo.db.types    ;


/**
 *  Perform any pending work.
 */
void run ()
{
}


/**
 *  Select an object from the database.
 *
 *  Params:
 *      oid = desired object #id
 *
 *  Returns: a pointer to a const view of the selected object, or null if invalid
 */
@safe const(MObject) select(MInt oid) nothrow
{
    auto obj = mutableSelect(oid);
    if (obj !is null && obj.recycled)
    {
        obj = null;
    }
    return obj;
}


/**
 *  Start the database system.
 */
void start()
{
    exitCodeEnforce!`Internal`(!active, `start() called on active database system`);
    log(`Starting database system.`);
    debug {
        log(` * size of an object : %d`, __traits(classInstanceSize, MObject));
        log(` * size of a property: %d`, MProperty.sizeof);
        log(` * size of a value   : %d`, MValue.sizeof);
        log(` * size of a verb    : %d`, __traits(classInstanceSize, MVerb));
    }
    load();
    exitCodeEnforce!`InvalidDb`(validate(), `database failed validation`);
    active = true;
}


/**
 *  Stop the database system.
 */
@safe void stop () nothrow
{
    if ( active ) {
        log( `Stopping database system.` );
        active = false;
    }
}


//--------------------------------------------------------------------------------------------------
package:


/**
 *  Reserve a minimum number of slots in the database.
 *
 *  Params:
 *      requestedSize   = the desired minimum size (kinda obvious)
  */
@safe void reserve ( size_t requestedSize ) nothrow
{
    if ( world.length < requestedSize ) {
        world.length = requestedSize;
    }
}


/**
 *  Select an object from the database. Will select recycled objects. Outside code should use
 *  select() instead.
 *
 *  Params:
 *      oid     = desired object #id
 *      create  = whether to create the object if it does not exist
 *
 *  Returns: a reference to the selected object, or null if the #id is outside the database's range.
 */
@trusted MObject mutableSelect(MInt oid, bool shouldCreate = false) nothrow
{
    MObject obj = null;
    if (oid >= 0 && oid < world.length)
    {
        obj = world[oid];
        if (obj is null && shouldCreate)
        {
            obj = world[oid] = new MObject(oid);
        }
    }
    return obj;
}


/**
 *  Select a verb from the database by index. This is "unsafe" in that it returns a mutable view.
 *
 *  Params:
 *      oid = object #id to select the verb from
 *      vid = index of the desired verb
 *
 *  Returns: a pointer to the selected verb, or null if invalid
 */
@safe MVerb mutableSelectVerb(MInt oid, MInt vid) nothrow
{
    MVerb v = null;
    if (auto o = mutableSelect(oid))
    {
        v = o.selectVerb(vid);
    }
    return v;
}


//--------------------------------------------------------------------------------------------------
private:


bool        active  = false ; /// whether the system is active; ie, whether start() has been called
MObject[]   world           ; /// actual object storage


/**
 *  Load the database from disc.
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
            log( `Will load LambdaMOO database from %s`, config.dbPath );
            lloader.load( file );
        }
        else {
            log( `Will load ReduxMOO database from %s`, config.dbPath );
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
 *  Validate a loaded database, checking for inheritance/location cycles, invalid owners, etc.
 *
 *  Returns: true for pass, false for fail.
 */
@safe bool validate () pure nothrow
{
    bool pass = true;
    return pass;
}

