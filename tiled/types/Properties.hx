package tiled.types;

import tiled.types.JsonDef;
import haxe.io.Output;
import haxe.io.Input;
using tiled.types.XmlTools;

@:forward @:forward.new @:forwardStatics
abstract Properties(PropertiesImpl) {
  
  @:arrayAccess @:noCompletion
  inline function __get<T>(key: String):Null<T> return this.getRaw(key);
  
}

/**
  Generic list of properties that can be found on the map, layers, tiles and objects.
**/
private class PropertiesImpl {
  
  var props:Map<String, PropertyValue>;
  
  public function new() {
    props = [];
  }
  
  /**
    Returns the internal raw map of the properties.
  **/
  public inline function rawProps():Map<String, PropertyValue> return props;
  /**
    Returns an Iterator over the keys of `this` Properties.
    
    The order of keys is undefined.
  **/
  public inline function keys():Iterator<String> return props.keys();
  /**
    Returns an Iterator over the values of `this` Properties.
    
    The order of values is undefined.
  **/
  public inline function values():Iterator<PropertyValue> return iterator();
  /**
    Returns an Iterator over the values of `this` Properties.
    
    The order of values is undefined.
  **/
  public inline function iterator():Iterator<PropertyValue> return props.iterator();
  
	/**
		Returns an Iterator over the keys and values of `this` Properties.

		The order of values is undefined.
	**/
  public inline function keyValueIterator(): KeyValueIterator<String, PropertyValue> return props.keyValueIterator();
  
  // public inline function typed<K, T:TypedProps<K>>():T return new TypedProps(this);
  
  /**
    Check whether the property with the given `name` exists or not.
    
    Note: Property may exists but be present as an empty string or `null`. If such properties should not be treated as present use `hasNotEmpty` method.
  **/
  public inline function has(name:String):Bool {
    return props.exists(name);
  }
  
  /**
    Check whether the property with the given `name` exists, not `null` and not an empty string.
  **/
  public inline function hasNotEmpty(name:String):Bool {
    var p = props.get(name);
    return p != null && p.value != null && p.value != "";
  }
  
  /**
    Get the value of the property with the given `name`. Does not perform type checks.
    @returns The property value or `def` if property does not exist.
  **/
  public inline function getRaw<T>(name:String, ?def:T):Null<T> {
    var p = props.get(name);
    if (p == null) return def;
    else return p.value;
  }
  /**
    Get the value of the property with the given `name`. Does not perform type checks.
    @returns The property value or `def` if property does not exist.
  **/
  public inline function get<T>(name:String, ?def:T):Null<T> return getRaw(name, def);
  
  /**
    Get the the type of a property with the given `name`.
    @returns The property type or `def` type if property does not exist.
  **/
  public inline function getType(name:String, def:PropertyType = TString):Null<PropertyType> {
    var p = props.get(name);
    if (p == null) return def;
    else return p.type;
  }
  
  /**
    Get the raw internal property value instance.
  **/
  public inline function getRawValue(name:String):Null<PropertyValue> {
    return props.get(name);
  }
  
  /**
    Checks whether property is inherited or not. Returns false if property does not exist.
  **/
  public inline function isInherited(name:String):Bool {
    var p = props.get(name);
    if (p == null) return false;
    return p.inherited;
  }
  
  /**
    Get the string value of the property with the given `name`.
    
    @returns Property value if its type is either `TString`, `TFile`, `TStringEmum` or `TStringFlags` and value is not an empty string or `null`. `def` otherwise.
  **/
  public function getString(name:String, def:String = ""):String {
    var p = props.get(name);
    if (p == null) return def;
    if (p.type == TStringFlags) {
      return p.value == null || (p.value:Array<String>).length == 0 ? def : (p.value:Array<String>).join(",");
    }
    if ((p.type != TString && p.type != TFile && p.type != TStringEnum) || p.value == "" || p.value == null) return def;
    else return p.value;
  }
  
