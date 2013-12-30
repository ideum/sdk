package org.openzoom.flash.viewport.controllers
{
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TouchEvent;
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Timer;
	import org.libspark.betweenas3.core.tweens.actions.RemoveFromParentAction;

	import org.openzoom.flash.core.openzoom_internal;
	import org.openzoom.flash.utils.math.clamp;
	import org.openzoom.flash.viewport.IViewportController;

	import com.gestureworks.events.GWGestureEvent;
	import com.gestureworks.events.GWClusterEvent;
	import com.gestureworks.events.GWTouchEvent;
	import com.gestureworks.core.GestureWorks;

	import org.tuio.TuioTouchEvent;
	
	use namespace openzoom_internal;

/**
 * Touch controller for viewports.
 */
public final class TouchController extends ViewportControllerBase
                                   implements IViewportController
{
	include "../../core/Version.as"

    private static const DEFAULT_TAP_ZOOM_IN_FACTOR:Number = 1.7
    private static const DEFAULT_TAP_ZOOM_OUT_FACTOR:Number = 0.3
    private static const DEFAULT_SCALE_ZOOM_FACTOR:Number = 1.1//1.4

    //--------------------------------------------------------------------------
    //  Constructor
    //--------------------------------------------------------------------------

    /**
     *  Constructor.
     */
    public function TouchController()
    {
       // createClickTimer()
    }

    private var viewDragVector:Rectangle = new Rectangle()
    private var viewportDragVector:Rectangle = new Rectangle()
    private var panning:Boolean = true;
    public var minZoomInFactor:Number = 1
    public var minZoomOutFactor:Number = 1
    public var smoothPanning:Boolean = false;
    public var clickEnabled:Boolean = true
	
	private var n:int = 0;
	private var scaleOn:Boolean = false;
	
    private var _tapZoomInFactor:Number = DEFAULT_TAP_ZOOM_IN_FACTOR
   	private var _tapZoomOutFactor:Number = DEFAULT_TAP_ZOOM_OUT_FACTOR
	private var _scaleZoomFactor:Number = DEFAULT_SCALE_ZOOM_FACTOR
	
	private var distanceX:Number;
	private var distanceY:Number;
	private var targetX:Number;
	private var targetY:Number;
	
 
    public function get tapZoomInFactor():Number
    {
        return _tapZoomInFactor
    }

    public function set tapZoomInFactor(value:Number):void
    {
        _tapZoomInFactor = value
    }
    public function get tapZoomOutFactor():Number
    {
        return _tapZoomOutFactor
    }
    public function set tapZoomOutFactor(value:Number):void
    {
        _tapZoomOutFactor = value
    }
    public function get scaleZoomFactor():Number
    {
        return _scaleZoomFactor
    }
    public function set scaleZoomFactor(value:Number):void
    {
        _scaleZoomFactor = value
    }
    //--------------------------------------------------------------------------
    //  Overridden methods: ViewportControllerBase
    //--------------------------------------------------------------------------
    override protected function view_addedToStageHandler(event:Event):void
    {
		view.gestureEvents = true;
		view.clusterEvents = true;
		view.mouseChildren = false;
		view.nativeTransform = false;
		view.affineTransform = false;
		//view.gestureList = { "1-finger-drag":true, "2-finger-scale":true, "double_tap":true };
		view.gestureList = { "n-drag":true, "n-scale":true, "double_tap":true };
		
		view.addEventListener(GWClusterEvent.C_POINT_REMOVE, view_pointRemoveHandler); // touch end is unreliable
		view.addEventListener(GWGestureEvent.DOUBLE_TAP, view_dTapHandler);	
		view.addEventListener(GWGestureEvent.DRAG, view_dragHandler);
		view.addEventListener(GWGestureEvent.SCALE, view_scaleHandler);
    }
    override protected function view_removedFromStageHandler(event:Event):void
    {
    	if (view)
    	{
	      // panning listeners
			
			view.removeEventListener(GWGestureEvent.DOUBLE_TAP, view_dTapHandler);
			view.removeEventListener(GWClusterEvent.C_POINT_REMOVE, view_pointRemoveHandler);
			
	      // zooming listeners
			view.removeEventListener(GWGestureEvent.DRAG, view_dragHandler);
			view.removeEventListener(GWGestureEvent.SCALE, view_scaleHandler);
    	}
    }
    //--------------------------------------------------------------------------
   
    private function view_scaleHandler(event:GWGestureEvent):void
    {
		//trace("Scaling view_scaleHandler");
		
		if (!panning)
        return
		
		var factor:Number
		//var dsc:Number = event.value.dsx * 0.2;
		var dsc:Number = event.value.scale_dsx * 2;
		
		//factor = clamp(Math.pow(scaleZoomFactor, dsc), 0.5, 3);// clamp sets upper and lower limits
		factor = Math.pow(scaleZoomFactor, dsc);
	
		var originX:Number = event.value.localX / view.width
        var originY:Number = event.value.localY / view.height
		//var originX:Number = event.value.localX
        //var originY:Number = event.value.localY
		
        // transform viewport
        viewport.zoomBy(factor, originX, originY);
    }
	
 	//-----------------------TOUCH DOWN HANDLERS----------------------------
	// These handlers are out of date and commented out currently until further
	// testing is completed to ensure they can be entirely removed.
   /*private function view_touchDownHandler(event:*):void
    {
		//trace("Touch_Begin through view_touchDownHandler");
		
        viewportDragVector.topLeft = new Point(viewport.transformer.target.x,viewport.transformer.target.y)
		viewDragVector.topLeft = new Point(event.value.localX, event.value.localY);
		
		//trace("______________________");
		//trace(event.localX, event.localX);
		//trace(event.stageX, event.stageY);
		
		panning = true
    }
	
	private function tuio_touchDownHandler(event:TuioTouchEvent):void
    {
		//trace("Touch_Begin through tuio_touchDownHandler");
		
        viewportDragVector.topLeft = new Point(viewport.transformer.target.x,viewport.transformer.target.y)
		viewDragVector.topLeft = new Point(event.stageX, event.stageY);
		
		panning = true
    }*/
	//-------------------------TOUCH DOWN HANDLERS END--------------------------------
	
	private function view_touchUpHandler(event:TouchEvent):void
    {
		panning = false
    }
	
	private function view_pointRemoveHandler(event:GWClusterEvent):void
    {
		 panning = false
    }
	
	private function view_dragHandler(event:GWGestureEvent):void
    {
		 if (!panning) {
				// reset vector UPDATES THE CLUSTER POSITION TO AVOID JUMPING WHEN SWITCHING TO DRAG
				viewportDragVector.topLeft = new Point(viewport.transformer.target.x,viewport.transformer.target.y)
				viewDragVector.topLeft = new Point(event.value.localX, event.value.localY);
				panning = true;
            return
		 }
		 
			viewportDragVector.topLeft = new Point(viewport.transformer.target.x,viewport.transformer.target.y)
			viewDragVector.topLeft = new Point(event.value.localX, event.value.localY);

			viewDragVector.bottomRight = new Point(event.value.localX + event.value.drag_dx, event.value.localY + event.value.drag_dy)
			
			distanceX = viewDragVector.width / viewport.viewportWidth;
			distanceY = viewDragVector.height / viewport.viewportHeight;
			
			targetX = viewportDragVector.x - (distanceX * viewport.width);
			targetY = viewportDragVector.y - (distanceY * viewport.height);
			
			viewport.panTo(targetX, targetY, false);
			
			//trace("drag", event.value.stageX, event.value.stageY );
    }
	
	 private function view_dTapHandler(event:GWGestureEvent):void
    {
        var factor:Number = tapZoomInFactor
		viewport.zoomBy(factor, event.value.localX/view.width, event.value.localY/view.height);
    }


}
}
