import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.MovieClip;
import flash.events.Event;
import flash.filesystem.File;
import flash.filesystem.FileMode;
import flash.filesystem.FileStream;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.utils.ByteArray;
import flash.utils.CompressionAlgorithm;
import flash.utils.Endian;
import mx.collections.ArrayCollection;
import mx.controls.Alert;
import mx.graphics.codec.JPEGEncoder;
import mx.graphics.codec.PNGEncoder;
import spark.components.TextInput;

private static const IDLE:String = "idle";
private static const MAKING_ACTION:String = "making_action";
private static const MAKING_EFFECT:String = "making_effect";
private static const CUTTING_JPG:String = "cutting_jpg";
private static const SCALING_BITMAP:String = "scaling_bitmap";
private static const COMPRESS:String = "compress";

private static const ATTACK:String = "attack";
private static const RUN:String = "run";
private static const DIE:String = "die";

private static const ACTION:Vector.<String> = new <String>[ATTACK, RUN, DIE];

[Bindable]
private var comboData:ArrayCollection;
private var file:File;
private var selectingPath:TextInput;
[Bindable]
private var processStatus:String = IDLE;

private var actionList:Vector.<String>;
private var directions:Vector.<int>;
private var actionFrame:Vector.<int>;

private var actionStep:int;
private var previewSWF:MovieClip;
private var previewFrame:int;
private var readingFiles:Vector.<String>;

private var jsflFile:File;
private var tmpJSFL:File;

private function init():void
{
	actionType.textInput.editable = false;
	
	comboData = new ArrayCollection();
	for (var i:int = 1; i <= UnitType.MAX_COUNT; ++i)
	{
		comboData.addItem( { label:UnitType.getName(i), data:i } );
	}
	actionType.dataProvider = comboData;
	
	file = new File();
	file.addEventListener(Event.SELECT, onDirSelected);
	LoadQueue.getInstance().addEventListener(Event.COMPLETE, onImageLoaded);
	
	addEventListener(MouseEvent.CLICK, onClick);
}

private function onClick(e:MouseEvent):void
{
	switch(e.target)
	{
		case pbActionSrc:
			selectingPath = actionPath;
			file.browseForDirectory("选择文件夹");
			break;
		case pbActionMake:
			makeAction();
			break;
		case pbEffectSrc:
			selectingPath = effectPath;
			file.browseForDirectory("选择文件夹");
			break;
		case pbEffectMake:
			makeEffect();
			break;
		case pbJpgSrc:
			selectingPath = jpgPath;
			file.browseForDirectory("选择文件夹");
			break;
		case pbScaleSrc:
			selectingPath = scalePath;
			file.browseForDirectory("选择文件夹");
			break;
		case pbCompressBrowse:
			selectingPath = compressPath;
			file.browseForDirectory("选择文件夹");
			break;
		case pbJpgCut:
			break;
		case pbJpgMake:
			break;
		case pbPreview:
			preview();
			break;
		case pbScale:
			scaleBitmap();
			break;
		case pbCompress:
			compressPNG();
			break;
	}
}

private function onDirSelected(e:Event):void
{
	selectingPath.text = file.nativePath;
}

private function onTextChange(e:Event):void
{
	file = new File(e.target.text);
}

/**
 * 打包动作
 */
private function makeAction():void
{
	if (actionType.selectedIndex == -1)
	{
		Alert.show("请选择一种动作类型！");
		return;
	}
	
	jsflFile = new File(File.applicationDirectory.resolvePath("exportActionSWF.jsfl").nativePath);
	
	processStatus = MAKING_ACTION;
	
	actionStep = 0;
	LoadQueue.getInstance().completeList.length = 0;
	
	if (file.exists)
	{
		readingFiles = new Vector.<String>();
		modifyJSFL(file.url);
		while (actionStep < ACTION.length)
		{
			readFile(new File(file.url + "/" + ACTION[actionStep]));
			actionStep++;
		}
		LoadQueue.getInstance().loadImageList(readingFiles);
	}
}

/**
 * 打包特效
 */
