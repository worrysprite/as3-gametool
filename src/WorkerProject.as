package
{
	import controller.CompressPNGController;
	import controller.CutBitmapController;
	import enum.ThreadMessageEnum;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.system.MessageChannel;
	import flash.system.Worker;
	/**
	 * 工作线程
	 * @author WorrySprite
	 */
	public class WorkerProject extends Sprite
	{
		private static var _instance:WorkerProject;
		private var commandChannel:MessageChannel;
		private var stateChannel:MessageChannel;
		
		public function WorkerProject()
		{
			if (_instance)
			{
				throw new Error();
			}
			_instance = this;
			commandChannel = Worker.current.getSharedProperty("CommandChannel") as MessageChannel;
			commandChannel.addEventListener(Event.CHANNEL_MESSAGE, onCommand);
			stateChannel = Worker.current.getSharedProperty("StateChannel") as MessageChannel;
		}
		
		private function onCommand(e:Event):void
		{
			while (commandChannel.messageAvailable)
			{
				var msg:Array = commandChannel.receive() as Array;
				//trace("command recv:" + msg[0]);
				switch(msg[0])
				{
					case ThreadMessageEnum.COMMAND_COMPRESS_PNG:
						CompressPNGController.compress(msg[1], msg[2], msg[3], msg[4]);
						break;
						
					case ThreadMessageEnum.COMMAND_CUT_MAP:
						CutBitmapController.split(msg[1], msg[2], msg[3], msg[4], msg[5]);
						break;
				}
			}
		}
		
		public static function sendMessage(msg:Array):void
		{
			_instance.stateChannel.send(msg);
		}
		
		public static function trace(info:String):void
		{
			_instance.stateChannel.send([ThreadMessageEnum.STATE_TRACE, info]);
		}
	}

}