package controller
{
	import com.worrysprite.manager.SwfLoaderManager;
	import enum.ThreadMessageEnum;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.geom.Rectangle;
	import mx.graphics.codec.IImageEncoder;
	import mx.graphics.codec.JPEGEncoder;
	import mx.graphics.codec.PNGEncoder;
	/**
	 * 位图切片
	 * @author WorrySprite
	 */
	public class CutBitmapController
	{
		private static var width:int;
		private static var height:int;
		private static var encoder:IImageEncoder;
		private static var outputFile:File;
		
		public function CutBitmapController()
		{
			
		}
		
		public static function split(srcDirURL:String, destDirURL:String, pieceWidth:int, pieceHeight:int, quality:int):void
		{
			var srcFile:File = new File(srcDirURL);
			WorkerProject.trace("w:" + pieceWidth + ", h:" + pieceHeight + ", q:" + quality);
			width = pieceWidth;
			height = pieceHeight;
			if (quality > 100)
			{
				encoder = new PNGEncoder();
			}
			else
			{
				encoder = new JPEGEncoder(quality);
			}
			outputFile = new File(destDirURL);
			WorkerProject.sendMessage([ThreadMessageEnum.STATE_START]);
			var tip:String = "正在加载源图片";
			WorkerProject.trace(tip);
			WorkerProject.sendMessage([ThreadMessageEnum.STATE_PROGRESS, 0, 100, tip]);
			SwfLoaderManager.getInstance().loadNow(srcDirURL, onLoaded);
		}
		
		static private function onLoaded(bitmap:Bitmap):void
		{
			var bmpData:BitmapData = bitmap.bitmapData;
			var numCols:int = Math.ceil(bmpData.width / width);
			var numRows:int = Math.ceil(bmpData.height / height);
			WorkerProject.trace("col:" + numCols + ", row:" + numRows);
			var currentProgress:int = 1;
			var totalProgress:int = numCols * numRows + 1;
			var ext:String = encoder is PNGEncoder ? ".png" : ".jpg";
			var rect:Rectangle = new Rectangle(0, 0, width, height);
			for (var i:int = 0; i < numRows; ++i)
			{
				rect.y = i * height;
				if (i == numRows - 1)
				{
					rect.bottom = bmpData.height;
				}
				else
				{
					rect.height = height;
				}
				for (var j:int = 0; j < numCols; ++j)
				{
					var fileName:String = i + "_" + j + ext;
					var tip:String = "正在处理" + fileName;
					WorkerProject.trace(tip);
					WorkerProject.sendMessage([ThreadMessageEnum.STATE_PROGRESS, currentProgress, totalProgress, tip]);
					
					var stream:FileStream = new FileStream();
					try
					{
						stream.open(outputFile.resolvePath(fileName), FileMode.WRITE);
						rect.x = j * width;
						if (j == numCols - 1)
						{
							rect.right = bmpData.width;
						}
						else
						{
							rect.width = width;
						}
						WorkerProject.trace("rect: x=" + rect.x + ", y=" + rect.y + ", w=" + rect.width + ", h=" + rect.height);
						stream.writeBytes(encoder.encodeByteArray(bmpData.getPixels(rect), rect.width, rect.height));
					}
					catch (e:Error)
					{
						stream.close();
						cleanup();
						WorkerProject.sendMessage([ThreadMessageEnum.STATE_ERROR, e.errorID]);
						return;
					}
					stream.close();
					++currentProgress;
				}
			}
			cleanup();
			WorkerProject.sendMessage([ThreadMessageEnum.STATE_COMPLETE]);
		}
		
		private static function cleanup():void
		{
			outputFile = null;
			encoder = null;
		}
	}
}