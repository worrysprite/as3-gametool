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
		private static var pngEncoder:PNGEncoder;
		private static var scaleValue:Number;
		private static var matrix:Matrix = new Matrix();
		private static var numLoaded:int;
		
		public static function scale(srcDirURL:String, destDirURL:String, recursive:Boolean, quality:int, pngNotChange:Boolean, percent:int):void
		{
			var srcDir:File = new File(srcDirURL);
			if (destDirURL)
			{
				outputDir = new File(destDirURL);
			}
			pngNotChange = pngNotChange;
			if (quality <= 100)
			{
				encoder = new JPEGEncoder(quality);
				if (pngNotChange)
				{
					pngEncoder = new PNGEncoder();
				}
			}
			else
			{
				encoder = new PNGEncoder();
			}
			matrix.identity();
			scaleValue = percent / 10000;	//为了提高精度，改成了万分比
			matrix.scale(scaleValue, scaleValue);
			
			numLoaded = 0;
			loadFiles(srcDir, recursive);
			
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
		
		private static function loadFiles(dir:File, recursive:Boolean):void
		{
			var allFiles:Array = dir.getDirectoryListing();
			var file:File;
			var loader:SwfLoaderManager = SwfLoaderManager.getInstance();
			for (var i:int = 0; i < allFiles.length; ++i)
			{
				file = allFiles[i];
				if (recursive && file.isDirectory)
				{
					loadFiles(file, recursive);
				}
				if (FileUtils.isImage(file))
				{
					srcFileList.push(file);
					loader.queueLoad(file.url, onLoaded, [file]);
				}
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
				var w:int = srcBmp.width * scaleValue;
				var h:int = srcBmp.height * scaleValue;
				if (w < 1 || h < 1)	//缩小后若小于1像素则忽略
				{
					return;
				}
				destBmp = new BitmapData(w, h, true, 0);
			}
			catch (e:Error)
			{
				cleanup();
				WorkerProject.sendMessage([ThreadMessageEnum.STATE_ERROR, ErrorCodeEnum.BITMAP_OUT_OF_SIZE]);
				return;
			}
			destBmp.draw(srcBmp, matrix, null, null, null, true);
			
			var enc:IImageEncoder;
			if (pngEncoder && FileUtils.isPNG(srcFile))	//PNG保持原有品质
			{
				enc = pngEncoder;
			}
			else
			{
				enc = encoder;
			}
			
			//编码并写入文件
			var ext:String = enc is PNGEncoder ? ".png" : ".jpg";
			var fileName:String = FileUtils.splitNameAndExt(srcFile.name)[0] + ext;
			var stream:FileStream = new FileStream();
			try
			{
				if (outputDir)
				{
					stream.open(outputDir.resolvePath(fileName), FileMode.WRITE);
				}
				else	//直接覆盖源文件
				{
					stream.open(srcFile.parent.resolvePath(fileName), FileMode.WRITE);
				}
				stream.writeBytes(enc.encode(destBmp));
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
			pngEncoder = null;
		}
	}

}