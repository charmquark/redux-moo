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
 *  General interface to database loaders.
 */
module moo.db.loader;

import std.range;
import std.stdio : File;

import moo.db.lambda_loader;
import moo.db.redux_loader;


//==================================================================================================
package:


enum LAMBDA_METALINE    = `** LambdaMOO Database`;  /// partial first line of a lambda database
enum REDUX_METALINE     = `[redux db]`;             /// partial first line of a redux database


alias ByLineRange = typeof( File(``).byLine() );


/**
 *  
 */
interface Loader {


    /**
     *
     */
    abstract void load ();


} // end Loader


/**
 *  
 */
Loader db_selectLoader ( ref File file )

out ( result ) {
    assert( result !is null, `db_selectLoader unexpectedly returned null` );
}

body {
    import std.algorithm : startsWith;
    import std.string : strip;
    import moo.exception;

    auto metaline = file.readln().strip();
    if ( metaline.startsWith( REDUX_METALINE ) ) {
        return new ReduxLoader( file );
    }
    else if ( metaline.startsWith( LAMBDA_METALINE ) ) {
        return new LambdaLoader( file );
    }
    throw new ExitCodeException(
        ExitCode.INVALID_DB,
        `Do not recognize database metaline: ` ~ metaline
    );
}