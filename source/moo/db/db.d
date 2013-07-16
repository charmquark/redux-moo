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


/**
 *  Primary database interface, as a singleton object.
 */
final class Database
{
    import moo.log;
    import moo.patterns.singleton;

    mixin Singleton;


    private {
        Logger _log;    /// Logger interface.
    }


    /**
     *  Start the database subsystem.
     *
     *  Params:
     *      path = file path to the database
     *
     *  Throws: ExitCodeException if called on an active database, or if the database fails to load
     *      and validate.
     */
    void start ( string  path ) {
        import moo.exception;

        _log = Logger( `database` );
        load( path );
        exitCodeEnforce!`INVALID_DB`( validate(), `Database in ` ~ path ~ ` fails validation.`);
    }


    /**
     *  Stop the database system.
     */
    void stop () {}


    //==========================================================================================
    private:


    /**
     *  Load a database from disc.
     *
     *  Params:
     *      path = file path to the database
     */
    void load ( string path ) {
        _log( `Loading database from %s`, path );
    }


    /**
     *  Validate a loaded database.
     *
     *  Returns: true for a verifiably valid database, false otherwise.
     */
    bool validate () { return false; } //TODO


} // end Database

