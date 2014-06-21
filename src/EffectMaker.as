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
import mx.collections.ArrayCollection;
import mx.controls.Alert;
import mx.graphics.codec.PNGEncoder;
import spark.components.TextInput;

private static const IDLE:String = "idle";
private static const MAKING_ACTION:String = "making_action";
private static const MAKING_EFFECT:String = "making_effect";
private static const CUTTING_JPG:String = "cutting_jpg";
private static const SCALING_BITMAP:String = "scaling_bitmap";

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
	}
}

private function scaleBitmap():void
{
	LoadQueue.getInstance().completeList.length = 0;
	processStatus = SCALING_BITMAP;
	if (file.exists)
	{
		readingFiles = new Vector.<String>();
		readFile(file);
	}
}

private function readFile(dir:File):Boolean
{
	if (!dir || !dir.exists || !dir.isDirectory)
	{
		return false;
	}
	var content:Array = dir.getDirectoryListing();
	var url:String;
	var fileList:Vector.<String> = new Vector.<String>();
	for (var i:int = 0; i < content.length; i++)
	{
		url = content[i].url;
		if (url.length > 4 && url.substr(url.length - 4) == ".png")
		{
			fileList.push(url);
			readingFiles.push(url);
		}
	}
	LoadQueue.getInstance().loadImageList(fileList);
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