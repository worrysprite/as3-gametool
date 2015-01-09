var folder = "file:///C:/Users/WorrySprite/Desktop/swordman";
var doc;
var tline;
var lib;
var pack = "com.worrysprite.effect.";
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

function readFolder()
{
	var subFolder;
	var files = [];
	var allBmps = FLfile.listFolder(folder + "/*.png", "files");
	for (var k = 0; k < allBmps.length; k++)
	{
		files.push(folder + "/" + allBmps[k]);
	}
	readFile(files);
}

function readFile(files)
{
	var fileName;
	var item;
	var tmp;
	var x, y;
	var index;
	var itemName;
	var element;
	//tline.addNewLayer();
	for (var i = 0; i < files.length; i++)
	{
		tline.setSelectedLayers(0);
		fileName = files[i];
		index = fileName.lastIndexOf(".png");
		tmp = fileName.substring(0, index).split("_");
		if (tmp.length < 3)
		{
			continue;
		}
		x = Number(tmp[tmp.length - 2]);
		y = Number(tmp[tmp.length - 1]);
		index = fileName.lastIndexOf("/");
		itemName = fileName.substring(index + 1);
		doc.importFile(fileName, true);
		lib.selectItem(itemName);
		item = lib.getSelectedItems()[0];
		doc.addItem({x:x, y:y}, item);
		element = tline.layers[0].frames[0].elements[i];
		element.x = x;
		element.y = y;
	}
	tline.layers[0].frames[0].actionScript = "import flash.system.Security;\nSecurity.allowDomain(\"*\");";
	
	index = folder.lastIndexOf("/output");
	var folderName = folder.substring(0, index);
	index = folderName.lastIndexOf("/");
	folderName = folderName.substring(index + 1);
	
	lib.selectAll();
	lib.setItemProperty('compressionType', 'photo');
	lib.setItemProperty('useImportedJPEGQuality', false);
	lib.setItemProperty('quality', 80);
	for (var j = 0; j < lib.items.length; j++)
	{
		lib.items[j].linkageExportForAS = true;
		lib.items[j].linkageExportInFirstFrame = true;
		lib.items[j].linkageBaseClass = "flash.display.BitmapData";
		lib.items[j].linkageClassName = pack + folderName + "_" + j;
	}
	
	doc.exportSWF(folder + "/" + folderName + ".swf");
	fl.saveDocument(doc, folder + "/" + folderName + ".fla");
}

init();