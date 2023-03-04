package tiled._internal;

import tiled.types.JsonDef;
#if macro
import haxe.macro.Compiler;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.Context;
using haxe.macro.Tools;
using StringTools;

typedef UseAsType = {
  var name: String;
  var as: TiledClassUseAs;
  var init: (name: String)->Expr;
  var validate: ComplexType;
}

#end

class ProjectMacro {
  #if macro
  
  @:persistent
  public static var types: Array<TiledPropertyType> = [];
  
  @:persistent
  static var useAsTypes: Map<String, UseAsType> = [
    "initObject" => { name: "initObject", as: UAObject, init: (name: String) -> macro tiled.project.TiledProject.registerObjectClass($v{name}, initObject), validate: macro :tiled.types.TmxObject },
    "initTile" => { name: "initTile", as: UATile, init: (name: String) -> macro tiled.project.TiledProject.registerTileClass($v{name}, initTile), validate: macro :tiled.types.TmxTileset.TmxTile },
    "initLayer" => { name: "initLayer", as: UALayer, init: (name: String) -> macro tiled.project.TiledProject.registerLayerClass($v{name}, initLayer), validate: macro :tiled.types.TmxLayer },
    "initTileset" => { name: "initTileset", as: UATileset, init: (name: String) -> macro tiled.project.TiledProject.registerTilesetClass($v{name}, initTileset), validate: macro :tiled.types.TmxTileset },
    "initMap" => { name: "initMap", as: UAMap, init: (name: String) -> macro tiled.project.TiledProject.registerMapClass($v{name}, initMap), validate: macro :tiled.types.TmxMap },
    "initProperty" => { name: "initProperty", as: UAProperty, init: (name: String) -> macro tiled.project.TiledProject.registerPropertyClass($v{name}, initProperty), validate: macro :tiled.project.TiledClass },
    #if tiled_metadata
    "initWangColor" => { name: "initWangColor", as: UAWangcolor, init: (name: String) -> macro tiled.project.TiledProject.registerWangColorClass($v{name}, initWangColor), validate: macro :tiled.types.TmxTileset.WangColor },
    "initWangSet" => { name: "initWangSet", as: UAWangset, init: (name: String) -> macro tiled.project.TiledProject.registerWangSetClass($v{name}, initWangSet), validate: macro :tiled.types.TmxTileset.WangSet },
    #end
  ];
  
  static inline function extractTname(meta: MetadataEntry, def: String) {
    return if (meta.params == null || meta.params.length == 0) {
      Context.warning("Invalid @:tname parameter! Expected a string!", meta.pos);
      def;
    } else try {
      switch (meta.params[0].expr) {
        case EConst(CIdent(s) | CString(s)):
          s;
        default:
          Context.warning("Invalid @:tname parameter! Expceted a string!", meta.pos);
          def;
      }
    } catch (_) {
      def;
    }
  }
  
  static function nameOf(t: BaseType) {
    if (t.meta.has(":tname")) {
      return extractTname(t.meta.extract(":tname")[0], t.name);
    }
    return t.name;
  }
  
  static function ctToExpr(ct: ComplexType, pos: Position) {
    return switch (ct) {
      case TPath(p):
        var e: Expr = { expr: EConst(CIdent(p.pack.length > 0 ? p.pack[0] : p.name)), pos: pos };
        var i = 1;
        while (i < p.pack.length) {
          e = { expr: EField(e, p.pack[i++], Normal), pos: pos };
        }
        if (p.sub != null) e = { expr: EField(e, p.sub, Normal), pos: pos };
        e;
      default: throw "assert";
    }
  }
  
  static function compareCT(a: ComplexType, b: ComplexType) {
    // Because imported complex type != non-imported
    // a = a.toType().toComplexType();
    b = b.toType().toComplexType();
    switch (a) {
      case TPath(p):
        switch (b) {
          case TPath(p2):
            if (p.pack.length != p2.pack.length) return false;
            for (i in 0...p.pack.length) {
              if (p.pack[i] != p2.pack[i]) return false;
            }
            if (p.params != null && p2.params != null) {
              if (p.params.length > 0) Context.warning("Can't compare complex types with params!", Context.currentPos());
            } else if (p.params != null || p2.params != null) return false;
            return p.name == p2.name && p.sub == p2.sub;
          default: 
            return false;
        }
      default: 
        return false;
    }
  }
  
