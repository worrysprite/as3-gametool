package controller
{
	import com.worrysprite.manager.SwfLoaderManager;
	import com.worrysprite.model.image.ActionVo;
	import com.worrysprite.model.image.AEPFile;
	import com.worrysprite.utils.FileUtils;
	import enum.ErrorCodeEnum;
	import enum.ThreadMessageEnum;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Endian;
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
		
		public static function packAction(srcDirURL:String, destFileURL:String, quality:int, jpegAlgorithm:int, actions:Array):void
		{
			srcDir = new File(srcDirURL);
			destFile = new File(destFileURL);
			actionList = actions;
			processActionIndex = 0;
			outputFile = new AEPFile(AEPFile.TYPE_ACTION, quality);
			outputFile.jpegAlgorithm = jpegAlgorithm;
			WorkerProject.sendMessage([ThreadMessageEnum.STATE_START]);
			processNextAction();
		}
		
		private static function processNextAction():void
		{
			if (processActionIndex == actionList.length)
			{
				if (writeFile())
				{
					cleanup();
					WorkerProject.sendMessage([ThreadMessageEnum.STATE_COMPLETE]);
				}
			}
			else
			{
				var action:ActionVo = actionList[processActionIndex];
				action.bitmaps = new Vector.<BitmapData>();
				action.offsetXs = new Vector.<int>();
				action.offsetYs = new Vector.<int>();
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
				if (FileUtils.isImage(file))
				{
					srcFileList.push(file);
					loader.queueLoad(file.url, onLoaded, [action, isEffect]);
				}
			}
			if (srcFileList.length == 0)
			{
				cleanup();
				WorkerProject.sendMessage([ThreadMessageEnum.STATE_ERROR, ErrorCodeEnum.EMPTY_RESOURCE_DIRECTORY]);
			}
			else
			{
				if (isEffect)
				{
					WorkerProject.sendMessage([ThreadMessageEnum.STATE_START]);
				}
			}
		}
		
		private static function onLoaded(data:DisplayObject, action:ActionVo, isEffect:Boolean = false):void
		{
			var srcFile:File = srcFileList[numLoaded];
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
				outputFile.addAction(action);
				if (isEffect)
				{
					if (writeFile())
					{
						WorkerProject.sendMessage([ThreadMessageEnum.STATE_COMPLETE]);
					}
				}
				else
				{
					processNextAction();
				}
			}
		}
		
		private static function writeFile():Boolean
		{
			var stream:FileStream = new FileStream();
			stream.endian = Endian.LITTLE_ENDIAN;
			try
			{
				stream.open(destFile, FileMode.WRITE);
				outputFile.writeToFile(stream);
			}
			catch (e:Error)
			{
				stream.close();
				cleanup();
				WorkerProject.sendMessage([ThreadMessageEnum.STATE_ERROR, e.errorID]);
				return false;
			}
			stream.close();
			return true;
		}
		
		public static function packEffect(srcDirURL:String, destFileURL:String, quality:int, jpegAlgorithm:int, interval:int):void
		{
			srcDir = new File(srcDirURL);
			destFile = new File(destFileURL);
			outputFile = new AEPFile(AEPFile.TYPE_EFFECT, quality);
			outputFile.jpegAlgorithm = jpegAlgorithm;
			
			var action:ActionVo = new ActionVo();
			action.interval = interval;
			action.directory = "";
			action.bitmaps = new Vector.<BitmapData>();
			action.offsetXs = new Vector.<int>();
			action.offsetYs = new Vector.<int>();
			processFiles(srcDir.getDirectoryListing(), action, true);
		}
		
		private static function cleanup():void
		{
			srcDir = null;
			destFile = null;
			actionList = null;
			srcFileList.length = 0;
			outputFile = null;
			processActionIndex = 0;
			numLoaded = 0;
		}
	}

}