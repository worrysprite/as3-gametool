package model
{
	import flash.display.BitmapData;
	import flash.events.EventDispatcher;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	import flash.utils.IDataOutput;
	import mx.graphics.codec.PNGEncoder;
	/**
	 * aep文件定义
	 * @author WorrySprite
	 */
	public class AEPFile extends EventDispatcher
	{
		public static const TYPE_ACTION:int = 1;
		public static const TYPE_EFFECT:int = 2;
		
		private static const VERSION_1_0:uint = 0x00010000;
		
		private static const pngEncoder:PNGEncoder = new PNGEncoder();
		
		private var _type:int;
		private var _bytes:ByteArray;
		private var _actionList:Vector.<ActionVo>;
		private var _quality:int;
		private var jngList:Vector.<JNGFile>;
		
		public function AEPFile(type:int, quality:int = 80)
		{
			_type = type;
			_bytes = new ByteArray();
			_bytes.endian = Endian.LITTLE_ENDIAN;
			_bytes.writeUnsignedInt(VERSION_1_0);	//写入版本
			_bytes.writeShort(0);	//写入动作数量
			
			_actionList = new Vector.<ActionVo>();
			_quality = quality;
			if (quality <= 100)
			{
				jngList = new Vector.<JNGFile>();
			}
		}
		
		private function addBitmap(bmp:BitmapData):void
		{
			if (bmp)
			{
				//写入宽高
				_bytes.writeShort(bmp.width);
				_bytes.writeShort(bmp.height);
				//写入png数据
				var pngBytes:ByteArray = pngEncoder.encode(bmp);
				_bytes.writeUnsignedInt(pngBytes.length);
				_bytes.writeBytes(pngBytes);
			}
		}
		
		private function readV1_0():void
		{
			
		}
		
		public function addAction(action:ActionVo):void
		{
			if (!action || !action.bitmaps)
			{
				return;
			}
			action.index = _actionList.length;
			//修改动作数量
			_bytes.position = 4;
			_bytes.writeShort(_actionList.push(action));
			_bytes.position = _bytes.length;
			
			//写入动作信息
			_bytes.writeUTF(action.directory);
			_bytes.writeUnsignedInt(action.interval);
			//写入PNG图片数量
			var bmpCount:int = action.bitmaps.length;
			_bytes.writeShort(bmpCount);
			
			var jng:JNGFile;
			if (_quality <= 100)	//压缩为jng
			{
				jng = new JNGFile(_quality);	//每个动作对应一个jng文件
				jngList.push(jng);
			}
			//写入偏移量列表
			for (var j:int = 0; j < bmpCount; ++j)
			{
				_bytes.writeShort(action.offsetXs[j]);
				_bytes.writeShort(action.offsetYs[j]);
			}
			//写入图片列表
			for (var i:int = 0; i < bmpCount; ++i)
			{
				if (jng)
				{
					jng.addBitmap(action.bitmaps[i]);
				}
				else
				{
					addBitmap(action.bitmaps[i]);
				}
			}
			if (jng)
			{
				_bytes.writeBytes(jng.bytes);
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
			if (version == VERSION_1_0)
			{
				readV1_0();
			}
		}
		
		public function get bytes():ByteArray
		{
			var clone:ByteArray = new ByteArray();
			clone.endian = Endian.LITTLE_ENDIAN;
			clone.writeBytes(_bytes);
			return clone;
		}
		
		public function get type():int
		{
			return _type;
		}
		
		public function get actionList():Vector.<ActionVo>
		{
			return _actionList;
		}
		
		/**
		 * 品质，1~100为jpg品质，101为无损
		 */
		public function get quality():int
		{
			return _quality;
		}
	}
}