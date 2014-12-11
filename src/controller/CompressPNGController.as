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
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	import mx.graphics.codec.JPEGEncoder;
	/**
	 * 压缩PNG
	 * @author WorrySprite
	 */
	public class CompressPNGController
	{
		private static var srcFileList:Vector.<File> = new Vector.<File>();
		private static var numLoaded:int;
		private static var outputDir:File;
		private static var outputStream:FileStream;
		private static var outputBytes:ByteArray;
		private static var jpgEncoder:JPEGEncoder;
		private static var _processingFilePath:String;
		
		public static function compress(srcDirURL:String, destDirURL:String, quality:int, isSingleFile:Boolean):void
		{
			var srcDir:File = new File(srcDirURL);
			var destDir:File = new File(destDirURL);
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
					loader.loadNow(file.url, onLoaded);
				}
			}
			if (srcFileList.length > 0)
			{
				outputDir = destDir;
				if (isSingleFile)
				{
					outputStream = new FileStream();
					outputStream.endian = Endian.LITTLE_ENDIAN;
					outputStream.open(outputDir.resolvePath("output.jng"), FileMode.WRITE);
					
					outputBytes = new ByteArray();
					outputBytes.endian = Endian.LITTLE_ENDIAN;
					outputBytes.writeBoolean(true);	//写入是多个文件
					outputBytes.writeShort(srcFileList.length);	//写入文件个数
				}
				jpgEncoder = new JPEGEncoder(quality);
			}
			else
			{
				WorkerProject.sendMessage([ThreadMessageEnum.STATE_COMPLETE, true]);
			}
		}
		
		private static function onLoaded(data:DisplayObject):void
		{
			var srcFile:File = srcFileList[numLoaded];
			var tip:String = "正在处理" + srcFile.nativePath;
			WorkerProject.trace(tip);
			WorkerProject.sendMessage([ThreadMessageEnum.STATE_PROGRESS, numLoaded, srcFileList.length, tip]);
			
			++numLoaded;
			var bmpData:BitmapData = Bitmap(data).bitmapData;
			if (!outputStream)
			{
				outputBytes = new ByteArray();
				outputBytes.endian = Endian.LITTLE_ENDIAN;
				outputBytes.writeBoolean(false);
			}
			
			outputBytes.writeShort(bmpData.width);
			outputBytes.writeShort(bmpData.height);
			outputBytes.writeBytes(jpgEncoder.encode(bmpData));
			var vec:Vector.<uint> = bmpData.getVector(bmpData.rect);
			var len:int = vec.length;
			for (var i:int = 0; i < len; ++i)
			{
				outputBytes.writeByte(vec[i] >> 24);
			}
			
			if (!outputStream)
			{
				outputBytes.compress();
				//创建新文件
				var fileName:String = srcFile.name.substring(0, srcFile.name.length - 3) + "jng";
				var file:File = outputDir.resolvePath(fileName);
				//写入文件内容
				var stream:FileStream = new FileStream();
				stream.endian = Endian.LITTLE_ENDIAN;
				stream.open(file, FileMode.WRITE);
				stream.writeBytes(outputBytes);
				stream.close();
				outputBytes = null;
			}
			//全部完毕
			if (numLoaded == srcFileList.length)
			{
				if (outputStream)
				{
					outputBytes.compress();
					outputStream.writeBytes(outputBytes);
					outputStream.close();
					outputBytes = null;
				}
				jpgEncoder = null;
				srcFileList.length = 0;
				_processingFilePath = null;
				WorkerProject.sendMessage([ThreadMessageEnum.STATE_COMPLETE, true]);
			}
		}
	}
}