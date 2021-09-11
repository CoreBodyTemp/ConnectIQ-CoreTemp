/* Copyright (C) 2021, greenTEG AG
 *    info@CoreBodyTemp.com
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

using Toybox.Graphics;
using Toybox.WatchUi;


class CharacterFactory extends WatchUi.PickerFactory {
    hidden var mCharacterSet;
    hidden var mAddDone;
    hidden var mAddDelete;
    const DONE = -1;
    const DELETE = -2;

    function initialize(characterSet, options) {
        PickerFactory.initialize();
        mCharacterSet = characterSet;
        mAddDone = (null != options) and (options.get(:addDone) == true);
        mAddDelete = (null != options) and (options.get(:addDelete) == true);
    }	// end func initialize


    function getIndex(value) {
        var index = mCharacterSet.find(value);
        return index;
    }	// end func getIndex


    function getSize() {
        return mCharacterSet.length() + ( mAddDone ? 1 : 0 ) + ( mAddDelete ? 1 : 0 );
    }	// end func getSize


    function getValue(index) {
        if(index == mCharacterSet.length() and mAddDone) {
            return DONE;
        }
        else if(index >= mCharacterSet.length()) {
        	return DELETE;
        }

        return mCharacterSet.substring(index, index+1);
    }	// end func getValue


    function getDrawable(index, selected) {
        if(index == mCharacterSet.length() and mAddDone) {
            return new WatchUi.Text( {:text=>Rez.Strings.Done_Item, :color=>Graphics.COLOR_WHITE, :font=>Graphics.FONT_LARGE, :locX =>WatchUi.LAYOUT_HALIGN_CENTER, :locY=>WatchUi.LAYOUT_VALIGN_CENTER } );
        }
        else if(index >= mCharacterSet.length()) {
            return new WatchUi.Text( {:text=>Rez.Strings.Delete_Item, :color=>Graphics.COLOR_WHITE, :font=>Graphics.FONT_LARGE, :locX =>WatchUi.LAYOUT_HALIGN_CENTER, :locY=>WatchUi.LAYOUT_VALIGN_CENTER } );
        }

        return new WatchUi.Text( { :text=>getValue(index), :color=>Graphics.COLOR_WHITE, :font=> Graphics.FONT_LARGE, :locX =>WatchUi.LAYOUT_HALIGN_CENTER, :locY=>WatchUi.LAYOUT_VALIGN_CENTER } );
    }	// end func getDrawable


    function isDone(value) {
        return mAddDone and (value == DONE);
    }	// end func isDone

    
    function isDelete(value) {
        return mAddDelete and (value == DELETE);
    }	// end func isDelete
}	// end class CharacterFactory