  /**
    Get the string value of the property with the given `name`.
    
    Stricter version of `getString` that would return `def` only if property does not exist or on type mismatch.
    
    @returns Property value if its type is either `TString`, `TFile`, `TStringEnum` or `TStringFlags`. `def` otherwise.
  **/
  public function getStringStrict(name:String, def:String = ""):String {
    var p = props.get(name);
    if (p == null) return def;
    if (p.type == TStringFlags) return (p.value:Array<String>).join(",");
    if (p == null || (p.type != TString && p.type != TFile && p.type != TStringEnum)) return def;
    else return p.value;
  }
  
  /**
    Get the integer value of the property with the given `name`.
    
    If property type is `TFloat`, value would truncated via `Std.int`.
    
    @returns Property value if its type is either `TInt`, `TColor`, `TFloat`, `TIntEnum` or `TIntFlags`. `def` otherwise.
  **/
  public function getInt(name:String, def:Int = 0):Int {
    var p = props.get(name);
    if (p == null) return def;
    else if (p.type == TFloat) return Std.int(p.value);
    else if (p.type != TInt && p.type != TColor && p.type != TIntEnum && p.type != TIntFlags) return def;
    else return p.value;
  }
  
  /**
    Get the floating point value of the property with the given `name`.
    
    @returns Property value if its type is either `TFloat`, `TInt`, `TColor`, `TIntEnum` or `TIntFlags`. `def` otherwise.
  **/
  public function getFloat(name:String, def:Float = 0):Float {
    var p = props.get(name);
    if (p == null || (p.type != TFloat && p.type != TInt && p.type != TColor && p.type != TIntEnum && p.type != TIntFlags)) return def;
    else return p.value;
  }
  
  /**
    Get the floating point value of the property with the given `name`.
    
    If property is of type `TString` - attempts to convert it to `TFloat`.
    
    Compatibility helper for Tiled maps that didn't have property types.
    
    @returns Property value if its type is either `TFloat`, `TInt`, `TColor`, `TIntEnum` or `TIntFlags`. `def` otherwise.
  **/
  public function getSFloat(name:String, def:Float = 0):Float {
    var p = props.get(name);
    if (p == null) return def;
    if (p.type != TFloat && p.type != TInt && p.type != TColor && p.type != TIntEnum && p.type != TIntFlags) {
      if (p.type == TString) {
        var v = Std.parseFloat(p.value);
        if (!Math.isNaN(v)) {
          p.value = v;
          p.type = TFloat;
          return v;
        }
      }
      return def;
    }
    else return p.value;
  }
  
  /**
    Get the boolean value of the property with the given `name`.
    
    @returns Property value if its type is `TBool`. `def` otherwise.
  **/
  public function getBool(name:String, def:Bool = false):Bool {
    var p = props.get(name);
    if (p == null || p.type != TBool) return def;
    else return p.value;
  }
  
  /**
    Get the file path value of the property with the given `name`.
    
    @returns Property value if its type is either `TString` or `TFile` and value is not `null`, an empty string or `"."`. `def` otherwise.
  **/
  public function getFile(name:String, def:String = "."):String {
    var p = props.get(name);
    if (p == null || (p.type != TString && p.type != TFile) || p.value == null || p.value == "" || p.value == ".") return def;
    else return p.value;
  }
  
  /**
    Get the file path value of the property with the given `name`.
    
    Stricter version of `getFile` that would return `def` only if property does not exist or on type mismatch.
    
    @returns Property value if its type is either `TString` or `TFile`. `def` otherwise.
  **/
  public function getFileStrict(name:String, def:String = "."):String {
    var p = props.get(name);
    if (p == null || (p.type != TString && p.type != TFile) || p.value == "" || p.value == ".") return def;
    else return p.value;
  }
  
  /**
    Get the color integer value of the property with the given `name`.
    
    If property type is `TFloat`, value would truncated via `Std.int`.
    
    @returns Property value if its type is either `TInt`, `TColor` or `TFloat`. `def` otherwise.
  **/
  public inline function getColor(name:String, def:Int = 0):Int return getInt(name, def);
  
