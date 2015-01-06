package model
{
	import flash.display.BitmapData;
	import flash.geom.Point;
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
		/**
		 * 偏移X
		 */
		public var offsetXs:Vector.<int>;
		/**
		 * 偏移Y
		 */
		public var offsetYs:Vector.<int>;
		
		public function ActionVo()
		{
			
		}
	}
}