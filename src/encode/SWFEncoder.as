package encode
{
	import flash.display.BitmapData;
	import flash.utils.ByteArray;
	
	import mx.graphics.codec.JPEGEncoder;
	
	import org.libspark.swfassist.io.ByteArrayOutputStream;
	import org.libspark.swfassist.swf.io.SWFWriter;
	import org.libspark.swfassist.swf.io.WritingContext;
	import org.libspark.swfassist.swf.structures.FillStyle;
	import org.libspark.swfassist.swf.structures.FillStyleTypeConstants;
	import org.libspark.swfassist.swf.structures.Matrix;
	import org.libspark.swfassist.swf.structures.SWF;
	import org.libspark.swfassist.swf.structures.ShapeWithStyle;
	import org.libspark.swfassist.swf.structures.StraightEdgeRecord;
	import org.libspark.swfassist.swf.structures.StyleChangeRecord;
	import org.libspark.swfassist.swf.tags.DefineBitsJPEG3;
	import org.libspark.swfassist.swf.tags.DefineSceneAndFrameLabelData;
	import org.libspark.swfassist.swf.tags.DefineShape4;
	import org.libspark.swfassist.swf.tags.PlaceObject3;
	import org.libspark.swfassist.swf.tags.SetBackgroundColor;
	import org.libspark.swfassist.swf.tags.ShowFrame;
	import org.libspark.swfassist.swf.tags.TagCodeConstants;
	public class SWFEncoder
	{
		private var _srcData:BitmapData;
		private var _quality:Number;
		private var _byte:ByteArray;
		private var _swf:SWF;
		
		private var _rx:Number;
		private var _ry:Number;
		public function SWFEncoder()
		{
		}
		public function encode(bitmapData:BitmapData,quality:Number=50,rx:Number=0,ry:Number=0):ByteArray
		{
			_rx=rx;
			_ry=ry;
			_quality=quality;
			initSWF(bitmapData)
			this.writefile();
			this.saveFileToLocal();
			return _byte;
		}
		private function initSWF( srcData:BitmapData ):void
		{		
			_srcData=srcData;
			this._swf = new SWF();	
			this._swf.header.version = 0x09;
			this._swf.header.frameSize.xMin = 0;
			this._swf.header.frameSize.yMin = 0;
			this._swf.header.frameSize.xMax = srcData.width;
			this._swf.header.frameSize.yMax = srcData.height;
			this._swf.header.frameRate = 12;
			this._swf.header.numFrames = 1;
			this._swf.header.isCompressed = true;
			this._swf.fileAttributes.isActionScript3 = true;
			this._swf.fileAttributes.hasMetadata = false;

			/*var ed:EnableDebugger2 = new EnableDebugger2();
			ed.password = "0";
			this._swf.tags.addTag( ed );*/
			
			
			
			
			//set swf backgroun
			 var bgColor:SetBackgroundColor = new SetBackgroundColor( );
			bgColor.backgroundColor.fromUint( 0x000000 );
			this._swf.tags.addTag( bgColor );
			
			var sceneDefine:DefineSceneAndFrameLabelData=new DefineSceneAndFrameLabelData();
			_swf.tags.addTag(sceneDefine);
		}
		private function writefile():void
		{
			var jpg:JPEGEncoder = new JPEGEncoder(this._quality);//new PNGEncoder();
			var jpgBA:ByteArray=jpg.encode(this._srcData);
			
			var alphaBA:ByteArray=new ByteArray();
			for(var i:int=0;i<_srcData.height;i++)
			{
				for(var j:int=0;j<_srcData.width;j++)
				{
					alphaBA.writeByte(_srcData.getPixel32(j,i)>>24);
				}
			}
			alphaBA.compress();
			var definePNG:DefineBitsJPEG3 = new DefineBitsJPEG3(TagCodeConstants.TAG_DEFINE_BITS_JPEG3); 
			definePNG.characterId = 1;
			definePNG.jpegData = jpgBA;
			definePNG.bitmapAlphaData = alphaBA;
			this._swf.tags.addTag( definePNG );
			
			this.setSWF();
		}
		private function saveFileToLocal():void
		{
			var bytes:ByteArray = new ByteArray();
			var swfWritter:SWFWriter =  new SWFWriter();
			var wc:WritingContext = new WritingContext();
			wc.length = 5000;
			
			var baos:ByteArrayOutputStream = new ByteArrayOutputStream( bytes );
			
			swfWritter.writeSWF( baos, wc, this._swf );
			
			_byte=bytes
			/*var file:File = File.desktopDirectory.resolvePath(this._swfFileName + this._fileFomat);//new File("c:/testSavesf/test.swf" );;
			var fileStream:FileStream = new FileStream(); 
			fileStream.open( file, FileMode.WRITE );
	
			fileStream.writeBytes( bytes )
			fileStream.close();*/
			////trace("fileAttributes::" + this._swf.fileAttributes)
		}
		private function setSWF():void
		{
			
			//shape
			this.setShape();
				
			// placeObject
			this.setPlaceObject();
			var showframe:ShowFrame=new ShowFrame();
			_swf.tags.addTag(showframe);
		}
		
		private function setShape():void
		{
			var defineShape:DefineShape4 = new DefineShape4(); 
			defineShape.shapeId = 2;
			defineShape.shapeBounds.xMin = 0;
			defineShape.shapeBounds.yMin = 0;
			defineShape.shapeBounds.xMax = this._srcData.width;
			defineShape.shapeBounds.yMax = this._srcData.height;
			var fillStyle:FillStyle = new FillStyle();  
			fillStyle.fillStyleType = FillStyleTypeConstants.CLIPPED_BITMAP_FILL;
			fillStyle.bitmapId = 1; 
			fillStyle.bitmapMatrix.hasScale = true; 
			fillStyle.bitmapMatrix.scaleX = 20;
			fillStyle.bitmapMatrix.scaleY = 20; 
			var shape : ShapeWithStyle = defineShape.shapes; 
			shape.fillStyles.fillStyles.push(fillStyle); 
			
			var _width:Number=this._srcData.width;
			var _height:Number=this._srcData.height;
			
			var _tagSCR:StyleChangeRecord = new StyleChangeRecord();
            _tagSCR.stateFillStyle1=true;
            _tagSCR.stateMoveTo = true;
            _tagSCR.moveDeltaX = _width;
            _tagSCR.moveDeltaY = _height;
            _tagSCR.fillStyle1=1;
            _tagSCR.fillStyle0=0; 

            var _tagSER1:StraightEdgeRecord= new StraightEdgeRecord();
            _tagSER1.generalLine=false;
            _tagSER1.verticalLine=false;
            _tagSER1.deltaX=-_width;
            _tagSER1.deltaY=0; 

            var _tagSER2:StraightEdgeRecord= new StraightEdgeRecord();
            _tagSER2.generalLine=false;
            _tagSER2.verticalLine=true;
            _tagSER2.deltaX=0;
            _tagSER2.deltaY=-_height; 

            var  _tagSER3:StraightEdgeRecord= new StraightEdgeRecord();
            _tagSER3.generalLine=false;
            _tagSER3.verticalLine=false;
            _tagSER3.deltaX=_width;
            _tagSER3.deltaY=0; 

            var _tagSER4:StraightEdgeRecord= new StraightEdgeRecord();
            _tagSER4.generalLine=false;
            _tagSER4.verticalLine=true;
            _tagSER4.deltaX=0;
            _tagSER4.deltaY=_height; 
			shape.shapeRecords=[_tagSCR,_tagSER1,_tagSER2,_tagSER3,_tagSER4];
			/*var r1 : StyleChangeRecord = new StyleChangeRecord();
			r1.fillStyle0 = 1; 
			r1.moveDeltaX = 0; 
			r1.moveDeltaY = 0; 
			r1.stateFillStyle0 = true; 
			r1.stateMoveTo = true;  
			var r2:StraightEdgeRecord = new StraightEdgeRecord();
			r2.verticalLine = true; 
			r2.deltaY = this._srcData.height;//375; 
			var r3 : StraightEdgeRecord = new StraightEdgeRecord();
			r3.horizontalLine = true; 
			r3.deltaX = this._srcData.width; 
			var r4 : StraightEdgeRecord = new StraightEdgeRecord();
			r4.verticalLine = true; 
			r4.deltaY = -this._srcData.height//-375;
			var r5 : StraightEdgeRecord = new StraightEdgeRecord(); 
			r5.horizontalLine = true;
			r5.deltaX = -this._srcData.width; 
			shape.shapeRecords.push(r1, r2, r3, r4, r5); */
			_swf.tags.addTag(defineShape);
			
			
		}
		
		private function setPlaceObject():void
		{
			var placeObj:PlaceObject3 = new PlaceObject3();
			placeObj.characterId = 2;
			placeObj.depth = 1;
			placeObj.hasMatrix=true;
			placeObj.matrix=new Matrix();
			placeObj.matrix.translateX=-_rx;
			placeObj.matrix.translateY=-_ry;
			placeObj.hasCharacter = true;
			placeObj.hasCacheAsBitmap = true;
			//placeObj.hasImage = true;
			this._swf.tags.addTag( placeObj );
		}
	}
}