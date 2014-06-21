/**
使 用方法:

//建立一个 SWVMaker实例
var maker:SWFMaker = new SWFMaker();

//增加一个祯
maker.addFrame(frameBitmapData1);
//增加一个祯
maker.addFrame(frameBitmapData2);

var out:ByteArray = maker.finish(); 

*/
package encode {
    
    import flash.display.BitmapData;
    import flash.utils.ByteArray;
    
    import org.bytearray.images.JPEGEncoder;
    import org.bytearray.images.PNGEncoder;
    import org.libspark.swfassist.io.*;
    import org.libspark.swfassist.swf.io.*;
    import org.libspark.swfassist.swf.structures.*;
    import org.libspark.swfassist.swf.tags.*;

    public class SWFMaker {
            private var _quality:uint;
            private var _width:uint;
            private var _height:uint;
            private var _fps:uint;
            //
            private var _jpgEnc:JPEGEncoder;
			private var _pngEnc:PNGEncoder;
            //
            private var _swf:SWF;
            //
            private var _frame:uint;
            //
            private var _tagSCR:StyleChangeRecord;
            private var _tagSER1:StraightEdgeRecord;
            private var _tagSER2:StraightEdgeRecord;
            private var _tagSER3:StraightEdgeRecord;
            private var _tagSER4:StraightEdgeRecord;
            private var _tagSF:ShowFrame; 
			
			private var _fx:Number;
			private var _fy:Number;
			private var _fwidth:Number;
			private var _fheight:Number;
			private var _whiteNum:int;
            public function SWFMaker(width:uint=320,height:uint=240,fps:uint=12,quality:uint=50,whiteNum:int=0) {
                    _width = width;
                    _height = height;
                    _quality = quality;
                    _fps = fps; 
					_whiteNum=whiteNum;
                    /*_tagSCR = new StyleChangeRecord();
                    _tagSCR.stateFillStyle1=true;
                    _tagSCR.stateMoveTo = true;
                    _tagSCR.moveDeltaX = _width;
                    _tagSCR.moveDeltaY = _height;
                    _tagSCR.fillStyle1=1;
                    _tagSCR.fillStyle0=0; 

                    _tagSER1= new StraightEdgeRecord();
                    _tagSER1.generalLine=false;
                    _tagSER1.verticalLine=false;
                    _tagSER1.deltaX=-_width;
                    _tagSER1.deltaY=0; 

                    _tagSER2= new StraightEdgeRecord();
                    _tagSER2.generalLine=false;
                    _tagSER2.verticalLine=true;
                    _tagSER2.deltaX=0;
                    _tagSER2.deltaY=-_height; 

                    _tagSER3= new StraightEdgeRecord();
                    _tagSER3.generalLine=false;
                    _tagSER3.verticalLine=false;
                    _tagSER3.deltaX=_width;
                    _tagSER3.deltaY=0; 

                    _tagSER4= new StraightEdgeRecord();
                    _tagSER4.generalLine=false;
                    _tagSER4.verticalLine=true;
                    _tagSER4.deltaX=0;
                    _tagSER4.deltaY=_height; */

                    
                    _jpgEnc = new JPEGEncoder(_quality);
					_pngEnc = new PNGEncoder();
                    start();
            }
            public function get frame():uint{
                    return _frame
            }
            public function start() :void{
                    
                    this._swf = new SWF();	
					this._swf.header.version = 0x09;
					this._swf.header.frameSize.xMin = 0;
					this._swf.header.frameSize.yMin = 0;
					this._swf.header.frameSize.xMax =_width;
					this._swf.header.frameSize.yMax =_height;
					this._swf.header.frameRate = _fps;
					this._swf.header.isCompressed = true;
					this._swf.fileAttributes.isActionScript3 = true;
					this._swf.fileAttributes.hasMetadata = false;
					
					var bgColor:SetBackgroundColor = new SetBackgroundColor( );
					bgColor.backgroundColor.fromUint( 0x000000 );
					this._swf.tags.addTag( bgColor );
					
					var sceneDefine:DefineSceneAndFrameLabelData=new DefineSceneAndFrameLabelData();
					 var sceneData:SceneData=new SceneData();
                    sceneData.frameOffset=0;
                    sceneData.name="scene1";
                    sceneDefine.scenes.push(sceneData);
					_swf.tags.addTag(sceneDefine);
					
					_frame = 1;
            }
            public function addFrame(bmpData:BitmapData,x:Number=0,y:Number=0):void {
            	
            	_fx=x;
            	_fy=y;
            	_fwidth=bmpData.width;
            	_fheight=bmpData.height;
            	
				var jpgBA:ByteArray=_jpgEnc.encode(bmpData);
				//var pngBA:ByteArray = _pngEnc.encode(bmpData);
				
        		var alphaBA:ByteArray=new ByteArray();
        		var str:String="";
				for(var i:int=0;i<bmpData.height;i++)
				{
					for(var j:int=0;j<bmpData.width;j++)
					{
						var color:uint=(bmpData.getPixel32(j,i)>>24)&(0xff);
						//str+=color.toString(16)+"|"+bmpData.getPixel32(j,i).toString(16)+",";
						//alphaBA.writeByte(color);
						if(color==0)
						{
							alphaBA.writeByte(0);
						}
						else if(color<0xff)
						{
							
							alphaBA.writeByte(uint(color/_whiteNum));
							
						}
						else
						{
							alphaBA.writeByte(0xff);
						}
					}
					str+="\n";
				}
				//trace(str)
				alphaBA.compress();
				var definePNG:DefineBitsJPEG3 = new DefineBitsJPEG3(TagCodeConstants.TAG_DEFINE_BITS_JPEG3); 
				definePNG.characterId = (_frame-1)*2+1;
				definePNG.jpegData = jpgBA;
				//definePNG.jpegData = pngBA;
				definePNG.bitmapAlphaData = alphaBA;
				this._swf.tags.addTag( definePNG );
                //define bits jpeg2
                /*var tagDBJ:DefineBitsJPEG2 = new DefineBitsJPEG2();
                tagDBJ.characterId = (_frame-1)*2+1;
                tagDBJ.jpegData = _jpgEnc.encode(bmpData);*/
                //define shape
               /* var tagDS:DefineShape = new DefineShape();
                tagDS.shapeId = (_frame-1)*2+2;
                tagDS.shapeBounds.xMin = 0;
                tagDS.shapeBounds.xMax = _width;
                tagDS.shapeBounds.yMin = 0;
                tagDS.shapeBounds.yMax = _height;
                //define fill style
                var tagFS:FillStyle = new FillStyle();
                tagFS.color.fromUint(0xff000000);
                tagFS.fillStyleType = 67;
                tagFS.bitmapId = (_frame-1)*2+1;
                tagFS.bitmapMatrix.hasScale = true;
                tagFS.bitmapMatrix.scaleX = 20;
                tagFS.bitmapMatrix.scaleY = 20;
                //
                tagDS.shapes.shapeRecords = [_tagSCR,_tagSER1,_tagSER2,_tagSER3,_tagSER4];
                tagDS.shapes.fillStyles.fillStyles = [tagFS];
                //
                var tagPO:PlaceObject2 = new PlaceObject2();
                tagPO.hasCharacter = true;
                tagPO.hasMatrix = true;
                tagPO.depth=_frame;
                tagPO.characterId = (_frame-1)*2+2;
                //
               // _swf.tags.addTag(tagDBJ);
                _swf.tags.addTag(tagDS);
                _swf.tags.addTag(tagPO);
                _swf.tags.addTag(_tagSF);    
                //*/
               //shape
				//this.setShape();
				
				
				// placeObject
				//this.setPlaceObject();
				if(_tagSF == null)
				{
					_tagSF = new ShowFrame();
					_swf.tags.addTag(_tagSF);
				}
                //_frame++;
				depth++;
            }
            private function setShape():void
			{
				var defineShape:DefineShape = new DefineShape(); 
				defineShape.shapeId = (_frame-1)*2+2;;
				defineShape.shapeBounds.xMin = 0;
				defineShape.shapeBounds.yMin = 0;
				defineShape.shapeBounds.xMax = _fwidth;
				defineShape.shapeBounds.yMax = _fheight;
				
				var fillStyle:FillStyle = new FillStyle();  
				fillStyle.fillStyleType = FillStyleTypeConstants.CLIPPED_BITMAP_FILL;
				fillStyle.bitmapId = (_frame-1)*2+1; 
				fillStyle.bitmapMatrix.hasScale = true; 
				fillStyle.bitmapMatrix.scaleX = 20;
				fillStyle.bitmapMatrix.scaleY = 20; 
				var shape : ShapeWithStyle = defineShape.shapes; 
				shape.fillStyles.fillStyles.push(fillStyle); 
				
				
				var _tagSCR:StyleChangeRecord = new StyleChangeRecord();
	            _tagSCR.stateFillStyle1=true;
	            _tagSCR.stateMoveTo = true;
	            _tagSCR.moveDeltaX = _fwidth;
	            _tagSCR.moveDeltaY = _fheight;
	            _tagSCR.fillStyle1=1;
	            _tagSCR.fillStyle0=0; 
	
	            var _tagSER1:StraightEdgeRecord= new StraightEdgeRecord();
	            _tagSER1.generalLine=false;
	            _tagSER1.verticalLine=false;
	            _tagSER1.deltaX=-_fwidth;
	            _tagSER1.deltaY=0; 
	
	            var _tagSER2:StraightEdgeRecord= new StraightEdgeRecord();
	            _tagSER2.generalLine=false;
	            _tagSER2.verticalLine=true;
	            _tagSER2.deltaX=0;
	            _tagSER2.deltaY=-_fheight; 
	
	            var  _tagSER3:StraightEdgeRecord= new StraightEdgeRecord();
	            _tagSER3.generalLine=false;
	            _tagSER3.verticalLine=false;
	            _tagSER3.deltaX=_fwidth;
	            _tagSER3.deltaY=0; 
	
	            var _tagSER4:StraightEdgeRecord= new StraightEdgeRecord();
	            _tagSER4.generalLine=false;
	            _tagSER4.verticalLine=true;
	            _tagSER4.deltaX=0;
	            _tagSER4.deltaY=_fheight; 
				shape.shapeRecords=[_tagSCR,_tagSER1,_tagSER2,_tagSER3,_tagSER4];
				_swf.tags.addTag(defineShape);
				
				
			}
			private var depth:int;
			
			private function setPlaceObject():void
			{
				var removeObj:RemoveObject2=new RemoveObject2();
				removeObj.depth=1;
				this._swf.tags.addTag( removeObj );
				
				var placeObj:PlaceObject2 = new PlaceObject2();
				placeObj.isMove=false;
				placeObj.characterId = (_frame-1)*2+2;
				placeObj.depth = depth;
				placeObj.clipDepth = depth;
				placeObj.hasMatrix=true;
				placeObj.matrix=new Matrix();
				placeObj.matrix.translateX=_fx;
				placeObj.matrix.translateY=_fy;
				placeObj.hasCharacter = true;
				//placeObj.hasCacheAsBitmap = true;
				//placeObj.hasImage = true;
				this._swf.tags.addTag( placeObj );
			}
            public function finish():ByteArray {
            	this._swf.header.numFrames=_frame;
                var data:ByteArray = new ByteArray();
                var swfwriter:SWFWriter = new SWFWriter();
                var out:ByteArrayOutputStream = new ByteArrayOutputStream(data);
                var context:WritingContext = new WritingContext();
                swfwriter.writeSWF(out,context,_swf);
                return data;
            }
    }
} 