  /**
    Get the object reference from the property with the given `name`.
    
    @returns The `TmxObject` instance if property type is `TObject`, not `null` and not an invalid reference. `def` otherwise.
  **/
  public function getObject(name:String, def:TmxObject = null):TmxObject {
    var p = props.get(name);
    if (p == null || p.type != TObject || p.value == null) return def;
    if (Std.isOfType(p.value, TmxObject)) return p.value;
    else return def;
  }
  /**
    Get the object reference ID from the property with the given `name`.
    
    @returns The reference ID if property type is `TObject` and not `null`. `def` otherwise.
  **/
  public function getObjectId(name:String, def:Int = -1):Int {
    var p = props.get(name);
    if (p == null || p.type != TObject || p.value == null) return def;
    if (Std.isOfType(p.value, TmxObject)) return (p.value:TmxObject).id;
    else return p.value;
  }
  
  /**
    Checks whether the object reference in the property with the given `name` is a valid object reference.
    
    @returns `true` if referenced object exists, `false` otherwise.
  **/
  public function isInvalidObjectRef(name:String):Bool {
    var p = props.get(name);
    return p != null && p.type == TObject && p.value != null && Std.isOfType(p.value, TmxObject);
  }
  
  /**
    Get the string enum value of the property with the given `name`.
    
    @returns Property value if it's type is `TStringEnum` and it's not an empty string or `null`. `def` otherwise.
  **/
  public function getStringEnum(name: String, ?def: String): String {
    var p = props.get(name);
    if (p == null || p.type != TStringEnum || p.value == "" || p.value == null) return def;
    else return p.value;
  }
  
  /**
    Get an int enum value of the property with the given `name`.
    
    @returns Property value if it's type is `TIntEnum` and it's not `null`. `def` otherwise.
  **/
  public function getIntEnum(name: String, def: Int = 0): Int {
    var p = props.get(name);
    if (p == null || p.type != TIntEnum || p.value == null) return def;
    else return p.value;
  }
  
  /**
    Get the string enum flags value of the property with the given `name`.
    
    @returns Property value if it's type is `TStringFlags` and it's not `null`. `def` otherwise.
  **/
  public function getStringFlags(name: String, ?def: Array<String>): Array<String> {
    var p = props.get(name);
    if (p == null || p.type != TStringFlags || p.value == null) return def;
    else return p.value;
  }
  
  /**
    Get an int enum flags value of the property with the given `name`.
    
    @returns Property value if it's type is `TIntFlags` and it's not `null`. `def` otherwise.
  **/
  public function getIntFlags<T: EnumValue>(name: String, def: haxe.EnumFlags<T> = cast 0): haxe.EnumFlags<T> {
    var p = props.get(name);
    if (p == null || p.type == TIntFlags || p.value == null) return def;
    else return p.value;
  }
  
  /**
    Inherits properties that are not yet present from a parent properties.
    
    @param parent The parent Properties instance to inherit properties from.
    @param inheritInherited If set, parent properties that are marked as inherited are also inherited.
  **/
  public function inherit(parent:Properties, inheritInherited:Bool = true) {
    if (parent == null) return;
    for (name => prop in parent.props) {
      if (inheritInherited || !prop.inherited) {
        var current = props[name];
        if (current == null) props.set(name, { type: prop.type, value: prop.value, inherited: true, finalized: prop.finalized });
      }
    }
  }
  
  // Load
  /**
    Load the `<properties>` XML element.
  **/
  public function loadXML(x:Xml, loader: Tiled) {
    for (el in x) {
      if (el.nodeType == Element) {
        addProp(el.get('name'), el.get('type'), el.exists('value') ? el.get('value') : el, el.get('propertyType'), loader);
      }
    }
  }
  
  /**
    Load the `<objecttype>` XML element.
  **/
  public function loadObjectTypes(x:Xml, loader: Tiled) {
    // VERIFY: Can data be stored in CDATA chunk?
    for (el in x) if (el.nodeType == Element && (el.exists('default')))
      addProp(el.get('name'), el.get('type'), el.get('default'), el.get('propertyType'), loader);
  }
  
