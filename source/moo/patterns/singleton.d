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
 *  Mixin implementation of the low-lock singleton pattern.
 */
module moo.patterns.singleton;


/**
 *  Standard implementation.
 */
mixin template Singleton () {
    alias This = typeof( this );


    private {
        static {
            bool            _instantiated   = false;    /// Thread-local instance indicator.
            __gshared This  _instance       ;           /// Global shared instance.
        }
    }


    /**
     *  Singleton instance retrieval.
     *
     *  Returns: the global shared instance.
     */
    @property
    static This instance () {
        if ( !_instantiated ) {
            synchronized {
                if ( _instance is null ) {
                    _instance = new This;
                }
                _instantiated = true;
            }
        }
        return _instance;
    }


    /**
     *  Default constructor.  Made private to prevent instances other than the managed one.
     */
    private this () {}


} // end Singleton


