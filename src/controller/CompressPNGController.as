package controller
{
	import com.worrysprite.manager.SwfLoaderManager;
	import enum.ThreadMessageEnum;
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.utils.Endian;
	import model.JNGFile;
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
		
		public static function compress(srcDirURL:String, destDirURL:String, quality:int, isSingleFile:Boolean):void
		{
			var srcDir:File = new File(srcDirURL);
			outputDir = new File(destDirURL);
			_quality = quality;
			single = isSingleFile;
			
			numLoaded = 0;
			var srcFiles:Array = srcDir.getDirectoryListing();
			var file:File;
			var loader:SwfLoaderManager = SwfLoaderManager.getInstance();
			for (var i:int = 0; i < srcFiles.length; ++i)
			{
				file = srcFiles[i];
				if (!file.isDirectory && file.extension == "png")
				{
					srcFileList.push(file);
					loader.queueLoad(file.url, onLoaded);
				}
			}
			if (srcFileList.length <= 0)	//如果未加载任何文件
			{
				outputDir = null;
				WorkerProject.sendMessage([ThreadMessageEnum.STATE_COMPLETE]);
			}
		}
		
		private static function onLoaded(data:DisplayObject):void
		{
			var srcFile:File = srcFileList[numLoaded];
			var tip:String = "正在处理" + srcFile.nativePath;
			WorkerProject.trace(tip);
			WorkerProject.sendMessage([ThreadMessageEnum.STATE_PROGRESS, numLoaded, srcFileList.length, tip]);
			
			++numLoaded;
			if (!outputFile)
			{
				outputFile = new JNGFile(_quality);
			}
			outputFile.addBitmap(Bitmap(data).bitmapData);
			
			var stream:FileStream;
			if (!single)	//不合并单个文件就直接写入文件
			{
				//创建新文件
				var fileName:String = srcFile.name.substring(0, srcFile.name.length - 3) + "jng";
				writeFile(fileName);
			}
			//全部完毕
			if (numLoaded == srcFileList.length)
			{
				if (single)
				{
					writeFile("output.jng");
				}
				srcFileList.length = 0;
				WorkerProject.sendMessage([ThreadMessageEnum.STATE_COMPLETE]);
			}
		}
		
		private static function writeFile(fileName:String):void
		{
			var stream:FileStream = new FileStream();
			stream.endian = Endian.LITTLE_ENDIAN;
			stream.open(outputDir.resolvePath(fileName), FileMode.WRITE);
			outputFile.writeToFile(stream);
			stream.close();
			outputFile = null;
		}
	}
}