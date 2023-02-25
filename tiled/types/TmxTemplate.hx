package tiled.types;

class TmxTemplate {
  
  public var path: String;
  
  public var tileset: Null<TmxTileset>;
  public var object: TmxObject;
  
  public function new(?path: String) {
    this.path = path;
  }
  
  public function loadXML(x: Xml, loader: Tiled) {
    if (x.nodeType == Document) x = x.firstElement();
    for (el in x) {
      if (el.nodeType == Element) {
        if (el.nodeName == "tileset") {
          var tset = this.tileset = new TmxTileset(path);
          tset.loadXML(el, null, loader);
          if (!tset.isComplete) {
            var tsx = loader.loadTSX(tset.source, this.path);
            tset.loadTSX(tsx);
          }
        } else if (el.nodeName == "object") {
          var obj = this.object = new TmxObject();
          obj.loadXML(el, loader, path, [tileset]);
        }
      }
    }
  }
  
}