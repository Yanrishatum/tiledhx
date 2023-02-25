package tiled;

import tiled.types.TmxTemplate;
import tiled.types.JsonDef;
import tiled.types.TileImageType;
import tiled.types.ImageType;
import tiled.types.Properties;
import tiled.types.TmxObject;
import tiled.types.TmxMap;
import haxe.Json;
import haxe.io.Path;
import tiled.types.TmxTileset;
import tiled.types.DynamicProps;

using tiled.types.XmlTools;

/**
  The general Tiled map loader.
  
  Main entry-point for loading Tiled maps and offers a number of options regarding behavior of how the maps should be loaded.
  
  See samples and Readme for initial configuration instructions.
**/
class Tiled {
  
  var tsxCache:Map<String, TmxTileset> = [];
  var templateCache: Map<String, TmxTemplate> = [];
  
  public var objectTypes:Map<String, TmxDynamicClass> = [];
  public var enumTypes: Map<String, TmxDynamicEnum> = [];
  
  #if (tiled_props=="project")
  
  #else
  
  /**
    Causes child layers in Group layers to inherit Group properties during flattening with `flattenLayers`.
    
    Note that all layers will inherit the properties, and in case of duplicates, child layer property takes priority.
  **/
  public var inheritGroupPropertiesOnFlatten:Bool = false;
  
  #end
  
  /**
    Removes all `TGroup` layers and ensures `layers` is linear array.
    
    This will lead to a loss of data, since groups can contain properties which are subsequently lost during flattening process.
    Only in `dynamic` property mode: It can be circumvented by enabling `inheritGroupPropertiesOnFlatten`.
    
    Following properties are applied to child layers:
    * Group and layer `offsetX` and `offsetY` are combined.
    * If group `visibility` is set to `false`, children will inherit hidden flag.
    * `tintColor` and `opacity` are multiplied with Group values.
    
    Note that you can use `TmxMap.flateIterator()` to iterate the layers in a flat manner without loss of data.
  **/
  public var flattenLayers:Bool = false;
  
  /**
    Converts the image paths in various objects from relative to loaded file to absolute path.
    
    I.e. when loading `maps/map.tmx` that uses `maps/tileset.png`, Tiled will store path to the image as `tileset.png`, as that's relative path from the `map.tmx`. 
    When `deLocalizeImagePaths` is set, the path would be converted back to `maps/tileset.png` using the `maps/map.tmx` path and the relative path of the `tileset.png`.
    
    This can be useful when not using `ImageType` and loading images via string path as that allows using paths local to the asset root.
  **/
  public var deLocalizeImagePaths:Bool = false;
  
  /**
    Converts the properties with `file` type relative to the asset root path, instead of whatever file property was stored in.
  **/
  public var deLocalizeFileProperties: Bool = true;
  
  /**
    Create new Tiled loader.
  **/
  public function new() {
  }
  
  /**
    Clear the .tsx external tilesets cache.
    
    Can be used for development purposes to ensure changes in TSX files are applied on map reloads.
  **/
  public inline function clearTSXCache() {
    tsxCache = [];
  }
  
  public inline function clearTemplateCache() {
    templateCache = [];
  }
  
  public inline function clearCache() {
    clearTSXCache();
    clearTemplateCache();
  }
  
  /**
    Clear the `objectTypes` and `enumTypes` lists.
  **/
  public inline function clearObjectTypes() {
    objectTypes = [];
    enumTypes = [];
  }
  
  /**
    Checks whether object type with a given name exists or not.
  **/
  public inline function hasObjectType(name:String):Bool {
    return objectTypes.exists(name);
  }
  
  /**
    Checks whether enum with a given name exists or not.
  **/
  public inline function hasEnumType(name: String): Bool {
    return enumTypes.exists(name);
  }
  
  /**
    Retrieve the `Properties` of the object type with given name.
    Returns `null` if no such object type exists.
  **/
  public function getObjectType(name:String):Null<Properties> {
    final ot = objectTypes[name];
    if (ot != null) return ot.properties;
    return null;
  }
  
  public inline function getEnumType(name: String): TmxDynamicEnum {
    return enumTypes[name];
  }
  
