package 
{
	import com.flashdynamix.utils.SWFProfiler;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.system.System;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.utils.Timer;
	import org.openzoom.flash.components.MemoryMonitor;
	import org.openzoom.flash.components.MultiScaleImage;
	import org.openzoom.flash.viewport.controllers.MouseController;
	import org.openzoom.flash.viewport.transformers.TweenerTransformer;
	
	/**
	 * ...
	 * @author josh
	 */
	public class Main extends Sprite 
	{
		private var image:MultiScaleImage;
		private var timer:Timer;
		private var memoryMonitor:MemoryMonitor;
		
		private var m_log:TextField;
		
		public function Main():void 
		{
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function createLog():void
		{
			var tf:TextFormat = new TextFormat( "Courier Sans Ms", 12 );
			
			// create our textfield
			this.m_log 						= new TextField;
			this.m_log.defaultTextFormat	= tf;
			this.m_log.width				= 250;
			this.m_log.height				= 300;
			this.m_log.border				= true;
			this.m_log.background			= true;
			this.m_log.x					= this.stage.stageWidth - this.m_log.width;
			this.m_log.wordWrap				= true;
			
			this.stage.addChild( this.m_log );
		}
		
		private function _log( msg:String ):void
		{
			trace( msg );
			this.m_log.appendText( msg + "\n" );
		}
		
		private function init(e:Event = null):void 
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			// entry point
			createLog();
			
			MemoryTracker.stage = this.stage;
			MemoryTracker.debugTextField = m_log;
			
			this._log("Starting up memory tracker test.");
			/*memoryMonitor = new MemoryMonitor();
			addChild(memoryMonitor);*/
			
			//SWFProfiler.init(stage, this);
			
			timer = new Timer(5 * 1000, 1);
			timer.addEventListener(TimerEvent.TIMER, loadUpNewImage);
			timer.start();
		}
		
		private function image_completeHandler(e:Event):void 
		{
			image.removeEventListener(Event.COMPLETE, image_completeHandler)
			trace("image complete");
			timer.addEventListener(TimerEvent.TIMER, onTimer);
			timer.reset();
			timer.start();
		}
		
		private function onTimer(e:TimerEvent):void 
		{
			timer.removeEventListener(TimerEvent.TIMER, onTimer);
			trace("clearing new image.");
			removeChild(image);
			image.controllers = [];
			image.transformer.dispose();
			image.dispose();
			image = null;
			
			
			MemoryTracker.gcAndCheck();
			//trace("Forcing garbage collection,");
			//System.gc();
			//System.gc();
			//trace("Memory now:", System.totalMemory / 1024);
			
			timer.addEventListener(TimerEvent.TIMER, loadUpNewImage);
			timer.reset();
			timer.start();
		}
		
		private function loadUpNewImage(e:TimerEvent = null):void 
		{
			timer.removeEventListener(TimerEvent.TIMER, loadUpNewImage);
			trace("loading new image. System memory:", System.totalMemory / 1024, "kb");
			image = new MultiScaleImage();
			if (!image.hasEventListener(Event.COMPLETE))
				image.addEventListener(Event.COMPLETE, image_completeHandler)
				
			var transformer:TweenerTransformer = new TweenerTransformer()
			transformer.easing = "EaseOut";
			transformer.duration = 1 // seconds
			
			image.transformer = transformer;
			var controller:MouseController = new MouseController()
			MemoryTracker.track(controller, "Mouse controller.");
			image.controllers = [controller]
			
			image.width = 500;
			image.height = 500;
			
			image.source = "../../../gwas/development/bin/library/assets/deepzoom/space.xml";
			addChild(image);
			//setChildIndex(memoryMonitor, numChildren - 1);
		}
		
	}
	
}