  /**
    Load the Json property list.
  **/
  public function loadJson(props:Array<TmxJsonProperty>, loader: Tiled) {
    for (p in props) {
      addProp(p.name, p.type, p.value, p.propertyType, loader);
    }
  }
  
  inline function _addProp(name:String, t:PropertyType, v:Any) props.set(name, { type: t, value: v, inherited: false, finalized: false });
  
  inline function addStringProp(name: String, val: String, propertyType: String, loader: Tiled) {
    if (propertyType != null) {
      var etype = loader.getEnumType(propertyType);
      // TODO: Parse enums for dynamic mode?
      if (etype == null || !etype.isFlags) _addProp(name, TStringEnum, val);
      else _addProp(name, TStringFlags, val.split(","));
    } else {
      _addProp(name, TString, val);
    }
  }
  
  inline function addIntProp(name: String, val: Int, propertyType: String, loader: Tiled) {
    if (propertyType != null) {
      // TODO: Parse enums for dynamic mode?
      var etype = loader.getEnumType(propertyType);
      if (etype == null || !etype.isFlags) _addProp(name, TIntEnum, val);
      else _addProp(name, TIntFlags, val);
    } else {
      _addProp(name, TInt, val);
    }
  }
  
  inline function addFloatProp(name: String, val: Float, propertyType: String, loader: Tiled) _addProp(name, TFloat, val);
  inline function addBoolProp(name: String, val: Bool, propertyType: String, loader: Tiled) _addProp(name, TBool, val);
  inline function addColorProp(name: String, val: String, propertyType: String, loader: Tiled) {
    if (val.charCodeAt(0) == '#'.code) val = val.substr(1);
    _addProp(name, TColor, val.length == 6 ? (0xff000000 | Std.parseInt('0x' + val)) : Std.parseInt('0x' + val));
  }
  inline function addFileProp(name: String, val: String, propertyType: String, loader: Tiled) _addProp(name, TFile, val);
  inline function addObjectProp(name: String, val: Int, propertyType: String, loader: Tiled) _addProp(name, TObject, val);
  inline function addClassProp(name: String, val: Dynamic, propertyType: String, loader: Tiled) {
    var props = new Properties();
    var source = loader.objectTypes[propertyType];
    if (val != null) {
      if (val is Xml) {
        var xval: Xml = val;
        for (node in xval) {
          if (node.nodeType == Element && node.nodeName == "properties") {
            props.loadXML(node, loader);
            break;
          }
        }
        // For JSON we first inherit default values, then merge, for XML we do it in reverse.
        if (source != null) props.inherit(source.properties);
      } else {
        if (source != null) props.inherit(source.properties);
        // Merge values that override the inherited properties.
        // VERIFY: Check if it works
        function mergeValues(props: Properties, val: Xml) {
          var fields = Reflect.fields(val);
          for (f in fields) {
            var prop = props.props[f];
            if (prop == null) continue;
            var fieldVal: Dynamic = Reflect.field(val, f);
            switch (prop.type) {
              case TStringFlags: prop.value = (fieldVal:Array<String>).copy();
              case TColor: prop.value = (fieldVal:String).parseColor();
              case TClass: if (fieldVal != null) mergeValues(prop.value, fieldVal);
              default: prop.value = fieldVal;
            }
            prop.inherited = false;
          }
        }
        mergeValues(props, val);
      }
    }
    
    _addProp(name, TClass, props);
  }
  