  /**
    Load the `objecttypes.xml` from the given asset `path`.
  **/
  public function loadObjectTypes(path:String) {
    readObjectTypes(loadXML(path), path);
  }
  
  /**
    Load the object properties json export of object types. (Tiled 1.9+)
  **/
  public function loadObjectProperties(path: String) {
    loadObjectPropertiesFromData(loadJson(path), path);
  }
  
  /**
    Load the raw object properties.
  **/
  public function loadObjectPropertiesFromData(data: Array<TiledPropertyType>, path: String) {
    // Because class definition is out of order, first collect all classes and then resolve them.
    var classList: Map<String, TiledPropertyType> = [];
    
    var i = 0;
    while (i < data.length) {
      var type = data[i++];
      switch (type.type) {
        case KEnum:
          final denum: TmxDynamicEnum = {
            isFlags: type.valuesAsFlags,
            isString: type.storageType == KString,
            #if tiled_metadata
            names: type.values
            #end
          }
          enumTypes[type.name] = denum;
        case KClass:
          classList[type.name] = type;
        default: trace('Invalid object type for ${type.name}! Expectd enum or class! Got: ${type.type}');
      }
    }
    function resolve(type: TiledPropertyType) {
      var ot = objectTypes[type.name];
      if (ot == null) {
        ot = {
          color: type.color.parseColor(0xffa0a0a4),
          properties: new Properties()
        };
        objectTypes[type.name] = ot;
        for (prop in type.members) {
          if (prop.type == 'class') resolve(classList[prop.propertyType]);
          @:privateAccess ot.properties.addProp(prop.name, prop.type, prop.value, prop.propertyType, this);
        }
        if (deLocalizeFileProperties) ot.properties.deLocalize(path);
      }
    }
    for (cl in classList) resolve(cl);
  }
  
  /**
    Load the Tiled `.tiled-project` file and extract object properties from it.
  **/
  public function loadTiledProject(path: String) {
    var project: TiledProjectFile = loadJson(path);
    loadObjectPropertiesFromData(project.propertyTypes, path);
  }
  
  function readObjectTypes(p:Xml, path:String) {
    if (p.nodeType == Document) p = p.firstElement();
    for (el in p) if (el.nodeType == Element) {
      var props:Properties = new Properties();
      props.loadObjectTypes(el, this);
      if (deLocalizeFileProperties) props.deLocalize(path);
      objectTypes.set(el.get('name'), { color: el.catt('color'), properties: props });
    }
  }
  
  /**
    Load the `TmxMap` from the given asset `path`.
  **/
  public inline function loadTMX(path:String):TmxMap {
    return new TmxMap(path).loadXML(loadXML(path), this);
  }
  
  /**
    Load the external TmxTileset from the given relative `path`.
    
    The loaded TSX is cached for later reuse.
    
    @param path The external tileset absolute or relative path.
    @param relativeTo The parent file asset path the `path` argument is relative to. (Not directory!)
    @param ignoreCache Forces TSX to be reloaded and re-cached.
  **/
  public function loadTSX(path:String, ?relativeTo: String, ignoreCache: Bool = false):TmxTileset {
    final key = path.normalizePath(relativeTo);
    var tsx = tsxCache[key];
    if (tsx == null || ignoreCache) {
      tsxCache[key] = tsx = makeTSX(key);
    }
    return tsx;
  }
  
  /**
  
  **/
  public function loadTemplate(path:String, ?relativeTo:String, ignoreCache: Bool = false):TmxTemplate {
    final key = path.normalizePath(relativeTo);
    var tpl = templateCache[key];
    if (tpl == null || ignoreCache) {
      templateCache[key] = tpl = makeTemplate(key);
    }
    return tpl;
  }
  
  function makeTSX(path:String):TmxTileset {
    var tsx = new TmxTileset(path);
    tsx.loadXML(loadXML(path), null, this);
    return tsx;
  }
  
  function makeTemplate(path: String): TmxTemplate {
    var tpl = new TmxTemplate(path);
    tpl.loadXML(loadXML(path), this);
    return tpl;
  }
  
