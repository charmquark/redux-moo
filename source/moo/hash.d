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
module moo.hash;


/**
 *
 */
alias MHash = uint;


/**
 *  based on MurmurHash3
 *  TODO: write a separate 64bit version
 */
@safe MHash hash ( dstring str ) pure nothrow
{
    static immutable uint
        c1  = 0xcc9e2d51    ,
        c2  = 0x1b873593    ,
        r1  = 15            ,
        r1a = 32 - r1       ,
        r2  = 13            ,
        r2a = 32 - r2       ,
        m   = 5             ,
        n   = 0xe6546b64    ;

    uint result = seed;
    uint k;

    foreach ( dchar dc ; str ) {
        k = cast( uint ) dc;
        k *= c1;
        k = (k << r1) | (k >> r1a);
        k *= c2;
        result ^= k;
        result = ((result << r2) | (result >> r2a) * m) + n;
    }

    result ^= str.length;
    result ^= (result >> 16);
    result *= 0x85ebca6b;
    result ^= (result >> 13);
    result *= 0xc2b2ae35;
    result ^= (result >> 16);
    return result;
}


//--------------------------------------------------------------------------------------------------
private:


/**
 *
 */
immutable MHash seed;


/**
 *
 */
static this ()
{
    import std.random : uniform;

    seed = uniform!MHash();
}