  static function buildEnum(e: EnumType, flags: Bool, isString: Bool): String {
    var name = nameOf(e);
    if (isString) name += flags ? "_fs" : "_s";
    else if (flags) name += "_f";
    for (t in types) if (t.name == name) return name;
    
    var et: TiledEnumDescriptor = {
      id: types.length+1,
      name: name,
      type: TiledPropertyKind.KEnum,
      storageType: isString ? TiledEnumStorageKind.KString : TiledEnumStorageKind.KInt,
      values: e.names.copy(),
      valuesAsFlags: flags
    };
    types.push(cast et);
    return name;
  }
  
  public static function buildClass() {
    var fields = Context.getBuildFields();
    var props: Array<TmxJsonProperty> = [];
    final display = Context.defined("display");
    final projectMode = Context.definedValue("tiled-props") == "project";
    
    var color: String = "#ffffffff";
    var localClass = Context.getLocalClass().get();
    var classMeta = localClass.meta;
    var pos = localClass.pos;
    var name = localClass.name;
    
    var useAs: Array<UseAsType> = [];
    var useAsHints: Array<{ t: UseAsType, pos: Position, field: Field }> = [];
    var fallbackUseAs: UseAsType = null;
    var simpleConstructor: Bool = false;
    
    var thisType = switch(Context.getLocalType().toComplexType()) { 
      case TPath(p): p;
      default: throw "assert";
    }
    
    for (meta in classMeta.get()) {
      switch (meta.name) {
        case ":tname":
          name = extractTname(meta, name);
        case ":tcolor":
          if (meta.params.length < 1) Context.warning("Invalid @:tcolor meta, expected argument with type color (string hash notation or int)!", meta.pos);
          else {
            switch (meta.params[0].expr) {
              case EConst(CString(s, _)) if (s.charCodeAt(0) == "#".code):
                if (s.length == 4) s = "#F" + s.substr(1); // #RGB->#ARGB
                if (s.length == 5) {
                  var a = s.charAt(1);
                  var r = s.charAt(2);
                  var g = s.charAt(3);
                  var b = s.charAt(4);
                  color = "#" + a + a + r + r + g + g + b + b;
                } else {
                  if (s.length == 7) s = "#FF" + s.substr(1); // #RRGGBB -> #AARRGGBB
                  color = s;
                }
              case EConst(CInt(_.toLowerCase() => h)) if (h.startsWith("0x")):
                if (h.length <= 8) { // No alpha
                  color = "#ff" + h.substr(2).lpad("0", 6);
                } else {
                  color = "#" + h.substr(2);
                }
              case EConst(CInt(Std.parseInt(_) => i)):
                if ((i & 0xff000000) == 0) i &= 0xff000000;
                color = "#" + i.hex(8);
              default: Context.warning("Invalid @:tcolor meta, expected argument with type color (string hash notation or int)!", meta.pos);
            }
          }
        case ":useAs":
          if (meta.params == null) {
            Context.warning("@:useAs meta does not have parameters!", meta.pos);
          } else for (e in meta.params) {
            switch (e.expr) {
              case EConst(CIdent(s) | CString(s)):
                var initGen = useAsTypes[switch (s.toLowerCase()) {
                  case "object": "initObject";
                  case "tile": "initTile";
                  case "layer": "initLayer";
                  case "tileset": "initTileset";
                  case "map": "initMap";
                  case "property": "initProperty";
                  case "wangcolor": "initWangColor";
                  case "wangset": "initWangSet";
                  default: "";
                }];
                if (initGen == null) {
                  Context.warning("Unknown @:useAs type! Expected: object, tile, layer, tileset, map, property, wangcolor or wangset, got: " + s, e.pos);
                } else {
                  var hint = {
                    t: initGen,
                    pos: e.pos,
                    field: null
                  };
                  useAsHints.push(hint);
                  if (projectMode) hint.field = {
                    name: initGen.name,
                    pos: e.pos,
                    access: [AStatic],
                    doc: "Auto-generated from @:useAs meta",
                    kind: FFun({
                      args: [{ name: "arg", type: initGen.validate }],
                      expr: macro {
                        return new $thisType();
                      }
                    })
                  };
                }
                
              default: Context.warning("Invalid @:useAs meta parameter! Expected string/ident with applied type!", e.pos);
            }
          }
        case ":noBuild":
          return null;
      }
    }
    
    Compiler.keep(Context.getLocalClass().toString());
    
    var loadProps: Array<Case> = [];
    var finalize: Array<Expr> = [];
    var finalizeExtra: Array<Expr> = [];
    var loadUnknown: Expr = null; // An if...else chain
    var transfer: Array<Expr> = []; // Transfer from Tile to Object.
    
    if (Context.defined("debug") && !Context.defined("tiled_disable_debug_warnings")) {
      loadUnknown = macro trace($v{name} + ": Was given uknown property " + prop + " = " + v);
    }
    
    var fi = 0;
    while (fi < fields.length) {
      var f = fields[fi++];
      if (f.meta == null) continue;
      
      var isTvar = false;
      var tvarHint = null;
      var tname: String = f.name;
      var isOptional = false;
      var arrayFill = 1;
      
      for (meta in f.meta) {
        switch (meta.name) {
          case ":tvar":
            isTvar = true;
            if (meta.params != null) for (param in meta.params) {
              switch (param.expr) {
                case EConst(CIdent(s) | CString(s)):
                  if (s == "optional") isOptional = true;
                  else tvarHint = s;
                default:
                  Context.warning("Invalid @:tvar parameter! Expected CIdent or CString with the property type hint or `optional`!", meta.pos);
              }
            }
          case ":tname":
            if (meta.params != null && meta.params.length > 0) {
              switch (meta.params[0].expr) {
                case EConst(CIdent(s) | CString(s)):
                  tname = s;
                default:
                  Context.warning("Invalid @:tname parameter! Expected CIdent or CString with the property name to use!", meta.pos);
              }
            } else {
              Context.warning("Invalid @:tname meta! Expected to receive a parameter with the property name to use!", meta.pos);
            }
          case ":tfill":
            if (meta.params != null &&meta.params.length > 0) {
              switch (meta.params[0].expr) {
                case EConst(CInt(i)):
                  arrayFill = Std.parseInt(i);
                default:
                  Context.warning("Invalid @:tfill parameter! Expected CInt with array prefill count!", meta.pos);
              }
            } else {
              Context.warning("Invalid @:tfill meta! Expected to receive a parameter with array prefill count!", meta.pos);
            }
        }
      }
      
      var ft: ComplexType;
      var defVal: Expr = null;
      switch (f.kind) {
        case FVar(_t, e): ft = _t; defVal = e;
        case FFun(fun): 
          var type = useAsTypes[f.name];
          if (type != null) {
            if (!f.access.contains(AStatic)) Context.fatalError("initX should be a static method!", f.pos);
            if (fun.args.length != 1) Context.fatalError("Incorrect amount of arguments on initX! Expected 1!", f.pos);
            if (!compareCT(type.validate, fun.args[0].type)) Context.fatalError("Incorrect argument type on initX! Expected " + type.validate.toString() + ", got: " + fun.args[0].type.toString(), f.pos);
            useAs.push(type);
          } else switch (f.name) {
            case "new":
              if (fun.args.length == 1) {
                var ctype = fun.args[0].type;
                for (t in useAsTypes) {
                  if (compareCT(t.validate, ctype)) {
                    fallbackUseAs = t;
                    break;
                  }
                }
              }
              // TODO: Allow multiple constructor fallbacks if all types are optional
              simpleConstructor = (fun.args.length == 0 || Lambda.find(fun.args, (v) -> !v.opt) == null);
            case "finalize":
              // In case different names used: Assign variables under new names.
              if (fun.args[0].name != "objects" && fun.args[0].name != "_") {
                var rename = fun.args[0].name;
                finalizeExtra.push(macro var $rename = objects);
              }
              if (fun.args[1].name != "path" && fun.args[1].name != "_") {
                var rename = fun.args[1].name;
                finalizeExtra.push(macro var $rename = path);
              }
              if (fun.args[2].name != "loader" && fun.args[2].name != "_") {
                var rename = fun.args[1].name;
                finalizeExtra.push(macro var $rename = loader);
              }
              finalizeExtra.push(fun.expr);
              // Make sure to remove the original method.
              fields.splice(fi-1, 1);
              fi--;
            case "loadProperties":
              Context.fatalError("Implementation of loadProperties is not allowed!", f.pos);
            case "transferToObject" | "transferToTileset":
              // TODO: Allow custom code
              Context.fatalError("Implementation of transfer methods is not allowed!", f.pos);
          }
        case FProp(get, set, _t, e):
          if (isTvar && set == "never" || get == "never") {
            isTvar = false;
            Context.warning("Cannot expose a property with a `never` read/write rule!", f.pos);
          }
          ft = _t; defVal = e;
      }
      
      if (!isTvar) continue;
      
      var isArray = switch (ft.toType()) {
        case TInst(_.toString() => a, [at]) if (a == "Array"):
          ft = at.toComplexType();
          true;
        default: false;
      }
      
      var propKind: TiledPropertyMemberKind = null;
      var propType: String = null;
      var propDef: Any = null;
      var load: Expr = null;
      var postLoad: Expr = null;
      var fname = f.name;
      
      function makeArrayLoad() {
        loadUnknown = macro {
          if (StringTools.startsWith(prop, $v{fname}) && (prop.charCodeAt($v{fname.length}) == ".".code || prop.charCodeAt($v{fname.length}) == "[".code)) {
            $load;
          } else $loadUnknown;
        };
      }
      function makeLoad(convert: Expr = null) {
        if (convert == null) convert = macro v;
        if (isArray) {
          load = macro {
            if (this.$fname == null) this.$fname = [];
            this.$fname.push($convert);
          }
          makeArrayLoad();
          transfer.push(macro if (this.$fname != null) copy.$fname = this.$fname.copy()); // TODO: Make copy optional
        } else {
          load = macro this.$fname = $convert;
          transfer.push(macro copy.$fname = this.$fname);
        }
      }
      
      var resolved = true;
      switch (ft.toString()) {
        case "String":
          propKind = TiledPropertyMemberKind.KString; propDef = "";
          if (tvarHint == "file") propKind = TiledPropertyMemberKind.KFile;
          else if (tvarHint == "color") propKind = TiledPropertyMemberKind.KColor;
          else if (tvarHint != null && tvarHint != "string") Context.warning("Invalid suggested type for String! Expected string, file or color, got: " + tvarHint, f.pos);
          if (tvarHint == "file") makeLoad(macro loader.deLocalizeFileProperties ? tiled.types.XmlTools.normalizePath(v, path) : v);
          else makeLoad();
        case "Int":
          propKind = TiledPropertyMemberKind.KInt; propDef = 0;
          if (tvarHint == "color") propKind = TiledPropertyMemberKind.KColor;
          else if (tvarHint == "object") propKind = TiledPropertyMemberKind.KObject;
          else if (tvarHint != null && tvarHint != "int") Context.warning("Invalid suggested type for Int! Expected int, color or object, got: " + tvarHint, f.pos);
          if (propKind == TiledPropertyMemberKind.KColor) {
            makeLoad(macro Std.parseInt("0x" + (v:String).substr(1))); // Cut out #
          } else {
            makeLoad();
          }
        case "Float":
          propKind = TiledPropertyMemberKind.KFloat; propDef = 0.0;
          if (tvarHint == "int") propKind = TiledPropertyMemberKind.KInt;
          else if (tvarHint != null && tvarHint != "float") Context.warning("Invalid suggested type for Float! Expected int or float, got: " + tvarHint, f.pos);
          makeLoad();
        case "Bool":
          propKind = TiledPropertyMemberKind.KBool; propDef = false;
          if (tvarHint != null && tvarHint != "bool") Context.warning("Invalid suggested type for Bool! Expected bool, got: " + tvarHint, f.pos);
          makeLoad();
        case "TmxObject" | "tiled.types.TmxObject":
          propKind = TiledPropertyMemberKind.KObject;
          if (tvarHint != null && tvarHint != "object") Context.warning("Invalid suggested type for TmxObject! Expected object, got: " + tvarHint, f.pos);
          if (projectMode) {
            var idName = fname + "ID";
            fields.push({
              name: idName,
              pos: f.pos,
              meta: [{ name: ":noCompletion", pos: f.pos }],
              kind: isArray ? FVar(macro :Array<Int>, macro []) : FVar(macro :Int, macro 0),
              access: [APrivate],
              doc: "Auto-generated for Tiled usage."
            });
            if (isArray) {
              load = macro this.$idName.push(v);
              makeArrayLoad();
              postLoad = macro if (this.$idName.length > 0) {
                if (this.$fname == null) this.$fname = [];
                for (id in this.$idName) {
                  this.$fname.push(objects[id]);
                }
              }
              transfer.push(macro copy.$idName = this.$idName.copy());
              transfer.push(macro if (this.$fname != null) copy.$fname = this.$fname.copy());
            } else {
              load = macro this.$idName = v;
              postLoad = macro this.$fname = objects[this.$idName];
              transfer.push(macro copy.$idName = this.$idName);
              transfer.push(macro copy.$fname = this.$fname);
            }
          }
        default: resolved = false;
      }
      // TODO: Default enums
      if (!resolved) {
        switch (ft.toType()) {
          case TInst(_.get() => t, [TEnum(_.get() => e, _)]) if (t.name == "Array"):
            // Enum array
            propKind = tvarHint == "int" ? TiledPropertyMemberKind.KInt : TiledPropertyMemberKind.KString;
            propType = buildEnum(e, true, tvarHint != "int");
            resolved = true;
            var tn = ctToExpr(ft, f.pos);
            if (propKind == TiledPropertyMemberKind.KInt) {
              var max = e.names.length;
              makeLoad(macro {
                var arr = [];
                var idx = 0;
                while (idx < $v{max}) {
                  if ((v & (1<<idx)) != 0) arr.push($tn.createByIndex(idx));
                  idx++;
                }
                arr;
              });
              // FIXME: transfer does a shallow copy
            } else {
              makeLoad(macro [for (name in v.split(",")) $tn.createByName(name)]);
            }
          case TEnum(_.get() => t, _):
            propKind = tvarHint == "string" ? TiledPropertyMemberKind.KString : TiledPropertyMemberKind.KInt;
            propType = buildEnum(t, isArray, tvarHint == "string");
            resolved = true;
            var tn = ctToExpr(ft, f.pos);
            if (isArray) {
              if (propKind == TiledPropertyMemberKind.KInt) {
                var max = t.names.length;
                load = macro {
                  this.$fname = [];
                  var idx = 0;
                  var iv:Int = v;
                  while (idx < $v{max}) {
                    if ((iv & (1<<idx)) != 0) this.$fname.push($tn.createByIndex(idx));
                    idx++;
                  }
                };
              } else {
                load = macro {
                  this.$fname = [for (name in (v:String).split(",")) $tn.createByName(name)];
                };
              }
              transfer.push(macro if (this.$fname != null) copy.$fname = this.$fname.copy());
              if (defVal != null) {
                Context.warning("Default values for enum flags are not supported yet!", defVal.pos);
              }
            } else {
              if (propKind == TiledPropertyMemberKind.KString) {
                load = macro this.$fname = $tn.createByName(v);
                if (defVal != null) switch (defVal.expr) {
                  case EConst(CIdent(s)): propDef = s;
                  case EField(e, field, kind) if (Context.typeExpr(e).t.unify(ft.toType())):
                    propDef = field;
                  default:
                }
              } else {
                load = macro this.$fname = $tn.createByIndex(v);
                if (defVal != null) switch (defVal.expr) {
                  case EConst(CIdent(s)): propDef = t.names.indexOf(s);
                  case EField(e, field, kind) if (Context.typeExpr(e).t.unify(ft.toType())):
                    propDef = t.names.indexOf(field);
                  default:
                }
              }
              transfer.push(macro copy.$fname = this.$fname);
            }
          case TAbstract(_.get() => t, [TEnum(_.get() => e, _)]) if (t.name == "EnumFlags"):
            propKind = tvarHint == "string" ? TiledPropertyMemberKind.KString : TiledPropertyMemberKind.KInt;
            propType = buildEnum(e, true, tvarHint == "string");
            resolved = true;
            var tn = ctToExpr((ft.toType().getParameters()[1][0]:Type).toComplexType(), f.pos);
            if (propKind == TiledPropertyMemberKind.KInt) {
              makeLoad(macro haxe.EnumFlags.ofInt(v));
            } else {
              // Not very optimal, but why would you store string enum in EnumFlags anyway.
              makeLoad(macro {
                var f = haxe.EnumFlags.ofInt(0);
                for (name in (v:String).split(",")) f.set($tn.createByName(name));
                f;
              });
            }
          case TInst(_.get() => t, _):
            for (i in t.interfaces) if (i.t.get().name == "TiledClass") {
              propKind = TiledPropertyMemberKind.KClass;
              propType = nameOf(t);
              resolved = true;
              var tp = ctToExpr(ft, f.pos);
              if (isArray) {
                load = macro {
                  if (this.$fname == null) this.$fname = [];
                  var inst = @:privateAccess $tp.initProperty(this);
                  inst.loadProperties(v, loader, path);
                  this.$fname.push(inst);
                }
                makeArrayLoad();
                transfer.push(macro if (this.$fname != null) {
                  copy.$fname = [];
                  for (cl in this.$fname) {
                    var inst = @:privateAccess $tp.initProperty(this);
                    cl.transferTo(inst);
                    copy.$fname.push(inst);
                  }
                });
              } else {
                load = macro {
                  this.$fname = @:privateAccess $tp.initProperty(this);
                  this.$fname.loadProperties(v, loader, path);
                };
                transfer.push(macro copy.$fname = @:privateAccess $tp.initProperty(copy));
                transfer.push(macro this.$fname.transferTo(copy.$fname));
              }
              break;
            }
          default:
        }
        if (!resolved) Context.fatalError("Unsupported @:tvar variable type " + ft + "!", f.pos);
      }
      
      if (propKind != null) {
        // TODO: Default value for enums
        // FIXME: Array :tname does not work for array subs
        function extractDefVal(expr: Expr): Dynamic {
          return try {
            switch (expr.expr) {
              case EArrayDecl(values):
                [for (e in values) extractDefVal(e)];
              case EConst(CInt(s)) if (propKind == KColor):
                "#"+Std.parseInt(s).hex(8);
              default:
                expr.getValue();
            }
          } catch (e: Dynamic) { propDef; }
        }
        var val = extractDefVal(defVal);
        function makeProp(name: String) {
          var prop: TmxJsonProperty = {
            name: name,
            type: propKind,
          }
          if (val != null && !(val is Array)) prop.value = val;
          if (propType != null) prop.propertyType = propType;
          props.push(prop);
        }
        if (!isOptional) {
          if (!isArray || arrayFill == 1) makeProp(tname);
          else {
            for (i in 0...arrayFill) makeProp(tname + "[" + i + "]");
          }
        }
        if (load != null) {
          var c: Case = {
            values: [macro $v{tname}],
            expr: load
          };
          loadProps.push(c);
        }
        if (postLoad != null) finalize.push(postLoad);
      }
    }
    
    if (useAs.length == 0) {
      if (fallbackUseAs != null) {
        useAs.push(fallbackUseAs);
        if (projectMode) fields.push({
          name: fallbackUseAs.name,
          pos: pos,
          access: [AStatic],
          doc: "Auto-generated from constructor.",
          kind: FFun({
            args: [{ name: "arg", type: fallbackUseAs.validate }],
            expr: macro {
              return new $thisType(arg);
            }
          })
        });
      }
    }
    if (useAsHints.length > 0) {
      if (!simpleConstructor && projectMode) Context.fatalError("@:useAs meta requires constructor to either take no arguments or all arguments being optional!", classMeta.extract(":useAs")[0].pos);
      for (hint in useAsHints) {
        if (hint.t == fallbackUseAs) {
          Context.warning("Attempting to apply @:useAs compatibility that is already declared via constructor!", hint.pos);
        } else {
          useAs.push(hint.t);
          if (projectMode) fields.push(hint.field);
        }
      }
    }
    if (useAs.length == 0) Context.warning("Class does not declare any Tiled types it is compatible with!", pos);
    // TODO: If constructor takes no arguments - automatically generate all useAs
    
    if (projectMode) {
      
      fields.push({
        name: "_registered",
        pos: pos,
        meta: [{ name: ":noCompletion", pos: pos }, { name: ":keep", pos: pos }],
        access: [APublic, AStatic],
        kind: FVar(macro :Bool, macro {
          $b{useAs.map(u -> u.init(name))};
          true;
        }),
        doc: "Auto-generated for Tiled usage."
      });
      
      // TODO: Custom code in load/finalize
      var loadSwitch: Expr = if (loadProps.length > 0) ({ expr: ESwitch(macro prop, loadProps, loadUnknown), pos: pos }) else macro {};
      fields.push({
        name: "loadProperties",
        access: [APublic],
        kind: FFun({
          args: [
            { name: "properties", type: macro :tiled.project.PropertyIterator },
            { name: "loader", type: macro :tiled.Tiled },
            { name: "path", type: macro :String },
          ],
          expr: macro {
            for (prop => v in properties) {
              $loadSwitch;
            }
            //$loadExtra
          },
          ret: macro :Void,
        }),
        pos: pos,
        doc: "Auto-generated for Tiled usage",
      });
      fields.push({
        name: "finalize",
        access: [APublic],
        kind: FFun({
          args: [{ name: "objects", type: macro :Array<tiled.types.TmxObject> }, { name: "path", type: macro :String }, { name: "loader", type: macro :tiled.Tiled }],
          expr: macro { $b{finalize}; $b{finalizeExtra}; },
          ret: macro :Void,
        }),
        pos: pos,
        doc: "Auto-generated for Tiled usage",
      });
      transfer.push(macro return copy);
      var localCT = Context.getLocalType().toComplexType();
      fields.push({
        name: "transferTo",
        access: [APublic],
        kind: FFun({
          args: [{ name: "copy", type: localCT }],
          expr: macro $b{transfer},
          ret: localCT
        }),
        pos: pos,
        doc: "Auto-generated for Tiled usage",
      });
      fields.push({
        name: "transferToObject",
        access: [APublic],
        kind: FFun({
          args: [{ name: "obj", type: macro :tiled.types.TmxObject }],
          expr: if (useAs.contains(useAsTypes["initObject"])) macro {
            var copy = initObject(obj);
            transferTo(copy);
            return copy;
          } else macro { return null; },
          ret: macro :tiled.project.TiledClass
        }),
        pos: pos,
        doc: "Auto-generated for Tiled usage",
      });
      fields.push({
        name: "transferToTileset",
        access: [APublic],
        kind: FFun({
          args: [{ name: "tset", type: macro :tiled.types.TmxTileset }],
          expr: if (useAs.contains(useAsTypes["initTileset"])) macro {
            var copy = initTileset(tset);
            transferTo(copy);
            return copy;
          } else macro { return null; },
          ret: macro :tiled.project.TiledClass
        }),
        pos: pos,
        doc: "Auto-generated for Tiled usage",
      });
      
    }
    
    var exists = false;
    for (t in types) if (t.name == name) {
      t.members = props;
      exists = true;
      break;
    }
    if (!exists) {
      types.push({
        id: types.length+1,
        name: Context.getLocalType().getClass().name,
        type: TiledPropertyKind.KClass,
        useAs: useAs.map(u -> u.as),
        members: props,
        color: color,
      });
    }
    
    return projectMode ? fields : null;
  }
  
  #end
}