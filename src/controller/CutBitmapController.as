package controller
{
	import com.worrysprite.manager.SwfLoaderManager;
	import enum.JpegAlgorithmEnum;
	import enum.ThreadMessageEnum;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.JPEGEncoderOptions;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import org.bytearray.images.JPEGEncoder;
	import org.bytearray.images.PNGEncoder;
	/**
	 * 位图切片
	 * @author WorrySprite
	 */
	public class CutBitmapController
	{
		private static var width:int;		//切片宽
		private static var height:int;		//切片高
		private static var pngEncoder:PNGEncoder;
		private static var jpegEncoder:JPEGEncoder;
		private static var jpegEncoderOptions:JPEGEncoderOptions;
		private static var outputFile:File;
		private static var naming:String;
		private static var rowIndex:int;
		private static var colIndex:int;
		
		public function CutBitmapController()
		{
			
		}
		
		public static function split(srcDirURL:String, destDirURL:String, namingRegular:String,
										pieceWidth:int, pieceHeight:int, quality:int, jpegAlgorithm:int):void
		{
			var srcFile:File = new File(srcDirURL);
			width = pieceWidth;
			height = pieceHeight;
			if (quality > 100)
			{
				pngEncoder = new PNGEncoder();
			}
			else
			{
				if (jpegAlgorithm == JpegAlgorithmEnum.ALGORITHM_ORG_BYTEARRAY_IMAGES_JPEGENCODER)
				{
					jpegEncoder = new JPEGEncoder(quality);
				}
				else if (jpegAlgorithm == JpegAlgorithmEnum.ALGORITHM_BITMAPDATA_ENCODE)
				{
					jpegEncoderOptions = new JPEGEncoderOptions(quality);
				}
			}
			outputFile = new File(destDirURL);
			naming = namingRegular.replace("%dir%", outputFile.name);
			WorkerProject.sendMessage([ThreadMessageEnum.STATE_START]);
			var tip:String = "正在加载源图片";
			WorkerProject.sendMessage([ThreadMessageEnum.STATE_PROGRESS, 0, 100, tip]);
			SwfLoaderManager.getInstance().loadNow(srcDirURL, onLoaded);
		}
		
		static private function onLoaded(bitmap:Bitmap):void
		{
			var bmpData:BitmapData = bitmap.bitmapData;
			var numCols:int = Math.ceil(bmpData.width / width);
			var numRows:int = Math.ceil(bmpData.height / height);
			var currentProgress:int = 1;
			var totalProgress:int = numCols * numRows + 1;
			var ext:String = pngEncoder ? ".png" : ".jpg";
			var rect:Rectangle = new Rectangle(0, 0, width, height);
			if (jpegEncoder)
			{
				var destBmp:BitmapData = new BitmapData(width, height);
				var zeroPoint:Point = new Point();
			}
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
					rowIndex = i;
					colIndex = j;
					var fileName:String = getFileName() + ext;
					var tip:String = "正在处理" + fileName;
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
						if (pngEncoder)
						{
							stream.writeBytes(pngEncoder.encodeByteArray(bmpData.getPixels(rect), rect.width, rect.height));
						}
						else
						{
							if (jpegEncoder)
							{
								if (rect.width == width && rect.height == height)
								{
									destBmp.copyPixels(bmpData, rect, zeroPoint);
									stream.writeBytes(jpegEncoder.encode(destBmp));
								}
								else
								{
									var tmpBmp:BitmapData = new BitmapData(rect.width, rect.height);
									tmpBmp.copyPixels(bmpData, rect, zeroPoint);
									stream.writeBytes(jpegEncoder.encode(tmpBmp));
								}
							}
							else if (jpegEncoderOptions)
							{
								stream.writeBytes(bmpData.encode(rect, jpegEncoderOptions));
							}
						}
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
		
		private static function getFileName():String
		{
			return naming.replace(/%row0*[01]%/g, replaceRow).replace(/%col0*[01]%/g, replaceCol);
		}
		
		private static function replaceRow(match:String, index:int, fullStr:String):String
		{
			var rowStr:String = match.charAt(match.length - 2) == "0" ? rowIndex.toString() : String(rowIndex + 1);
			var fixed:int = match.length - 5;
			if (fixed > 1)
			{
				while (rowStr.length < fixed)
				{
					rowStr = "0" + rowStr;
				}
			}
			return rowStr;
		}
		
		private static function replaceCol(match:String, index:int, fullStr:String):String
		{
			var colStr:String = match.charAt(match.length - 2) == "0" ? colIndex.toString() : String(colIndex + 1);
			var fixed:int = match.length - 5;
			if (fixed > 1)
			{
				while (colStr.length < fixed)
				{
					colStr = "0" + colStr;
				}
			}
			return colStr;
		}
		
		private static function cleanup():void
		{
			outputFile = null;
			pngEncoder = null;
			jpegEncoderOptions = null;
		}
	}
}