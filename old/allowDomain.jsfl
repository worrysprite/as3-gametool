var doc = fl.getDocumentDOM();
if(doc)
{
	var tline = doc.getTimeline();
	tline.layers[0].frames[0].actionScript = "import flash.system.Security;\nSecurity.allowDomain(\"*\");";
	fl.saveDocument(doc);
	doc.exportSWF();
}