  function addProp(name:String, type:TiledPropertyMemberKind, val:Dynamic, propertyType: String, loader: Tiled) {
    switch (type) {
      case 'string': addStringProp(name, val, propertyType, loader);
      case 'int': addIntProp(name, Std.parseInt(val), propertyType, loader);
      case 'float': addFloatProp(name, Std.parseFloat(val), propertyType, loader);
      case 'bool': addBoolProp(name, val == 'true', propertyType, loader);
      case 'color': addColorProp(name, val, propertyType, loader);
      case 'file': addFileProp(name, val, propertyType, loader);
      case 'object': addObjectProp(name, Std.parseInt(val), propertyType, loader);// add(TObject, Std.parseInt(val));
      case 'class': addClassProp(name, val, propertyType, loader);
      default: _addProp(name, TString, Std.string(val)); // TUnknown
    }
  }
  
  /**
    Finalizes the properties instance.
    Equivalent to calling `fillReferences` and `deLocalize`.
  **/
  public inline function finalize(objs: Array<TmxObject>, path: String, loader: Tiled) {
    final delocalize = loader.deLocalizeFileProperties;
    for (p in props) {
      if (p.type == TObject) {
        _fillReferences(p, objs);
      } else if (p.type == TClass) {
        (p.value:Properties).finalize(objs, path, loader);
      } else if (p.type == TFile && delocalize) {
        _deLocalize(p, path);
      }
    }
  }
  
  inline function _fillReferences(p: PropertyValue, objs: Array<TmxObject>) {
    if (!p.finalized && p.value != null) {
      final ival: Int = p.value;
      if (objs[ival] != null) p.value = objs[ival];
      p.finalized = true;
    }
  }
  
  /**
    Replace object IDs with their repsective TmxObject instances.
  **/
  public function fillReferences(objs:Array<TmxObject>) {
    for (p in props) {
      if (p.type == TObject) {
        _fillReferences(p, objs);
      } else if (p.type == TClass) {
        (p.value:Properties).fillReferences(objs);
      }
    }
  }
  
  inline function _deLocalize(p: PropertyValue, path: String) {
    if (!p.finalized && p.value != "") {
      p.value = (p.value:String).normalizePath(path);
      p.finalized = true;
    }
  }
  
  /**
    Turn all TFile properties to a path from resource root rather than local to the file properties are stored in.
    
    Does not affect inherited fields.
  **/
  public function deLocalize(path:String) {
    for (p in props) {
      // TODO: Better indicator that TFile is already localized.
      if (p.type == TFile) {
        _deLocalize(p, path);
      } else if (p.type == TClass) {
        (p.value:Properties).deLocalize(path);
      }
    }
  }
  
}

/**
  The raw property value.
**/
@:structInit
class PropertyValue {
  /**
    The stored property value type.
  **/
  public var type:PropertyType;
  /**
    The current value of the property.
  **/
  public var value:Any;
  /**
    Whether this property was inherited from another instance of Properties.
  **/
  public var inherited:Bool;
  /**
    For `TFile` properties: Indicates that file is already de-localized and its value is asset-root relative.
    For `TObject` properties: Indicates that object was already filled.
  **/
  public var finalized: Bool;
  
  /**
    Returns a string representation of the property.
  **/
  public function toString() {
    return '{ ${inherited ? '[i] ':''}$type -> $value }';
  }
}

/**
  The property value type.
**/
enum PropertyType {
  /**
    The `String` type.
  **/
  TString;
  /**
    The `Int` type.
  **/
  TInt;
  /**
    The `Float` type.
  **/
  TFloat;
  /**
    The `Bool` type. Stored as either `1`/`0` or `true`/`false`.
  **/
  TBool;
  /**
    The `Int` type. Stored as a hexadecimal value with `#RRGGBB` or `#AARRGGBB` format.
  **/
  TColor;
  /**
    The `String` type. Stored as relative to the file it's being stored at, but unwrapped into a full asset path on parsing.
  **/
  TFile;
  /**
    The `TmxObject` reference or an `Int` when reference is invalid.
  **/
  TObject;
  /**
    A subclass property.
  **/
  TClass;
  
  /**
    An integer enum.
  **/
  TIntEnum;
  /**
    A string enum.
  **/
  TStringEnum;
  /**
    An array of string enums.
  **/
  TStringFlags;
  /**
    An integer enum bitmask.
  **/
  TIntFlags;
}