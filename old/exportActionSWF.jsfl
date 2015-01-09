var folder = "file:///C:/Users/WorrySprite/Desktop/swordman";
var doc;
var tline;
var lib;
var pack = "com.worrysprite.action.";
function init()
{
	if (folder != null)
	{
		doc = fl.createDocument();
		doc.width = 512;
		doc.height = 512;
		doc.frameRate = 8;
		tline = doc.getTimeline();
		lib = doc.library;
		readFolder();
	}
}
var action = ["attack", "run", "die"];

function readFolder()
{
	var subFolder;
	var files = [];
	var tmp;
	for (var i = 0; i < action.length; i++)
	{
		tmp = FLfile.listFolder(folder + "/" + action[i] + "/*.png", "files");
		for (var k = 0; k < tmp.length; k++)
		{
			files.push(folder + "/" + action[i] + "/" + tmp[k]);
		}
	}
	readFile(files);
}

function readFile(files)
{
	var fileName;
	var item;
	var tmp;
	var x, y, w, h;
	var index;
	var itemName;
	var element;
	tline.addNewLayer();
	for (var i = 0; i < files.length; i++)
	{
		tline.setSelectedLayers(0);
		fileName = files[i];
		index = fileName.lastIndexOf(".png");
		tmp = fileName.substring(0, index).split("_");
		if (tmp.length < 4)
		{
			continue;
		}
		x = Number(tmp[tmp.length - 4]);
		y = Number(tmp[tmp.length - 3]);
		w = Number(tmp[tmp.length - 2]);
		h = Number(tmp[tmp.length - 1]);
		index = fileName.lastIndexOf("/");
		itemName = fileName.substring(index + 1);
		doc.importFile(fileName, true);
		lib.selectItem(itemName);
		item = lib.getSelectedItems()[0];
		doc.addItem({x:0, y:0}, item);
		element = tline.layers[0].frames[0].elements[0];
		element.x = (512 - element.width) / 2;
		element.y = (512 - element.height) / 2;
		doc.selection = [element];
		doc.breakApart();
		tline.layers[1].locked = true;
		doc.setSelectionRect({left:x, top:y, right:x + w, bottom:y + h}, true, true);
		doc.convertSelectionToBitmap();
		doc.clipCut();
		tline.layers[1].locked = false;
		tline.setSelectedLayers(1);
		doc.clipPaste(true);
		tline.setSelectedLayers(0);
		doc.selection = tline.layers[0].frames[0].elements;
		doc.deleteSelection();
		lib.deleteItem(itemName);
	}
	tline.deleteLayer(0);
	tline.layers[0].frames[0].actionScript = "import flash.system.Security;\nSecurity.allowDomain(\"*\");";
	
	index = folder.lastIndexOf("/");
	var folderName = folder.substring(index + 1);
	
	lib.selectAll();
	lib.setItemProperty('compressionType', 'photo');
	lib.setItemProperty('useImportedJPEGQuality', false);
	lib.setItemProperty('quality', 60);
	for (var j = 0; j < lib.items.length; j++)
	{
		lib.items[j].linkageExportForAS = true;
		lib.items[j].linkageExportInFirstFrame = true;
		lib.items[j].linkageBaseClass = "flash.display.BitmapData";
		lib.items[j].linkageClassName = pack + folderName + "_" + j;
	}
	
	//doc.exportSWF(folder + ".swf");
	fl.saveDocument(doc, folder + ".fla");
	doc.close();
}

init();