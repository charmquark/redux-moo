module moo.db.redux_loader;

import moo.db;
import moo.db.loader;


//==================================================================================================
package:


final class ReduxLoader : Loader {


    /**
     *
     */
    this ( ref File file ) {
        source = file.byLine();
    }


    /**
     *
     */
    void load () {
    }


    //============================================================================================
    private:


    ByLineRange source = void;


} // end ReduxLoader