module moo.db.lambda_loader;

import moo.db;
import moo.db.loader;


//==================================================================================================
package:


final class LambdaLoader : Loader {


    /**
     *
     */
    this ( ref File file ) {
        source = file.byLine();
    }


    void load () {
    }


    //============================================================================================
    private:


    ByLineRange source = void;


    /**
     *
     */
    T next ( T ) () {
        import std.conv;

        return nextLine().to!T();
    }

    alias nextInt       = next!long     ;
    alias nextFloat     = next!double   ;
    alias nextString    = next!string   ;
    // We use next to read strings, rather than use the value of source.front directly, because
    // File.byLine will reuse its internal buffer, obliterating any data we were using.  Calling
    // to!string on it produces a safe copy.


    /**
     *
     */
    char[] nextLine () {
        import moo.exception;
        exitCodeEnforce!`INVALID_DB`( !source.empty, `Unexpected end of database file.` );
        auto result = source.front;
        source.popFront();
        return result;
    }


} // end LambdaLoader