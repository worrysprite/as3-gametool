package controller
{
	import com.worrysprite.manager.SwfLoaderManager;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
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
		private static var srcFileList:Vector.<File> = new Vector.<File>();
		
		public static function packAction(srcDirURL:String, destDirURL:String, quality:int, actionList:Array):void
		{
			var srcDir:File = new File(srcDirURL);
			var destFile:File = new File(destDirURL);
			
			var action:ActionVo;
			var actionDir:File;
			for (var i:int = 0; i < actionList.length; ++i)
			{
				action = actionList[i];
				action.bitmaps = new Vector.<BitmapData>();
				WorkerProject.trace("index=" + action.index + ", dir=" + action.directory + ", interval=" + action.interval);
				actionDir = srcDir.resolvePath(action.directory);
				if (actionDir.exists && actionDir.isDirectory)
				{
					processFiles(actionDir.getDirectoryListing());
				}
			}
		}
		
		private static function processFiles(files:Array):void
		{
			var file:File;
			var ext:String;
			var loader:SwfLoaderManager = SwfLoaderManager.getInstance();
			for (var i:int = 0; i < files.length; ++i) 
			{
				file = files[i];
				if (!file.isDirectory)
				{
					ext = file.extension.toLowerCase();
					if (ext == "png" || ext == "jpg")
					{
						srcFileList.push(file);
						loader.queueLoad(file.url, onLoaded);
					}
				}
			}
		}
		
		private static function onLoaded(data:DisplayObject):void
		{
			
		}
		
		public static function packEffect(srcDirURL:String, destDirURL:String, quality:int, interval:int):void
		{
			
		}
	}

}