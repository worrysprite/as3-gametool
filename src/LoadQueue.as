package
{
	import flash.display.DisplayObject;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.net.URLRequest;

	public class LoadQueue extends EventDispatcher
	{
		private static var _instance:LoadQueue;
		
		private var loader:Loader;
		private var request:URLRequest;
		private var idle:Boolean = true;
		
		private var loadList:Vector.<String>;
		
		public var completeList:Vector.<DisplayObject>;
		
		public function LoadQueue()
		{
			if (_instance != null)
			{
				throw new Error("singleton error");
			}
			_instance = this;
			init();
		}
		
		public static function getInstance():LoadQueue
		{
			if (_instance == null)
			{
				_instance = new LoadQueue();
			}
			return _instance;
		}
		
		private function init():void
		{
			loadList = new Vector.<String>();
			completeList = new Vector.<DisplayObject>();
			
			loader = new Loader();
			request = new URLRequest();
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoaded);
			loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onLoadError);
		}
		
		public function loadImage(url:String):void
		{
			loadList.push(url);
			if (idle)
			{
				loadNext();
			}
		}
		
		public function loadImageList(urlList:Vector.<String>):void
		{
			loadList = urlList.slice();
			if (idle)
			{
				loadNext();
			}
		}
		
		private function onLoaded(evt:Event):void
		{
			var info:LoaderInfo = evt.target as LoaderInfo;
			trace("加载成功", info.url);
			completeList.push(info.content);
			loadNext();
		}
		
		private function onLoadError(evt:IOErrorEvent):void
		{
			trace("文件加载失败：", LoaderInfo(evt.target).url);
			loadNext();
		}
		
		private function loadNext():void
		{
			if (loadList.length)
			{
				idle = false;
				request.url = loadList.shift();
				loader.load(request);
			}
			else
			{
				idle = true;
				trace("-----队列加载完毕-----");
				dispatchEvent(new Event(Event.COMPLETE));
			}
		}
	}
}