private function makeEffect():void
{
	jsflFile = new File(File.applicationDirectory.resolvePath("exportEffectSWF.jsfl").nativePath);
	
	LoadQueue.getInstance().completeList.length = 0;
	processStatus = MAKING_EFFECT;
	if (file.exists)
	{
		modifyJSFL(file.url);
		readingFiles = new Vector.<String>();
		readFile(file);
		LoadQueue.getInstance().loadImageList(readingFiles);
	}
}

private function scaleBitmap():void
{
	LoadQueue.getInstance().completeList.length = 0;
	processStatus = SCALING_BITMAP;
	if (file.exists)
	{
		readingFiles = new Vector.<String>();
		readFile(file, null, true);
		LoadQueue.getInstance().loadImageList(readingFiles);
	}
}

private function readFile(dir:File, ext:Vector.<String> = null, recursion:Boolean = false):Boolean
{
	if (!dir || !dir.exists || !dir.isDirectory)
	{
		return false;
	}
	if (ext == null)
	{
		ext = new <String>[".png"];
	}
	
	var content:Array = dir.getDirectoryListing();
	var url:String;
	var file:File;
	for (var i:int = 0; i < content.length; i++)
	{
		file = content[i];
		if (recursion && file.isDirectory)
		{
			readFile(file, ext, recursion);
		}
		else
		{
			url = file.url;
			if (url.length > 4 && ext.indexOf(url.substr(url.length - 4)) >= 0)
			{
				readingFiles.push(url);
			}
		}
	}
	return true;
}

private function onImageLoaded(evt:Event):void
{
	switch(processStatus)
	{
		case MAKING_ACTION:
			actionImageHandler();
			break;
		case MAKING_EFFECT:
			effectImageHandler();
			break;
		case IDLE:
			previewHandler();
			break;
		case SCALING_BITMAP:
			scaleBitmapHandler();
			break;
		case COMPRESS:
			compressHandler();
			break;
	}
}

private function actionImageHandler():void
{
	var bmpList:Vector.<Bitmap> = Vector.<Bitmap>(LoadQueue.getInstance().completeList);
	setOffset(bmpList, true);
}

private function effectImageHandler():void
{
	var bmpList:Vector.<Bitmap> = Vector.<Bitmap>(LoadQueue.getInstance().completeList);
	setOffset(bmpList);
}

private function scaleBitmapHandler():void
{
	var mat:Matrix = new Matrix();
	var scaleValue:Number = scaleRate.value / 100;
	mat.scale(scaleValue, scaleValue);
	
	var bmpList:Vector.<Bitmap> = Vector.<Bitmap>(LoadQueue.getInstance().completeList);
	var srcBmpData:BitmapData;
	var outputBmpData:BitmapData;
	var fs:FileStream = new FileStream();
	var encoder:PNGEncoder = new PNGEncoder();
	var path:String;
	for (var i:int = 0; i < bmpList.length; ++i)
	{
		path = readingFiles[i];
		srcBmpData = bmpList[i].bitmapData;
		outputBmpData = new BitmapData(srcBmpData.width * scaleValue, srcBmpData.height * scaleValue, true, 0);
		outputBmpData.draw(srcBmpData, mat, null, null, null, true);
		
		fs.open(new File(path), FileMode.WRITE);
		fs.writeBytes(encoder.encode(outputBmpData));
		fs.close();
	}
	processStatus = IDLE;
}

private function preview():void
{
	if (outputPath.text && outputPath.text.length)
	{
		LoadQueue.getInstance().completeList.length = 0;
		LoadQueue.getInstance().loadImage(outputPath.text);
	}
}

private function previewHandler():void
{
	previewSWF = LoadQueue.getInstance().completeList.shift() as MovieClip;
}

