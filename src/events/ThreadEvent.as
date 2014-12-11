package events
{
	import flash.events.Event;
	
	/**
	 * ...
	 * @author WorrySprite
	 */
	public class ThreadEvent extends Event
	{
		public static const THREAD_STATE:String = "thread_state";
		
		private var _msg:Array;
		
		public function ThreadEvent(type:String, msg:Array, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			_msg = msg;
		}
		
		public override function clone():Event
		{
			return new ThreadEvent(type, _msg, bubbles, cancelable);
		}
		
		public override function toString():String
		{
			return formatToString("ThreadEvent", "type", "bubbles", "cancelable", "eventPhase");
		}
		
		/**
		 * 子线程发来的消息，索引0是消息号，后面是消息参数
		 */
		public function get msg():Array
		{
			return _msg;
		}
	}
}