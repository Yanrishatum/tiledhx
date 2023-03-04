package tiled.project;

import tiled.types.Properties;
import tiled.types.TmxTileset;
import tiled.types.TmxLayer;
import tiled.types.TmxObject;
import tiled.types.TmxMap;

@:noBuild
class PropertyClass implements TiledClass {
  
  #if (tiled_props=="project")
  
  public var props: Properties;
  
  public function new() {
    props = new Properties();
  }
  
	public function loadProperties(properties:PropertyIterator, loader: Tiled, path: String) {
  }

	public function finalize(objects: Array<TmxObject>, path: String, loader: Tiled) {
    props.finalize(objects, path, loader);
  }
  
  public function transferToObject(obj: TmxObject): TiledClass {
    var cl = new PropertyClass();
    cl.props.inherit(this.props);
    return cl;
  }
  
	public function transferToTileset(tset:TmxTileset):TiledClass {
		var cl = new PropertyClass();
    cl.props.inherit(this.props);
    return cl;
	}
  #end

}