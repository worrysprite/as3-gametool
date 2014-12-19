package model
{
	import com.worrysprite.manager.SwfLoaderManager;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.BitmapDataChannel;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.geom.Point;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	import flash.utils.IDataOutput;
	import mx.graphics.codec.JPEGEncoder;
	/**
	 * jng文件定义
	 * @author WorrySprite
	 */
	public class JNGFile extends EventDispatcher
	{
		private static const CURRENT_VERSION:uint = 0x00010000;	//v1.0
		private var jpgEncoder:JPEGEncoder;
		private var _bitmaps:Vector.<BitmapData>;
		private var _bytes:ByteArray;
		private var fileLoaded:int;
		
		public function JNGFile(quality:int = 80)
		{
			jpgEncoder = new JPEGEncoder(quality);
			_bitmaps = new Vector.<BitmapData>();
			_bytes = new ByteArray();
			_bytes.endian = Endian.LITTLE_ENDIAN;
			_bytes.writeUnsignedInt(CURRENT_VERSION);
			_bytes.writeShort(0);
		}
		
		private function onLoaded(jpgImg:Bitmap, index:int):void
		{
			var bmpData:BitmapData = jpgImg.bitmapData;
			var channels:uint = BitmapDataChannel.RED | BitmapDataChannel.BLUE | BitmapDataChannel.GREEN;
			_bitmaps[index].copyChannel(bmpData, bmpData.rect, new Point(), channels, channels);
			
			if (++fileLoaded == _bitmaps.length)
			{
				dispatchEvent(new Event(Event.COMPLETE));
			}
		}
		
		public function addBitmap(bmp:BitmapData):void
		{
			if (bmp)
			{
				//写入宽高
				_bytes.writeShort(bmp.width);
				_bytes.writeShort(bmp.height);
				//写入jpg数据
				var jpgBytes:ByteArray = jpgEncoder.encode(bmp);
				_bytes.writeUnsignedInt(jpgBytes.length);
				_bytes.writeBytes(jpgBytes);
				//写入alpha数据
				var vec:Vector.<uint> = bmp.getVector(bmp.rect);
				var len:int = vec.length;
				for (var i:int = 0; i < len; ++i)
				{
					_bytes.writeByte(vec[i] >> 24);
				}
				
				//修改位图数量
				_bytes.position = 4;
				_bytes.writeShort(_bitmaps.push(bmp));
				_bytes.position = _bytes.length;
			}
		}
		
		public function writeToFile(file:IDataOutput):void
		{
			var content:ByteArray = bytes;
			content.compress();
			file.writeBytes(content);
		}
		
		public function readFromFile(file:ByteArray):void
		{
			file.uncompress();
			_bytes.clear();
			_bytes.writeBytes(file);
			_bytes.position = 0;
			var version:uint = _bytes.readUnsignedInt();
			_bitmaps.length = 0;
			_bitmaps.length = _bytes.readUnsignedShort();
			trace("jng version:", version, "bitmap count:", _bitmaps.length);
			var width:uint;
			var height:uint;
			var length:uint;
			var jpgBytes:ByteArray = new ByteArray();
			var bmp:BitmapData;
			var loader:SwfLoaderManager = SwfLoaderManager.getInstance();
			fileLoaded = 0;
			for (var i:int = 0; i < _bitmaps.length; ++i)
			{
				//读取宽高
				width = _bytes.readUnsignedShort();
				height = _bytes.readUnsignedShort();
				bmp = new BitmapData(width, height);
				_bitmaps[i] = bmp;
				
				//读取jpg
				length = _bytes.readUnsignedInt();
				jpgBytes.clear();
				_bytes.readBytes(jpgBytes, 0, length);
				loader.loadBytes(jpgBytes, onLoaded, [i]);
				
				//读取alpha
				for (var j:int = 0; j < height; ++j)
				{
					for (var k:int = 0; k < width; ++k)
					{
						bmp.setPixel32(k, j, _bytes.readByte() << 24);
					}
				}
			}
		}
		
		public function get bytes():ByteArray
		{
			var clone:ByteArray = new ByteArray();
			clone.endian = Endian.LITTLE_ENDIAN;
			clone.writeBytes(_bytes);
			return clone;
		}
		
		public function get bitmaps():Vector.<BitmapData>
		{
			return _bitmaps.slice();
		}
	}

}