package org.openzoom.flash.components {
	import com.gestureworks.core.TouchSprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import org.openzoom.flash.descriptors.IImagePyramidDescriptor;
	import org.openzoom.flash.renderers.images.ImagePyramidRenderer;
	import org.openzoom.flash.viewport.constraints.CenterConstraint;
	import org.openzoom.flash.viewport.constraints.CompositeConstraint;
	import org.openzoom.flash.viewport.constraints.ScaleConstraint;
	import org.openzoom.flash.viewport.constraints.VisibilityConstraint;
	import org.openzoom.flash.viewport.constraints.ZoomConstraint;
	import org.openzoom.flash.viewport.transformers.TweenerTransformer;
	import org.openzoom.flash.utils.uri.resolveURI;

	public final class MultiScaleImage extends MultiScaleImageBase {
		
		private var image:ImagePyramidRenderer;
		private var urlLoader:URLLoader;
		private var transformer:TweenerTransformer;
		private var constraint:CompositeConstraint;
		private var zoomConstraint:ZoomConstraint;
		private var scaleConstraint:ScaleConstraint;
		private var centerConstraint:CenterConstraint;
		private var visibilityConstraint:VisibilityConstraint;
		
		public function MultiScaleImage(minZoom:Number = 0.1, minScale:Number = 0.001, visibilityRatio:Number = 0.6) {
			super();
			image = new ImagePyramidRenderer();
			constraint = new CompositeConstraint();
			zoomConstraint = new ZoomConstraint();
			zoomConstraint.minZoom = minZoom;
			scaleConstraint = new ScaleConstraint();
			scaleConstraint.minScale = minScale;
			centerConstraint = new CenterConstraint();
			visibilityConstraint = new VisibilityConstraint();
			visibilityConstraint.visibilityRatio = visibilityRatio;
			constraint.constraints = [zoomConstraint, scaleConstraint, centerConstraint, visibilityConstraint];
			super.constraint = constraint;
		}
		
		private function disposeImage():void {
			if(image) {
				image.dispose()
				image = null
    	}
		}
		
		private function disposeLoader():void {
			if (urlLoader) {
				try {
					urlLoader.close()
				} catch(error:Error) {
					// Do nothing
				}
				urlLoader.removeEventListener(Event.COMPLETE, onXMLLoadComplete);
				urlLoader.removeEventListener(IOErrorEvent.IO_ERROR, onXMLIOError);
				urlLoader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onXMLSecurityError);
				urlLoader = null
    	}
		}
		
		override public function dispose():void {
			disposeLoader();
			disposeImage();
			super.dispose();
		}
		
		private function createImage(descriptor:IImagePyramidDescriptor, width:Number, height:Number):ImagePyramidRenderer {
        var image:ImagePyramidRenderer = new ImagePyramidRenderer()
        image.source = descriptor
        image.width = width
        image.height = height
        return image
    }
		
		private function onXMLIOError(event:IOErrorEvent):void {
			dispatchEvent(event);
		}
		
		private function onXMLSecurityError(event:SecurityErrorEvent):void {
			dispatchEvent(event);
		}
		
		private function onXMLLoadComplete(e:Event):void {
			
			//if image <-consider dealing with image after the new xml has been loaded to make it seem smoother
				//disposeImage?
			//TODO: make image...
			//dispatch I_MADE_A_NEW_IMAGE event
		}
		
		public function load(url:String):void {
			disposeLoader();
			//create new URLLoader
			if (loaderInfo) {
				url = resolveURI(loaderInfo.url, url);
			}
			urlLoader = new URLLoader();
			//attach listeners
			urlLoader.addEventListener(Event.COMPLETE, onXMLLoadComplete, false, 0, true);
			urlLoader.addEventListener(IOErrorEvent.IO_ERROR, onXMLIOError, false, 0, true);
			urlLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onXMLSecurityError, false, 0, true);
			//start loader
			urlLoader.load(new URLRequest(url));
		}
		
	}
}
