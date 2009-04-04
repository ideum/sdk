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
package org.openzoom.flex.components
{

import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.SecurityErrorEvent;
import flash.net.URLLoader;
import flash.net.URLRequest;

import org.openzoom.flash.descriptors.IMultiScaleImageDescriptor;
import org.openzoom.flash.descriptors.MultiScaleImageDescriptorFactory;
import org.openzoom.flash.renderers.MultiScaleImageRenderer;

/**
 *  Dispatched when the image has successfully loaded.
 *
 *  @eventType flash.events.Event.COMPLETE
 */
[Event(name="complete", type="flash.events.Event")]

/**
 *  Dispatched when an IO error has occured while loading the image.
 *
 *  @eventType flash.events.IOErrorEvent.IO_ERROR
 */
[Event(name="ioError", type="flash.events.IOErrorEvent")]

/**
 *  Dispatched when an security error has occured while loading the image.
 *
 *  @eventType flash.events.SecurityErrorEvent.SECURITY_ERROR
 */
[Event(name="securityError", type="flash.events.SecurityErrorEvent")]

/**
 * Flex component for displaying a single multiscale image.
 * Inspired by the <a href="http://msdn.microsoft.com/en-us/library/system.windows.controls.multiscaleimage(VS.95).aspx">
 * Microsoft Silverlight Deep Zoom MultiScaleImage control.</a>
 * This implementation has built-in support for Zoomify, Deep Zoom and OpenZoom images.
 * Basic keyboard and mouse navigation can be added by specifying viewport controllers through the <code>controllers</code> property.
 * The animation can be customized by adding a viewport transformer through the <code>transformer</code> property.
 * Zoom, visibility or custom constraints can be added through the <code>constraint</code> property.
 */
public final class MultiScaleImage extends MultiScaleImageBase
{
    //--------------------------------------------------------------------------
    //
    //  Constructor
    //
    //--------------------------------------------------------------------------

    /**
     * Constructor.
     */
    public function MultiScaleImage()
    {
        super()

//      tabEnabled = false
//      tabChildren = true
    }

    //--------------------------------------------------------------------------
    //
    //  Variables
    //
    //--------------------------------------------------------------------------

    private var url:String
    private var urlLoader:URLLoader

    private var image:MultiScaleImageRenderer

    //--------------------------------------------------------------------------
    //
    //  Properties
    //
    //--------------------------------------------------------------------------

    //----------------------------------
    //  source
    //----------------------------------

    private var _source:IMultiScaleImageDescriptor

    [Bindable(event="sourceChanged")]

    /**
     * Source of this image. Either a URL as String or an
     * instance of IMultiScaleImageDescriptor.
     *
     * @see org.openzoom.flash.descriptors.IMultiScaleImageDescriptor
     */
    public function get source():Object
    {
        return _source
    }

    public function set source(value:Object):void
    {
        if (_source)
        {
            _source = null

            if (container.numChildren > 0)
                container.removeChildAt(0)
        }

        if (value is String)
        {
            if (url == String(value))
                return

            url = String(value)
            urlLoader = new URLLoader(new URLRequest(url))

            urlLoader.addEventListener(Event.COMPLETE,
                                       urlLoader_completeHandler,
                                       false, 0, true)
            urlLoader.addEventListener(IOErrorEvent.IO_ERROR,
                                       urlLoader_ioErrorHandler,
                                       false, 0, true)
            urlLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR,
                                       urlLoader_securityErrorHandler,
                                       false, 0, true)
        }

        if (value is IMultiScaleImageDescriptor)
        {
            _source = IMultiScaleImageDescriptor(value).clone()
            dispatchEvent(new Event("sourceChanged"))

            addImage(_source)
        }
    }

    //--------------------------------------------------------------------------
    //
    //  Methods: Internal
    //
    //--------------------------------------------------------------------------

    /**
     * @private
     */
    private function addImage(descriptor:IMultiScaleImageDescriptor):void
    {
        var aspectRatio:Number = descriptor.width / descriptor.height
        var sceneWidth:Number
        var sceneHeight:Number

        if (aspectRatio > 1)
        {
            sceneWidth  = DEFAULT_SCENE_DIMENSION
            sceneHeight = DEFAULT_SCENE_DIMENSION / aspectRatio
        }
        else
        {
            sceneWidth  = DEFAULT_SCENE_DIMENSION * aspectRatio
            sceneHeight = DEFAULT_SCENE_DIMENSION
        }

        // resize scene
        container.sceneWidth  = sceneWidth
        container.sceneHeight = sceneHeight

        // create renderer
        image = new MultiScaleImageRenderer(descriptor, container.loader,
                                            sceneWidth, sceneHeight)
        container.addChild(image)
        container.showAll(true)
    }


    //--------------------------------------------------------------------------
    //
    //  Event handlers
    //
    //--------------------------------------------------------------------------

    /**
     * @private
     */
    private function urlLoader_completeHandler(event:Event):void
    {
        if (!urlLoader || !urlLoader.data)
            return

        var data:XML = new XML(urlLoader.data)
        var factory:MultiScaleImageDescriptorFactory =
                          MultiScaleImageDescriptorFactory.getInstance()
        var descriptor:IMultiScaleImageDescriptor =
                             factory.getDescriptor(url, data)

        _source = descriptor
        dispatchEvent(new Event("sourceChanged"))

        addImage(descriptor)

        dispatchEvent(event.clone())
    }

    /**
     * @private
     */
    private function urlLoader_ioErrorHandler(event:IOErrorEvent):void
    {
        dispatchEvent(event)
    }

    /**
     * @private
     */
    private function urlLoader_securityErrorHandler(event:SecurityErrorEvent):void
    {
        dispatchEvent(event)
    }
}

}