package controller
{
	import flash.display.BitmapData;
	import flash.filesystem.File;
	import flash.filesystem.FileStream;
	import model.ActionVo;
	/**
	 * 特效/动作打包
	 * @author WorrySprite
	 */
	public class EffectPackController
	{
		private static var outputStream:FileStream;
		
		public static function packAction(srcDirURL:String, destDirURL:String, quality:int, actionList:Array):void
		{
			var srcDir:File = new File(srcDirURL);
			var destFile:File = new File(destDirURL);
			
			var action:ActionVo;
			for (var i:int = 0; i < actionList.length; ++i)
			{
				action = actionList[i];
				action.bitmaps = new Vector.<BitmapData>();
				WorkerProject.trace("index=" + action.index + ", dir=" + action.directory + ", interval=" + action.interval);
				processFiles(srcDir.resolvePath(action.directory).getDirectoryListing());
				
			}
		}
		
		private static function processFiles(files:Array):void
		{
			
		}
		
		public static function packEffect(srcDirURL:String, destDirURL:String, quality:int, interval:int):void
		{
			
		}
	}

}