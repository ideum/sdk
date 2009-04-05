////////////////////////////////////////////////////////////////////////////////
//
//  OpenZoom
//
//  Copyright (c) 2007-2009, Daniel Gasienica <daniel@gasienica.ch>
//
//  OpenZoom is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  OpenZoom is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with OpenZoom. If not, see <http://www.gnu.org/licenses/>.
//
////////////////////////////////////////////////////////////////////////////////
package org.openzoom.flash.viewport.constraints
{

import flash.geom.Point;

import org.openzoom.flash.viewport.IViewportConstraint;
import org.openzoom.flash.viewport.IViewportTransform;

/**
 * Null Object Pattern applied to IViewportConstraint.
 */
public class NullConstraint implements IViewportConstraint
{
    //--------------------------------------------------------------------------
    //
    //  Class constants
    //
    //--------------------------------------------------------------------------

    private static const DEFAULT_MIN_ZOOM:Number = 0.00001
    private static const DEFAULT_MAX_ZOOM:Number = 1000000

    //--------------------------------------------------------------------------
    //
    //  Constructor
    //
    //--------------------------------------------------------------------------

    /**
     * Constructor.
     */
    public function NullConstraint()
    {
    }

    //--------------------------------------------------------------------------
    //
    //  Methods: IViewportConstraint
    //
    //--------------------------------------------------------------------------

    /**
     * @inheritDoc
     */
    public function validate(transform:IViewportTransform,
                             target:IViewportTransform):IViewportTransform
    {
        if (transform.zoom < DEFAULT_MIN_ZOOM)
            transform.zoomTo(DEFAULT_MIN_ZOOM)

        if (transform.zoom > DEFAULT_MAX_ZOOM)
            transform.zoomTo(DEFAULT_MAX_ZOOM)

        return transform
    }
}

}
