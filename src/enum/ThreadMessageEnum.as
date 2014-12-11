package enum
{
	/**
	 * 线程消息枚举
	 * @author WorrySprite
	 */
	public class ThreadMessageEnum
	{
		/**
		 * 进度消息，含有3个参数：
		 * int	当前进度
		 * int	总进度
		 * String	进度信息
		 */
		public static const STATE_PROGRESS:int = 1;
		/**
		 * 后台完成消息，含有1个参数：
		 * Boolean	是否成功
		 */
		public static const STATE_COMPLETE:int = 2;
		/**
		 * 跟踪调试信息，含有1个参数：
		 * String	调试信息内容
		 */
		public static const STATE_TRACE:int = 3;
		
		/**
		 * 压缩PNG消息，含有4个参数：
		 * String	源文件夹url
		 * String	目标文件夹url
		 * int	品质
		 * Boolean	合并为单个文件
		 */
		public static const COMMAND_COMPRESS_PNG:int = 101;
	}

}