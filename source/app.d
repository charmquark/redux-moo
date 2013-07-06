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
module app;

import  std.stdio   ;


/**
 *
 */
int main (
    string[] args
)

in {
    // there's something seriously wonky if this ever trips...
    assert( args.length != 0 );
}

body {
    int exitCode = 1;
    
    try {
        exitCode = 0;
    }
    catch ( Exception x ) {
        uncaughtException( x );
    }
    
    return exitCode;
}


////////////////////////////////////////////////////////////////////////////////////////////////////
private:
////////////////////////////////////////////////////////////////////////////////////////////////////


/**
 *
 */
void uncaughtException (
    Exception x
)

in {
    assert( x !is null );
}

body {
    
    stderr.writeln();
    stderr.writeln( x.toString() );
}

