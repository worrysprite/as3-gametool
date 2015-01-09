package enum
{
	/**
	 * 错误码
	 * @author WorrySprite
	 */
	public class ErrorCodeEnum
	{
		/**
		 * 资源文件夹里没有有效资源文件
		 */
		public static const EMPTY_RESOURCE_DIRECTORY:int = 10000;
		/**
		 * 位图超出尺寸
		 */
		public static const BITMAP_OUT_OF_SIZE:int = 10001;
		
		public static function getErrorMsg(errorCode:int):String
		{
			switch(errorCode)
			{
				case 3001:
					return "读写文件失败，拒绝访问。";
					
				case EMPTY_RESOURCE_DIRECTORY:
					return "资源目录中没有可处理的文件。";
					
				case BITMAP_OUT_OF_SIZE:
					return "位图超出有效尺寸。";
					
				default:
					return "未知错误" + errorCode + "，请报告至worrysprite@gmail.com";
			}
		}
	}

}