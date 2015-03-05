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
		 * 后台完成消息
		 */
		public static const STATE_COMPLETE:int = 2;
		/**
		 * 跟踪调试信息，含有1个参数：
		 * String	调试信息内容
		 */
		public static const STATE_TRACE:int = 3;
		/**
		 * 错误信息，含有1个参数：
		 * int	错误ID
		 */
		public static const STATE_ERROR:int = 4;
		/**
		 * 开始处理
		 */
		public static const STATE_START:int = 5;

		/**
		 * 压缩PNG消息，含有4个参数：
		 * String	源文件夹url
		 * String	目标文件夹url
		 * int	品质
		 * Boolean	合并为单个文件
		 */
		public static const COMMAND_COMPRESS_PNG:int = 101;
		/**
		 * 切割图片消息，含有6个参数
		 * String	源文件夹url
		 * String	目标文件夹url
		 * String	命名规则
		 * int	切片宽
		 * int	切片高
		 * int	品质
		 */
		public static const COMMAND_CUT_MAP:int = 102;
		/**
		 * 打包动作，含有4个参数
		 * String	源文件夹url
		 * String	目标文件夹url
		 * int	品质
		 * Array	动作数组（ActionVo对象数组）
		 */
		public static const COMMAND_PACK_ACTION:int = 103;
		/**
		 * 打包特效，含有4个参数
		 * String	源文件夹url
		 * String	目标文件夹url
		 * int	品质
		 * int	帧间隔（毫秒）
		 */
		public static const COMMAND_PACK_EFFECT:int = 104;
		/**
		 * 缩放图片，含有6个参数
		 * String	源文件夹url
		 * String	目标文件夹url
		 * Boolean	递归处理子文件夹
		 * int	品质
		 * Boolean	源PNG不改变品质
		 * int	缩放百分比
		 */
		public static const COMMAND_SCALE_BITMAP:int = 105;
	}

}