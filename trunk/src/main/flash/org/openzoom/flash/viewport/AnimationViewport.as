////////////////////////////////////////////////////////////////////////////////
//
//  OpenZoom
//
//  Copyright (c) 2007–2008, Daniel Gasienica <daniel@gasienica.ch>
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
package org.openzoom.flash.viewport
{

import flash.events.Event;
import flash.events.EventDispatcher;
import flash.geom.Point;
import flash.geom.Rectangle;

import mx.core.UIComponent;

import org.openzoom.flash.events.ViewportEvent;
import org.openzoom.flash.scene.IMultiScaleScene;
import org.openzoom.flash.scene.IReadonlyMultiScaleScene;
import org.openzoom.flash.viewport.constraints.NullViewportConstraint;
import org.openzoom.flash.viewport.transformers.NullViewportTransformer;
import org.openzoom.flash.viewport.transformers.TransformShortcuts;
import org.openzoom.flash.viewport.transformers.TweenerViewportTransformer;

//------------------------------------------------------------------------------
//
//  Events
//
//------------------------------------------------------------------------------

[Event(name="resize", type="org.openzoom.events.ViewportEvent")]
[Event(name="transformStart", type="org.openzoom.events.ViewportEvent")]
[Event(name="transform", type="org.openzoom.events.ViewportEvent")]
[Event(name="transformEnd", type="org.openzoom.events.ViewportEvent")]

/**
 * IViewport implementation that is based on a normalized [0, 1] coordinate system.
 * Features an advanced mechanism for efficient viewport animations.
 */
public class AnimationViewport extends EventDispatcher
                               implements INormalizedViewport,
                                          IReadonlyViewport,
                                          IViewportContainer,
                                          ITransformerViewport
{
    //--------------------------------------------------------------------------
    //
    //  Class constants
    //
    //--------------------------------------------------------------------------

    private static const NULL_CONSTRAINT  : IViewportConstraint  = new NullViewportConstraint()
    private static const NULL_TRANSFORMER : IViewportTransformer = new NullViewportTransformer()

    //--------------------------------------------------------------------------
    //
    //  Constructor
    //
    //--------------------------------------------------------------------------

    /**
     * Constructor.
     */
    public function AnimationViewport( width : Number, height : Number,
                                       scene : IMultiScaleScene )
    {
    	// FIXME
        TransformShortcuts.init()
        
    	_viewportWidth = width
    	_viewportHeight = height
    	
        _scene = scene
        _scene.addEventListener( Event.RESIZE, scene_resizeHandler, false, 0, true )
        
//        constraint = new DefaultViewportConstraint()
        
        // FIXME: Unsafe cast
        _transform = new ViewportTransform( this, IReadonlyMultiScaleScene( scene ))
        
        // FIXME
        _transformer = new TweenerViewportTransformer()
        _transformer.viewport = this
        
        validate()
    }

    //--------------------------------------------------------------------------
    //
    //  Properties
    //
    //--------------------------------------------------------------------------

    //----------------------------------
    //  zoom
    //----------------------------------

    [Bindable(event="transformUpdate")]
    public function get zoom() : Number
    {
        return _transform.zoom
    }

    public function set zoom( value : Number ) : void
    {
        zoomTo( value )
    }

    //----------------------------------
    //  scale
    //----------------------------------

    [Bindable(event="transformUpdate")]
    public function get scale() : Number
    {
        return viewportWidth / ( scene.sceneWidth * width ) 
    }
 
    //----------------------------------
    //  constraint
    //----------------------------------
    
    private var _constraint : IViewportConstraint = NULL_CONSTRAINT

    public function get constraint() : IViewportConstraint
    {
        return _constraint
    }
    
    public function set constraint( value : IViewportConstraint ) : void
    {
        if( value )
           _constraint = value
        else
           _constraint = NULL_CONSTRAINT
    }

    //----------------------------------
    //  transformer
    //----------------------------------

    private var _transformer : IViewportTransformer

    public function get transformer() : IViewportTransformer
    {
        return _transformer
    }

    public function set transformer( value : IViewportTransformer ) : void
    {
    	_transformer.stop()
    	
        if( value )
           _transformer = value
        else
           _transformer = NULL_TRANSFORMER
           
        _transformer.viewport = this
    }

    //----------------------------------
    //  transform
    //----------------------------------

    private var _transform : IViewportTransform

    public function get transform() : IViewportTransform
    {   	
    	return _transform.clone()
    }

    public function set transform( value : IViewportTransform ) : void
    {
        var oldTransform : IViewportTransform = _transform.clone()
        _transform = value.clone()
        
        var position : Point = constraint.computePosition( this )
        _transform.moveTo( position.x, position.y )

        dispatchUpdateTransformEvent( oldTransform )
    }
    
    //----------------------------------
    //  scene
    //----------------------------------
    
    /**
     * @private
     * Storage for the scene property.
     */
    private var _scene : IMultiScaleScene

    /**
     * @inheritDoc
     */ 
    public function get scene() : IMultiScaleScene
    {
        return _scene
    }
    
    //----------------------------------
    //  viewportWidth
    //----------------------------------
    
    /**
     * @private
     * Storage for the viewportWidth property.
     */
    private var _viewportWidth : Number
    
    [Bindable(event="viewportWidthChanged")]
    
    /**
     * @inheritDoc
     */
    public function get viewportWidth() : Number
    {
        return _viewportWidth
    }
    
    //----------------------------------
    //  viewportHeight
    //----------------------------------
    
    /**
     * @private
     * Storage for the viewportHeight property.
     */
    private var _viewportHeight : Number
    
    [Bindable(event="viewportHeightChanged")]
    
    /**
     * @inheritDoc
     */
    public function get viewportHeight() : Number
    {
        return _viewportHeight
    }

    //--------------------------------------------------------------------------
    //
    //  Methods: Zooming
    //
    //--------------------------------------------------------------------------

    /**
     * @inheritDoc
     */
    public function zoomTo( zoom : Number,
                            transformX : Number = 0.5,
                            transformY : Number = 0.5,
                            dispatchChangeEvent : Boolean = true ) : void
    {
    	var t : IViewportTransform = getViewportTransform()
        t.zoomTo( zoom, transformX, transformY )
        applyTransform( t )
    }
    
    /**
     * @inheritDoc
     */
    public function zoomBy( factor : Number,
                            transformX : Number = 0.5,
                            transformY : Number = 0.5,
                            dispatchChangeEvent : Boolean = true ) : void
    {
        var t : IViewportTransform = getViewportTransform()
    	t.zoomBy( factor, transformX, transformY )
        applyTransform( t )
    }

    //--------------------------------------------------------------------------
    //
    //  Methods: Panning
    //
    //--------------------------------------------------------------------------

    /**
     * @inheritDoc
     */
    public function moveTo( x : Number, y : Number,
                            dispatchChangeEvent : Boolean = true ) : void
    {
        var t : IViewportTransform = getViewportTransform()
        t.moveTo( x, y )
        applyTransform( t )
    }
    
    /**
     * @inheritDoc
     */
    public function moveBy( dx : Number, dy : Number,
                            dispatchChangeEvent : Boolean = true ) : void
    {
        var t : IViewportTransform = getViewportTransform()
        t.moveBy( dx, dy )
        applyTransform( t )
    }

    /**
     * @inheritDoc
     */
    public function moveCenterTo( x : Number, y : Number,
                                  dispatchChangeEvent : Boolean = true ) : void
    {
        var t : IViewportTransform = getViewportTransform()
        t.moveCenterTo( x, y )
        applyTransform( t )
    }

    /**
     * @inheritDoc
     */
    public function showRect( rect : Rectangle, scale : Number = 1.0, 
                              dispatchChangeEvent : Boolean = true ) : void
    {
        var t : IViewportTransform = getViewportTransform()
        t.showRect( rect, scale )
        applyTransform( t )
    }
    
    /**
     * @inheritDoc
     */
    public function showAll() : void
    {
        var t : IViewportTransform = getViewportTransform()
        t.showAll()
        applyTransform( t )
    }

    //--------------------------------------------------------------------------
    //
    //  Methods: Coordinate transformations
    //
    //--------------------------------------------------------------------------

    /**
     * @inheritDoc
     */ 
    public function localToScene( point : Point ) : Point
    {
        var p : Point = new Point()
        p.x = ( x * scene.sceneWidth ) 
              + ( point.x / viewportWidth )  * ( width  * scene.sceneWidth )
        p.y = ( y * scene.sceneHeight )
              + ( point.y / viewportHeight ) * ( height * scene.sceneHeight )
        return p
    }
    
    /**
     * @inheritDoc
     */
    public function sceneToLocal( point : Point ) : Point
    {
        var p : Point = new Point()
        p.x = ( point.x - ( x  * scene.sceneWidth ))
              / ( width  * scene.sceneWidth ) * viewportWidth
        p.y = ( point.y - ( y  * scene.sceneHeight ))
              / ( height * scene.sceneHeight ) * viewportHeight
        return p
    }

    /**
     * @private
     * 
     * Validate the viewport.
     */ 
    private function validate( dispatchEvent : Boolean = true ) : void
    {
        var t : IViewportTransform = getViewportTransform()
        t.zoomTo( zoom )
        applyTransform( t, true )
    }
    
    /**
     * @private
     */
    private function applyTransform( transform : IViewportTransform,
                                     immediately : Boolean = false ) : void
    {
        transformer.transform( transform, immediately )
    }

    //--------------------------------------------------------------------------
    //
    //  Methods: IViewport (scene coordinate system )
    //
    //--------------------------------------------------------------------------
    
    /**
     * @inheritDoc
     */
    public function contains( x : Number, y : Number ) : Boolean
    {
        return ( x >= left ) && ( x <= right ) && ( y >= top ) && ( y <= bottom )
    }
    
    /**
     * @inheritDoc
     */
    public function intersects( toIntersect : Rectangle ) : Boolean
    {
    	// FIXME
    	var sceneViewport : Rectangle = new Rectangle( x * scene.sceneWidth,
                                                       y * scene.sceneHeight, 
                                                       width * scene.sceneWidth,
                                                       height * scene.sceneHeight )
        return sceneViewport.intersects( denormalizeRectangle( toIntersect ))
    }
    
    /**
     * @inheritDoc
     */
    public function intersection( toIntersect : Rectangle ) : Rectangle
    {
    	// FIXME
        var sceneViewport : Rectangle = new Rectangle( x * scene.sceneWidth,
                                                       y * scene.sceneHeight, 
                                                       width * scene.sceneWidth,
                                                       height * scene.sceneHeight )
        return sceneViewport.intersection( denormalizeRectangle( toIntersect ))
    }

    //--------------------------------------------------------------------------
    //
    //  Properties: IViewport
    //
    //--------------------------------------------------------------------------
    
    //----------------------------------
    //  x
    //----------------------------------
    
    [Bindable(event="transformUpdate")]
    
    /**
     * @inheritDoc
     */
    public function get x() : Number
    {
        return _transform.x
    }
    
    /**
     * @inheritDoc
     */
    public function set x( value : Number ) : void
    {
    	// TODO
    }
    
    //----------------------------------
    //  y
    //----------------------------------
    
    [Bindable(event="transformUpdate")]
    
    /**
     * @inheritDoc
     */
    public function get y() : Number
    {
       return _transform.y
    }
    
    /**
     * @inheritDoc
     */
    public function set y( value : Number ) : void
    {
    	// TODO
    }
    
    //----------------------------------
    //  width
    //----------------------------------
    
    [Bindable(event="transformUpdate")]
    
    /**
     * @inheritDoc
     */
    public function get width() : Number
    {
        return _transform.width
    }
    
    //----------------------------------
    //  height
    //----------------------------------
    
    [Bindable(event="transformUpdate")]
    
    /**
     * @inheritDoc
     */
    public function get height() : Number
    {
        return _transform.height
    }
    
    //----------------------------------
    //  left
    //----------------------------------
    
    [Bindable(event="transformUpdate")]
    
    /**
     * @inheritDoc
     */
    public function get left() : Number
    {
        return _transform.left
    }
    
    //----------------------------------
    //  right
    //----------------------------------
    
    [Bindable(event="transformUpdate")]
    
    /**
     * @inheritDoc
     */
    public function get right() : Number
    {
        return _transform.right
    }
    
    //----------------------------------
    //  top
    //----------------------------------
    
    [Bindable(event="transformUpdate")]
    
    /**
     * @inheritDoc
     */
    public function get top() : Number
    {
        return _transform.top
    }
    
    //----------------------------------
    //  bottom
    //----------------------------------
    
    [Bindable(event="transformUpdate")]
    
    /**
     * @inheritDoc
     */
    public function get bottom() : Number
    {
        return _transform.bottom
    }

    //--------------------------------------------------------------------------
    //
    //  Methods: Transform Events
    //
    //--------------------------------------------------------------------------
    
    /**
     * @inheritDoc
     */
    public function beginTransform() : void
    {
        dispatchEvent( new ViewportEvent( ViewportEvent.TRANSFORM_START ))
    }
    
    /**
     * @private
     */
    private function dispatchUpdateTransformEvent( oldTransform : IViewportTransform
                                                       = null ) : void
    {
        dispatchEvent( new ViewportEvent( ViewportEvent.TRANSFORM_UPDATE,
                           false, false, oldTransform ))
    }
    
    /**
     * @inheritDoc
     */
    public function endTransform() : void
    {
        dispatchEvent( new ViewportEvent( ViewportEvent.TRANSFORM_END ))
    }
    
    //--------------------------------------------------------------------------
    //
    //  Methods: Internal
    //
    //--------------------------------------------------------------------------
    
    /**
     * @private
     */ 
    private function getViewportTransform() : IViewportTransform
    {
        var t : IViewportTransform = transformer.target
        return t
    }
    
    //--------------------------------------------------------------------------
    //
    //  Methods: IViewportContainer
    //
    //--------------------------------------------------------------------------
    
    /**
     * @inheritDoc
     */
    public function setSize( width : Number, height : Number ) : void
    {
        if( _viewportWidth == width && _viewportHeight == height )
            return
        
        _viewportWidth = width
        _viewportHeight = height
        validate( false )
        
        dispatchEvent( new ViewportEvent( ViewportEvent.RESIZE, false, false ))
    }
    
    //--------------------------------------------------------------------------
    //
    //  Methods: Coordinate conversion
    //
    //--------------------------------------------------------------------------
    
    /**
     * @private
     */ 
    private function normalizeX( value : Number ) : Number
    {
        return value / scene.sceneWidth
    }

    /**
     * @private
     */
    private function normalizeY( value : Number ) : Number
    {
        return value / scene.sceneHeight
    }
    
    /**
     * @private
     */
    private function normalizeRectangle( value : Rectangle ) : Rectangle
    {
        return new Rectangle( normalizeX( value.x ),
                              normalizeY( value.y ),
                              normalizeX( value.width ),
                              normalizeY( value.height ))
    }
    
    /**
     * @private
     */
    private function normalizePoint( value : Point ) : Point
    {
        return new Point( normalizeX( value.x ),
                          normalizeY( value.y ))
    }
    
    /**
     * @private
     */ 
    private function denormalizeX( value : Number ) : Number
    {
        return value * scene.sceneWidth
    }

    /**
     * @private
     */
    private function denormalizeY( value : Number ) : Number
    {
        return value * scene.sceneHeight
    }
    
    /**
     * @private
     */
    private function denormalizePoint( value : Point ) : Point
    {
        return new Point( denormalizeX( value.x ),
                          denormalizeY( value.y ))
    }
    
    /**
     * @private
     */
    private function denormalizeRectangle( value : Rectangle ) : Rectangle
    {
        return new Rectangle( denormalizeX( value.x ),
                              denormalizeY( value.y ),
                              denormalizeX( value.width ),
                              denormalizeY( value.height ))
    }
    
    //--------------------------------------------------------------------------
    //
    //  Event handlers
    //
    //--------------------------------------------------------------------------
    
    /**
     * @private
     */
    private function scene_resizeHandler( event : Event ) : void
    {
    	validate()
    }
    
    //--------------------------------------------------------------------------
    //
    //  Methods: Debug
    //
    //--------------------------------------------------------------------------
    
    /**
     * @inheritDoc
     */
    override public function toString() : String
    {
        return "[AnimationViewport]" + "\n"
               + "x=" + x + "\n" 
               + "y=" + y  + "\n"
               + "z=" + zoom + "\n"
               + "w=" + width + "\n"
               + "h=" + height + "\n"
               + "sW=" + scene.sceneWidth + "\n"
               + "sH=" + scene.sceneHeight
    }
}

}