private function setOffset(bmpList:Vector.<Bitmap>, isAction:Boolean = false):void
{
	var bmpData:BitmapData;
	var rects:Vector.<Rectangle> = new Vector.<Rectangle>();
	var zeroPoint:Point = new Point();
	var rect:Rectangle;
	var file:File;
	var dest:File;
	var index:int;
	var path:String;
	var output:File;
	var fs:FileStream = new FileStream();
	if (readingFiles.length)
	{
		index = readingFiles[0].lastIndexOf("/");
		path = readingFiles[0].substr(0, index + 1);
	}
	var encoder:PNGEncoder = new PNGEncoder();
	for (var i:int = 0; i < bmpList.length; i++)
	{
		bmpData = bmpList[i].bitmapData;
		rect = bmpData.getColorBoundsRect(0xFF000000, 0x00000000, false); // 不包括透明色的
		if (isAction)
		{
			rect.x += (512 - bmpData.width) * 0.5;
			rect.y += (512 - bmpData.height) * 0.5;
		}
		
		if (i < 10)
		{
			output = new File(path + "output/0" + i + "_" + rect.x + "_" + rect.y + ".png");
		}
		else
		{
			output = new File(path + "output/" + i + "_" + rect.x + "_" + rect.y + ".png");
		}
		fs.open(output, FileMode.WRITE);
		fs.writeBytes(encoder.encodeByteArray(bmpData.getPixels(rect), rect.width, rect.height));
		fs.close();
	}
	if (tmpJSFL.exists)
	{
		tmpJSFL.openWithDefaultApplication();
	}
	processStatus = IDLE;
}

private function modifyJSFL(url:String):void
{
	if (!jsflFile.exists)
	{
		return;
	}
	
	tmpJSFL = File.applicationStorageDirectory.resolvePath("tmpJSFL.jsfl");
	jsflFile.copyTo(tmpJSFL, true);
	
	var fs:FileStream = new FileStream();
	fs.open(tmpJSFL, FileMode.UPDATE);
	var content:String = fs.readUTFBytes(fs.bytesAvailable);
	var index:int = content.indexOf("\r\n");
	content = "var folder = \"" + url + "/output\";" + content.substr(index);
	
	fs.position = 0;
	fs.truncate();
	fs.writeUTFBytes(content);
	fs.close();
}

private function compressPNG():void
{
	processStatus = COMPRESS;
	LoadQueue.getInstance().completeList.length = 0;
	if (file.exists)
	{
		readingFiles = new Vector.<String>();
		if (readFile(file))
		{
			LoadQueue.getInstance().loadImageList(readingFiles);
		}
	}
}

private function compressHandler():void
{
	var bmpList:Vector.<Bitmap> = Vector.<Bitmap>(LoadQueue.getInstance().completeList);
	var srcBmpData:BitmapData;
	var fs:FileStream = new FileStream();
	var encoder:JPEGEncoder = new JPEGEncoder(80);
	var path:String;
	var jpgData:ByteArray;
	var data:ByteArray = new ByteArray();
	data.endian = Endian.LITTLE_ENDIAN;
	var alphaData:ByteArray = new ByteArray();
	alphaData.endian = Endian.LITTLE_ENDIAN;
	var vec:Vector.<uint>;
	if (cbCompressSingle.selected)
	{
		fs.open(file.resolvePath(file.name + ".jnp"), FileMode.WRITE);
		fs.endian = Endian.LITTLE_ENDIAN;
	}
	
	for (var i:int = 0; i < bmpList.length; ++i)
	{
		path = readingFiles[i];
		if (!cbCompressSingle.selected)
		{
			fs.open(new File(path.substring(0, path.length - 4) + ".jng"), FileMode.WRITE);
			fs.endian = Endian.LITTLE_ENDIAN;
		}
		
		//编码jpg
		srcBmpData = bmpList[i].bitmapData;
		data.clear();
		data.writeShort(srcBmpData.width);
		data.writeShort(srcBmpData.height);
		jpgData = encoder.encode(srcBmpData);
		data.writeBytes(jpgData);
		
		//写入jpg
		fs.writeUnsignedInt(data.length);
		data.compress();
		fs.writeUnsignedInt(data.length);
		fs.writeBytes(data);
		
		//编码alpha
		alphaData.clear();
		vec = srcBmpData.getVector(srcBmpData.rect);
		for (var j:int = 0; j < vec.length; ++j)
		{
			alphaData.writeByte(vec[j] >> 24);
		}
		alphaData.compress();
		//写入alpha
		fs.writeUnsignedInt(alphaData.length);
		fs.writeBytes(alphaData);
		if (!cbCompressSingle.selected)
		{
			fs.close();
		}
	}
	if (cbCompressSingle.selected)
	{
		fs.close();
	}
	processStatus = IDLE;
}