  /**
    Load the XML file with a given path. 
    
    Unless provided default implementation based on supported backends - should be overriden in order for loader to work.
    
    See Readme for list of supported backend.
    
    @param path The XML file absolute or relative path.
    @param relativeTo The parent file asset path the `path` argument is relative to. (Not directory!)
  **/
  public dynamic function loadXML(path:String, ?relativeTo:String):Xml {
    #if heaps
    return Xml.parse(hxd.Res.load(path.normalizePath(relativeTo)).entry.getText());
    #else
    throw "Assiggn or override loadXML";
    #end
  }
  
  /**
    Load the Json file with a given path.
    
    Unless provided default implementation based on supported backends - should be overriden in order for loader to work.
    
    See Readme for list of supported backend.
    
    @param path The json file absolute or relative path.
    @param relativeTo The parent file asset path the `path` argument is relative to. (Not directory!)
  **/
  public dynamic function loadJson(path:String, ?relativeTo:String):Dynamic {
    #if heaps
    return Json.parse(hxd.Res.load(path.normalizePath(relativeTo)).entry.getText());
    #else
    throw "Assiggn or override loadJson";
    #end
  }
  
  /**
    Load the referenced image file with a given path.
    
    Uses `ImageType.loadImage` and should provide the backend-specific image instance.
    
    Override this method in case generic `loadImage` is not feasible in your engine setup.
    
    @param path The image file absolute or relative path.
    @param relativeTo The parent file asset path the `path` argument is relative to. (Not directory!)
    
    @see `tiled.types.ImageType` and Readme for customization details.
  **/
  public dynamic function loadImage(path:String, ?relativeTo:String):ImageType {
    return ImageType.loadImage(path, relativeTo);
  }
  
  /**
    Split the tileset image into the tile images.
  **/
  public dynamic function loadTileset(base:ImageType, tileset:TmxTileset):Array<TileImageType> {
    var result = [];
    final tw = tileset.tileWidth;
    final th = tileset.tileHeight;
    final iw = tileset.imageWidth - tw;
    final ih = tileset.imageHeight - th;
    final tx = tileset.tileOffsetX;
    final ty = tileset.tileOffsetY;
    final margin = tileset.margin;
    final ox = tw + tileset.spacing;
    final oy = th + tileset.spacing;
    var y = margin; var x;
    while (y <= ih) {
      x = margin;
      while (x <= iw) {
        result.push(subRegion(base, x, y, tw, th, tx, ty));
        x += ox;
      }
      y += oy;
    }
    return result;
  }
  
  /**
    Extract the sub-region of the backend image as a tile image.
    
    Override this method in case generic `subRegion` is not feasible in your engine setup.
    
    @param image The source image region of which should be extracted.
    @param x The horizontal position of the sub-region on the source image.
    @param y The vertical position of the sub-region on the source image.
    @param w The width of the sub-region.
    @param h The height of the sub-region.
    @param offsetX Horizontal visual offset that should be appled when rendering the sub-region.
    @param offsetY Vertical visual offset that should be applied when rendering the sub-region.
  **/
  public dynamic function subRegion(image:ImageType, x:Int, y:Int, w:Int, h:Int, offsetX:Int, offsetY:Int):TileImageType {
    return ImageType.subRegion(image, x, y, w, h, offsetX, offsetY);
  }
  
  public dynamic function imageSize(image: ImageType): { width: Int, height: Int } {
    #if heaps
    return { width: image.iwidth, height: image.iheight };
    #else
    throw "Old Tiled map without tileset image size! Please override `Tiled.imageSize` method!";
    #end
  }
  
  #if heaps
  
  #if (tiled_props!="project")
  /**
    Helper method to load `objecttypes.xml` from the given Heaps `Resource`.
  **/
  public inline function loadObjectTypesResource(res:hxd.res.Resource) {
    readObjectTypes(Xml.parse(res.entry.getText()), res.entry.path);
  }
  #end
  
  /**
    Helper method to load TMX map from the given Heaps `Resource`.
  **/
  public inline function loadTMXResource(res:hxd.res.Resource):TmxMap {
    return new TmxMap(res.entry.path).loadXML(Xml.parse(res.entry.getText()), this);
  }
  #end
  
}