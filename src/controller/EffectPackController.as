package controller
{
	import com.worrysprite.manager.SwfLoaderManager;
	import enum.ThreadMessageEnum;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import model.ActionVo;
	import model.AEPFile;
	/**
	 * 特效/动作打包
	 * @author WorrySprite
	 */
	public class EffectPackController
	{
		private static var srcDir:File;
		private static var destFile:File;
		private static var actionList:Array;
		
		private static var srcFileList:Vector.<File> = new Vector.<File>();
		private static var outputFile:AEPFile;
		private static var processActionIndex:int;
		private static var numLoaded:int;
		
		public static function packAction(srcDirURL:String, destFileURL:String, quality:int, actions:Array):void
		{
			srcDir = new File(srcDirURL);
			destFile = new File(destFileURL);
			actionList = actions;
			processActionIndex = 0;
			outputFile = new AEPFile(AEPFile.TYPE_ACTION, quality);
			processNextAction();
		}
		
		private static function processNextAction():void
		{
			if (processActionIndex == actionList.length)
			{
				releaseAndComplete();
			}
			else
			{
				var action:ActionVo = actionList[processActionIndex];
				action.bitmaps = new Vector.<BitmapData>();
				action.offsetXs = new Vector.<int>();
				action.offsetYs = new Vector.<int>();
				//WorkerProject.trace("index=" + action.index + ", dir=" + action.directory + ", interval=" + action.interval);
				var tip:String = "正在处理" + action.directory;
				WorkerProject.sendMessage([ThreadMessageEnum.STATE_PROGRESS, processActionIndex, actionList.length, tip]);
				
				++processActionIndex;
				var actionDir:File = srcDir.resolvePath(action.directory);
				if (actionDir.exists && actionDir.isDirectory)
				{
					processFiles(actionDir.getDirectoryListing(), action);
				}
				else
				{
					processNextAction();
				}
			}
		}
		
		private static function processFiles(fileList:Array, action:ActionVo, isEffect:Boolean = false):void
		{
			var file:File;
			var ext:String;
			var loader:SwfLoaderManager = SwfLoaderManager.getInstance();
			srcFileList.length = 0;
			numLoaded = 0;
			for (var i:int = 0; i < fileList.length; ++i)
			{
				file = fileList[i];
				if (!file.isDirectory)
				{
					if (file.extension)
					{
						ext = file.extension.toLowerCase();
						if (ext == "png" || ext == "jpg")
						{
							srcFileList.push(file);
							loader.queueLoad(file.url, onLoaded, [action, isEffect]);
						}
					}
				}
			}
			if (srcFileList.length == 0)
			{
				if (isEffect)
				{
					releaseAndComplete(false);
				}
				else
				{
					processNextAction();
				}
			}
		}
		
		private static function onLoaded(data:DisplayObject, action:ActionVo, isEffect:Boolean = false):void
		{
			var srcFile:File = srcFileList[numLoaded];
			//WorkerProject.trace("打包" + srcFile.nativePath);
			if (isEffect)
			{
				var tip:String = "正在处理" + srcFile.nativePath;
				WorkerProject.sendMessage([ThreadMessageEnum.STATE_PROGRESS, numLoaded, srcFileList.length, tip]);
			}
			
			var bmpData:BitmapData = Bitmap(data).bitmapData;
			if (srcFile.extension == "png")	//切掉png图片的透明通道
			{
				var rect:Rectangle = bmpData.getColorBoundsRect(0xFF000000, 0x00000000, false);
				var clipBmp:BitmapData = new BitmapData(rect.width, rect.height);
				clipBmp.copyPixels(bmpData, rect, new Point());
				action.offsetXs.push(rect.x);
				action.offsetYs.push(rect.y);
				action.bitmaps.push(clipBmp);
			}
			else
			{
				action.offsetXs.push(0);
				action.offsetYs.push(0);
				action.bitmaps.push(bmpData);
			}
			if (++numLoaded == srcFileList.length)
			{
				//WorkerProject.trace("addAction, length=" + action.bitmaps.length);
				outputFile.addAction(action);
				if (isEffect)
				{
					releaseAndComplete();
				}
				else
				{
					processNextAction();
				}
			}
		}
		
		private static function releaseAndComplete(write:Boolean = true):void
		{
			if (write)
			{
				//WorkerProject.trace("write to file, " + destFile.nativePath);
				var stream:FileStream = new FileStream();
				try
				{
					stream.open(destFile, FileMode.WRITE);
				}
				catch (e:Error)
				{
					WorkerProject.sendMessage([ThreadMessageEnum.STATE_ERROR, e.errorID]);
				}
				outputFile.writeToFile(stream);
				stream.close();
			}
			srcDir = null;
			destFile = null;
			outputFile = null;
			actionList = null;
			processActionIndex = 0;
			numLoaded = 0;
			//WorkerProject.trace("complete!");
			WorkerProject.sendMessage([ThreadMessageEnum.STATE_COMPLETE]);
		}
		
		public static function packEffect(srcDirURL:String, destFileURL:String, quality:int, interval:int):void
		{
			srcDir = new File(srcDirURL);
			destFile = new File(destFileURL);
			outputFile = new AEPFile(AEPFile.TYPE_EFFECT, quality);
			
			var action:ActionVo = new ActionVo();
			action.interval = interval;
			action.directory = "";
			action.bitmaps = new Vector.<BitmapData>();
			action.offsetXs = new Vector.<int>();
			action.offsetYs = new Vector.<int>();
			processFiles(srcDir.getDirectoryListing(), action, true);
		}
	}

}