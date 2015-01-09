package controller
{
	import com.worrysprite.manager.SwfLoaderManager;
	import com.worrysprite.utils.FileUtils;
	import enum.ErrorCodeEnum;
	import enum.ThreadMessageEnum;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.geom.Matrix;
	import mx.graphics.codec.IImageEncoder;
	import mx.graphics.codec.JPEGEncoder;
	import mx.graphics.codec.PNGEncoder;
	/**
	 * 图片缩放
	 * @author WorrySprite
	 */
	public class BitmapScaleController
	{
		private static var srcFileList:Vector.<File> = new Vector.<File>();
		private static var outputDir:File;
		private static var encoder:IImageEncoder;
		private static var scaleValue:Number;
		private static var matrix:Matrix = new Matrix();
		private static var numLoaded:int;
		
		public static function scale(srcDirURL:String, destDirURL:String, quality:int, percent:int):void
		{
			var srcDir:File = new File(srcDirURL);
			outputDir = new File(destDirURL);
			if (quality <= 100)
			{
				encoder = new JPEGEncoder(quality);
			}
			else
			{
				encoder = new PNGEncoder();
			}
			matrix.identity();
			scaleValue = percent / 100;
			matrix.scale(scaleValue, scaleValue);
			
			numLoaded = 0;
			var allFiles:Array = srcDir.getDirectoryListing();
			var file:File;
			var loader:SwfLoaderManager = SwfLoaderManager.getInstance();
			for (var i:int = 0; i < allFiles.length; ++i)
			{
				file = allFiles[i];
				if (FileUtils.isImage(file))
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
			WorkerProject.trace(tip);
			WorkerProject.sendMessage([ThreadMessageEnum.STATE_PROGRESS, numLoaded, srcFileList.length, tip]);
			
			++numLoaded;
			var srcBmp:BitmapData = Bitmap(data).bitmapData;
			var destBmp:BitmapData;
			try
			{
				destBmp = new BitmapData(srcBmp.width * scaleValue, srcBmp.height * scaleValue);
			}
			catch (e:Error)
			{
				cleanup();
				WorkerProject.sendMessage([ThreadMessageEnum.STATE_ERROR, ErrorCodeEnum.BITMAP_OUT_OF_SIZE]);
				return;
			}
			destBmp.draw(srcBmp, matrix, null, null, null, true);
			
			var ext:String = encoder is PNGEncoder ? ".png" : ".jpg";
			//写入文件
			var fileName:String = FileUtils.splitNameAndExt(srcFile.name)[0] + ext;
			var stream:FileStream = new FileStream();
			try
			{
				stream.open(outputDir.resolvePath(fileName), FileMode.WRITE);
				stream.writeBytes(encoder.encode(destBmp));
			}
			catch (e:Error)
			{
				stream.close();
				cleanup();	//出错则中断操作
				WorkerProject.sendMessage([ThreadMessageEnum.STATE_ERROR, e.errorID]);
				return;
			}
			stream.close();
			
			//全部完毕
			if (numLoaded == srcFileList.length)
			{
				cleanup();
				WorkerProject.sendMessage([ThreadMessageEnum.STATE_COMPLETE]);
			}
		}
		
		private static function cleanup():void
		{
			outputDir = null;
			srcFileList.length = 0;
			numLoaded = 0;
			encoder = null;
		}
	}

}