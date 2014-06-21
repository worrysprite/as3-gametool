package
{
	/**
	 * 单位类型
	 * @author 王润智
	 */
	public class UnitType
	{
		private static const SKIN:Array = [];
		private static const NAMES:Array = [];
		/**
		 * 持剑英雄
		 */
		public static const SWORD_HERO:int = 1;
		SKIN[SWORD_HERO] = "app:/assets/swordhero.swf";
		NAMES[SWORD_HERO] = "持剑英雄";
		
		/**
		 * 步兵
		 */
		public static const SOLDIER:int = 2;
		SKIN[SOLDIER] = "app:/assets/swordman.swf";
		NAMES[SOLDIER] = "步兵";
		
		/**
		 * 弓兵
		 */
		//public static const RANGER:int = 3;
		//SKIN[RANGER] = "";
		//NAMES[] = "";
		
		/**
		 * 总数
		 */
		public static const MAX_COUNT:int = 2;
		
		public static function getSkin(type:int):String
		{
			return SKIN[type];
		}
		
		public static function getName(type:int):String
		{
			return NAMES[type];
		}
	}
}