package src.model
{
	import flash.display.BitmapData;
	import flash.geom.Rectangle;
	/**
	 * 除去了透明边的PNG图片
	 * @author WorrySprite
	 */
	public class FrameData
	{
		/**
		 * 图片原始宽度，包含透明区域
		 */
		public var originWidth:int;
		/**
		 * 图片原始高度，包含透明区域
		 */
		public var originHeight:int;
		/**
		 * 有效像素区域
		 */
		public var rect:Rectangle;
		/**
		 * 有效像素图片数据
		 */
		public var bitmapData:BitmapData;
		
		public function FrameData()
		{
			
		}
	}
}