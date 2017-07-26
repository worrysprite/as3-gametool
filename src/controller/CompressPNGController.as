package controller
{
	import com.worrysprite.manager.SwfLoaderManager;
	import com.worrysprite.model.image.JNGFile;
	import com.worrysprite.utils.FileUtils;
	import enum.ErrorCodeEnum;
	import enum.ThreadMessageEnum;
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.utils.Endian;
	/**
	 * 压缩PNG
	 * @author WorrySprite
	 */
	public class CompressPNGController
	{
		private static var srcFileList:Vector.<File> = new Vector.<File>();
		private static var outputDir:File;
		private static var single:Boolean;
		private static var numLoaded:int;
		private static var outputFile:JNGFile;
		private static var _quality:int;
		private static var _jpegAlgorithm:int;
		
		public static function compress(srcDirURL:String, destDirURL:String, quality:int, jpegAlgorithm:int, isSingleFile:Boolean):void
		{
			var srcDir:File = new File(srcDirURL);
			outputDir = new File(destDirURL);
			_quality = quality;
			single = isSingleFile;
			_jpegAlgorithm = jpegAlgorithm;
			
			numLoaded = 0;
			var allFiles:Array = srcDir.getDirectoryListing();
			var file:File;
			var loader:SwfLoaderManager = SwfLoaderManager.getInstance();
			for (var i:int = 0; i < allFiles.length; ++i)
			{
				file = allFiles[i];
				if (FileUtils.isPNG(file))
				{
					srcFileList.push(file);
					loader.queueLoad(file.url, onLoaded, [file]);
				}
			}
			if (srcFileList.length <= 0)	//如果未加载任何文件
			{
				cleanup();
				WorkerProject.sendMessage([ThreadMessageEnum.STATE_ERROR, ErrorCodeEnum.EMPTY_RESOURCE_DIRECTORY]);
			}
			else
			{
				WorkerProject.sendMessage([ThreadMessageEnum.STATE_START]);
			}
		}
		
		private static function onLoaded(data:DisplayObject, verifyFile:File):void
		{
			if (srcFileList.length == 0)	//如果中途出错srcFileList会被清空
			{
				return;
			}
			var srcFile:File = srcFileList[numLoaded];
			if (verifyFile != srcFile)	//如果中途出错加载队列不会停止，在此验证加载完成的文件
			{
				return;
			}
			var tip:String = "正在处理" + srcFile.nativePath;
			WorkerProject.sendMessage([ThreadMessageEnum.STATE_PROGRESS, numLoaded, srcFileList.length, tip]);
			
			++numLoaded;
			if (!outputFile)
			{
				outputFile = new JNGFile(_quality);
				outputFile.jpegAlgorithm = _jpegAlgorithm;
			}
			try
			{
				outputFile.addBitmap(Bitmap(data).bitmapData, srcFile.name);
			}
			catch (e:Error)
			{
				WorkerProject.trace("error" + e.getStackTrace());
			}
			
			if (!single)	//不合并单个文件就直接写入文件
			{
				//创建新文件
				var fileName:String = srcFile.name.substring(0, srcFile.name.length - 3) + "jng";
				if (!writeFile(fileName))
				{
					return;
				}
			}
			//全部完毕
			if (numLoaded == srcFileList.length)
			{
				if (single)
				{
					if (!writeFile("output.jng"))
					{
						return;
					}
				}
				cleanup();
				WorkerProject.sendMessage([ThreadMessageEnum.STATE_COMPLETE]);
			}
		}
		
		private static function writeFile(fileName:String):Boolean
		{
			var stream:FileStream = new FileStream();
			stream.endian = Endian.LITTLE_ENDIAN;
			try
			{
				stream.open(outputDir.resolvePath(fileName), FileMode.WRITE);
				outputFile.writeToFile(stream);
			}
			catch (e:Error)
			{
				stream.close();
				cleanup();	//出错则中断操作
				WorkerProject.sendMessage([ThreadMessageEnum.STATE_ERROR, e.errorID]);
				return false;
			}
			stream.close();
			outputFile = null;	//单个文件写入完之后要清空让下次创建新文件
			return true;
		}
		
		private static function cleanup():void
		{
			outputDir = null;
			srcFileList.length = 0;
			numLoaded = 0;
			outputFile = null;
		}
	}
}