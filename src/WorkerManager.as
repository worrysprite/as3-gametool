package
{
	import enum.ThreadMessageEnum;
	import events.ThreadEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.system.MessageChannel;
	import flash.system.Worker;
	import flash.system.WorkerDomain;
	import flash.system.WorkerState;
	import flash.utils.ByteArray;
	/**
	 * 后台工作线程管理
	 * @author WorrySprite
	 */
	public class WorkerManager
	{
		public static const listener:EventDispatcher = new EventDispatcher();
		
		[Embed(source="WorkerProject.swf", mimeType="application/octet-stream")]
		private static var WorkerProjectClass:Class;
		private static var bgWorker:Worker;
		private static var commandChannel:MessageChannel;
		private static var stateChannel:MessageChannel;
		
		public static function init():void
		{
			var workerBytes:ByteArray = new WorkerProjectClass();
			bgWorker = WorkerDomain.current.createWorker(workerBytes, true);
			commandChannel = Worker.current.createMessageChannel(bgWorker);
			bgWorker.setSharedProperty("CommandChannel", commandChannel);
			
			stateChannel = bgWorker.createMessageChannel(Worker.current);
			stateChannel.addEventListener(Event.CHANNEL_MESSAGE, onStateMessage);
			bgWorker.setSharedProperty("StateChannel", stateChannel);
			bgWorker.start();
		}
		
		/**
		 * 发送命令消息给子线程，
		 * @param	msg	索引0为消息号，后面是参数
		 */
		public static function sendMessage(msg:Array):void
		{
			if (bgWorker.state == WorkerState.RUNNING)
			{
				commandChannel.send(msg);
			}
		}
		
		static private function onStateMessage(e:Event):void
		{
			while (stateChannel.messageAvailable)
			{
				var msg:Array = stateChannel.receive() as Array;
				if (msg[0] == ThreadMessageEnum.STATE_TRACE)
				{
					trace("sub thread:", msg[1]);
				}
				else
				{
					listener.dispatchEvent(new ThreadEvent(ThreadEvent.THREAD_STATE, msg));
				}
			}
		}
	}
}