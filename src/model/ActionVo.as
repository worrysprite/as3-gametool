package model
{
	import flash.display.BitmapData;
	/**
	 * 动作VO
	 * @author WorrySprite
	 */
	public class ActionVo
	{
		/**
		 * 索引
		 */
		public var index:int;
		/**
		 * 资源路径
		 */
		public var directory:String;
		/**
		 * 帧间隔(毫秒)
		 */
		public var interval:uint;
		/**
		 * 相关图片
		 */
		public var bitmaps:Vector.<BitmapData>;
		
		public function ActionVo()
		{
			
		}
	}
}