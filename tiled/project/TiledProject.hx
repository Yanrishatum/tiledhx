package tiled.project;

import tiled.project.PropertyIterator;
#if !macro
import tiled.types.TmxMap;
import tiled.types.TmxLayer;
import tiled.types.TmxTileset;
import tiled.types.TmxObject;
#end

import haxe.Json;
import tiled.types.JsonDef;

class TiledProject {
  
  
  #if (tiled_props=="project" && !macro)
  
  public static var objectFactory: Map<String, TmxObject->TiledClass> = [];
  public static var tileFactory: Map<String, TmxTile->TiledClass> = [];
  public static var layerFactory: Map<String, TmxLayer->TiledClass> = [];
  public static var tilesetFactory: Map<String, TmxTileset->TiledClass> = [];
  public static var mapFactory: Map<String, TmxMap->TiledClass> = [];
  public static var propertyFactory: Map<String, TiledClass->TiledClass> = [];
  
  public static inline function registerObjectClass(name: String, factory: TmxObject->TiledClass): Void { objectFactory[name] = factory; }
  public static inline function registerTileClass(name: String, factory: TmxTile->TiledClass): Void { tileFactory[name] = factory; }
  public static inline function registerLayerClass(name: String, factory: TmxLayer->TiledClass): Void { layerFactory[name] = factory; }
  public static inline function registerTilesetClass(name: String, factory: TmxTileset->TiledClass): Void { tilesetFactory[name] = factory; }
  public static inline function registerMapClass(name: String, factory: TmxMap->TiledClass): Void { mapFactory[name] = factory; }
  public static inline function registerPropertyClass(name: String, factory: TiledClass->TiledClass): Void { propertyFactory[name] = factory; }
  
  #if tiled_metadata
  public static var wangColorFactory: Map<String, WangColor->TiledClass> = [];
  public static var wangSetFactory: Map<String, WangSet->TiledClass> = [];
  public static inline function registerWangColorClass(name: String, factory: WangColor->TiledClass): Void { wangColorFactory[name] = factory; }
  public static inline function registerWangSetClass(name: String, factory: WangSet->TiledClass): Void { wangSetFactory[name] = factory; }
  #end
  
  static var emptyClassIterator: PropertyIterator = {
    hasNext: function() { return false; },
    next: function() { return { key: "", value: null } },
  };
  public static function xmlIterator(el: Xml): PropertyIterator {
    var iter = el.iterator();
    var next: Xml = null;
    var kv: { key: String, value: RawPropertyValue } = { key: null, value: null };
    return {
      hasNext: function() {
        while (iter.hasNext()) {
          next = iter.next();
          if (next.nodeType == Element) return true;
        }
        return false;
      },
      next: function() {
        kv.key = next.get('name');
        kv.value = if (next.get('type') == 'class') {
          var props = el.elementsNamed("properties");
          if (!props.hasNext()) emptyClassIterator;
          else xmlIterator(props.next());
        } else {
          next.get('value');
        };
        return kv;
      }
    };
  }
  
  /**
    If class is unknown (null or otherwise) - defaults to using PropertyClass wrapper around Properties.
  **/
  public static inline function initWithFallback<T>(factory: T->TiledClass, v: T): TiledClass {
    return factory == null ? new PropertyClass() : factory(v);
  }
  
  public static inline function loadXMLProperties(cl: TiledClass, el: Xml, loader: Tiled, path: String) {
    if (cl != null) {
      if (cl is PropertyClass) {
        var pc: PropertyClass = cast cl;
        pc.props.loadXML(el, loader);
      } else {
        cl.loadProperties(xmlIterator(el), loader, path);
      }
    }
  }
  
  #end
  
  #if macro
  
  public static function generateProject(path: String) {
    #if display
    return;
    #end
    haxe.macro.Context.onAfterGenerate(() -> {
      var proj: TiledProjectFile;
      
      if (sys.FileSystem.exists(path)) {
        proj = Json.parse(sys.io.File.getContent(path));
      } else {
        proj = {
          automappingRulesFile: "",
          commands: [],
          extensionsPath: "",
          folders: [],
          propertyTypes: []
        };
      }
      proj.propertyTypes = tiled._internal.ProjectMacro.types;
      sys.io.File.saveContent(path, haxe.Json.stringify(proj, null, "    "));
    });
  }
  
  #end
  
}