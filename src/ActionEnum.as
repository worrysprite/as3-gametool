package
{
	public class ActionEnum
	{
		public static const STAND:String = "stand";
		public static const RUN:String = "run";
		public static const ATTACK:String = "attack";
		public static const SIT:String = "sit";
		
		public static const ACTION:Vector.<String> = new <String>[STAND, RUN, ATTACK, SIT];
		
		public static const ROLE_ACTION:Vector.<String> = new <String>[STAND, RUN, ATTACK, SIT];
		public static const NPC_ACTION:Vector.<String> = new <String>[STAND];
		public static const MONSTER_ACTION:Vector.<String> = new <String>[STAND, RUN, ATTACK];
		public static const PET_ACTION:Vector.<String> = new <String>[STAND, RUN, ATTACK];
		public static const WING_ACTION:Vector.<String> = new <String>[STAND, RUN, ATTACK];
		
		public static const ROLE_DIRECTION:Vector.<int> = new <int>[5, 5, 5, 1];
		public static const NPC_DIRECTION:Vector.<int> = new <int>[1];
		public static const MONSTER_DIRECTION:Vector.<int> = new <int>[5, 5, 5];
		public static const PET_DIRECTION:Vector.<int> = new <int>[2, 2, 2];
		public static const WING_DIRECTION:Vector.<int> = new <int>[5, 5, 5];
		
		public static const ROLE_FRAME:Vector.<int> = new <int>[4, 8, 7, 1];
		public static const NPC_FRAME:Vector.<int> = new <int>[4];
		public static const MONSTER_FRAME:Vector.<int> = new <int>[4, 6, 6];
		public static const PET_FRAME:Vector.<int> = new <int>[4, 8, 7];
		public static const WING_FRAME:Vector.<int> = new <int>[4, 8, 7];
	}
}