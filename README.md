# TiledHX

A complete rewrite of the [format-tiled](https://github.com/Yanrishatum/haxe-format-tiled) library with a change in a structure and support for recent [Tiled](https://www.mapeditor.org/) features. For curious souls you can also read the [short backstory](Backstory.md) of both libraries.

## Design notes
* I opted to unify TmxLayer into one class and contents are based on its type, which is now stored in `TmxLayer.kind`. Main reason is that I disliked gating layers behind an enum for a long time already, because not everyone needs to actually check the type of the layer. For example when type is determined by layer name, layer index or some other arbitrary condition, and developer is sure that it's a tile layer/object group/image layer and never anything else.
* Singular `Tiled` loader instance is used because newer Tiled maps are no longer self-sufficient, since there's now TSX tilesets, object templates and object types, that are sourced from outside.  
With having unified loader, we can use general cache between loading multiple maps, reducing loading times on average.
* Since Tiled 1.9 `type` was renamed into `class` in Tiled. Due to it being a keyword, whether something has a `class` it would be named as `type` instead. And author officially confirmed that he won't change keyword usage because he does not want to make breaking changes <!-- lol, break shit in 1.9 @ don't want to break shit again to unbreak it in 1.10, but still make breaking change that restores compat. -->
* Library has 2 distinct property parsing modes, see [Object Type integration](#object-type-integration) section for more information.
* In order to reduce data processing load, library opts to not parse a number of things. However it can be re-enabled via [define flags](#define-flags) if you need said data.
* Compared to `format-tiled`, this library does not try to be completely framework-detached. It still is framework-agnostic, however it offers framework integrations out of the box.

## Usage

1. Install library from Haxelib:
  ```cmd
  haxelib install tiledhx
  ```
  Or for dev build from git:
  ```cmd
  haxelib git tiledhx https://github.com/Yanrishatum/tiledhx
  ```
2. Add the library in HXML file:
  ```hxml
  -lib tiledhx
  ```
  * If you want to run in `project` mode, add the following define to HXML file:
    ```hxml
    -D tiled_props=project
    ```
3. Load the maps in the following manner:
```haxe
// Create the loader. You should store it in a static variable somewhere
// so you can reuse it for loading multiple maps.
var loader = new tiled.Tiled();
// Assign the loader methods. In case of supported backends you won't need to do that.
loader.loadXML = myAssetManager.loadXML;
loader.loadJson = myAssetManager.loadJson;
// Optionally you can assign image loaders, see custom types section.
// loader.loadImage
// loader.loadTileset
// loader.subRegion

// Load the TmxMap itself:
var map = loader.loadTMX("path/to/map.tmx");
// Flat iterator allows you to iterate all of the layers even if your map contains nested layer groups.
// If you want to crawl in a nested manner - iterate over `map.layers`.
for (layer in map.flatIterator()) {
  switch (layer.kind) {
    case TTileLayer:
      // Use layer.tileChunks or layer.tiles to load the tile layer.
      // If your map is infinite (map.infinite), you _should_ use layer.tileChunks
    case TObjectGroup:
      // Load your objects
    case TImageLayer:
      // Load the layer consisting of a single image.
    case TGroup:
      // The layer subgroup.
      // Because we're using flat iterator, after this layer you will receive
      // sub-layer of that group
      // You also can access them via `layer.subLayers`.
  }
}
```

For an example of project generation see samples.

## Using custom types for specific elements

It's possible to override various types to use ones from your engine to reduce the amount of extra passes and conversions between Tiled types and engine types.

This feature is based on Haxe allowing to override entire files provided by libraries by having them present in your classpath. 
I.e. to override `ImageType` you need to create `src/tiled/types/ImageType.hx` and declare your own `ImageType` here to override the type.

Currently it's possible to override the following:
* `tiled.types.ImageType` - The loaded texture type used by your engine, i.e. something `h2d.Tile` for Heaps. Should point at the type that has (preferably inline) static methods of `loadImage` and `subRegion`. See more detail in [ImageType.hx](tiled/types/ImageType.hx) / [Tiled.loadImage](tiled/Tiled.hx#loadImage) for more details.
* `tiled.types.TileImageType` - Typedefs to `ImageType` by default. This is useful if your engine image type and tile type are not equivalent.
* `tiled.types.TmxPoint` - A 2D `Float`-based point instance. Constructor should take `x: Float, y: Float` arguments. Primarily used for polyline/polygon objects.

See [Default backend support](#default-backend-support) for list of backends that are supported out of the box.

## Object type integration
By default Tiled uses `Properties` class for property data in the object. But since Tiled 1.9 rework of type system, it's possible to switch to macro-generated object types supplied by your own code.

To enable this feature add one of the following defines to your HXML file:
* `-D tiled_props=dynamic` (therefore called `dynamic` mode) will use `Properties` (default behavior)
* `-D tiled_props=project` (therefore called `project` mode) will disable `Properties` altogether and will use exclusively class-based approach.

Regardless of what mode is used, generating object types for .tiled-project file is possible.

### Generating the object types

All classes that should be exposes to Tiled should implement the `tiled.project.TiledClass` interface.

Afterwards, add the following line to your HXML file:
```hxml
--macro tiled.project.TiledProject.generateProject("path/to/my.tiled-project")
```
where `"path/to/my.tile-project` should point at the `.tiled-project` file you use to edit the maps.

> **Note:** As of writing this (Tiled 1.9/1.10) - if .tiled-project is updated externally - you have to restart Tiled in order for it to changes in your object types.

> **Compiler gotcha:** Keep in mind that if you do not `import` the class anywhere (or do not `--macro include` it) - compiler will not compile the class and therefore it will not be generated via `generateProject`. Make sure your `TiledClass` classes are property included.

### Customizing object type
By default, generated classes will use `#ffffffff` color and use the name of the implementing class as a Tiled class name. This can be customized by adding the following metadata to your class:
* `@:tcolor("#AARRGGBB")` - will change the outline color used for that object type. Additionally, using integer (`0xAARRGGBB`) instead of a string and shorthand notation of `#ARGB` is supported. If your notation does not include alpha (`"#RRGGBB"` / `"#RGB"` / `0xRRGGBB`) - it will be automatically set to `FF`.
* `@:tname("className")` - will enforce usage of provided class name for Tiled.
I.e. with `@:tname("breakable") class BreakableObject {}` it will use `breakable` as its name in Tiled instead of `BreakableObject`.

### Dictating applicable tiled types
By default, class cannot be applied to any of the Tiled entities (i.e. object/map/tile/layer/etc).
There are 3 ways to denote compatibility:
* By declaring static `initX(t: TmxX): T` methods which return a new instance of the class associated with the type provided.
If `initX` methods are present, the constructor and `@:useAs` metadata are ignored.
* By having a constructor take a tiled type as its only argument. I.e. `function new(obj: TmxObject)` would denote it as compatible only with `TmxObject`.
* By using `@:useAs()` metadata on the class. It is only usable if your constructor takes no arguments or all arguments are strictly optional. This limitation is not enforced in `dynamic` mode.
For it to work use the following syntax: `@:useAs(tile, object, layer, ...)` with types you wish that class to be compatible with.
Note that it is compatible with the constructor taking one argument notation. I.e. `new(?obj: TmxObject)` and `@:useAs(tile)` will denote class as compatible both with `TmxObject` and `TmxTile` and therefore generate `initObject` and `initTile` methods (in case of `project` mode).

The following init methods are supported:
* `initObject(object: TmxObject)`
* `initTile(tile: TmxTile)`
* `initLayer(layer: TmxLayer)`
* `initTileset(tileset: TmxTileset)`
* `initMap(map: TmxMap)`
* `initProperty(other: TiledClass)` - Allows this class to be used as a nested property for other classes.
* `initWangColor(color: WangColor)` - only if `tiled_metadata` flag is set.
* `initWangSet(wang: WangSet)` - only if `tiled_metadata` flag is set.

> Tip: If you use tile objects, you may want to expose class as both `tile` and `object` compatible, as you likely would set default values on tile first, and then would want it to be inherited to the object.

### Exposing variables

In order to expose your class fields to Tiled, use the `@:tvar` metadata on desired fields.
The property type is automatically derived from the field type. However, since some Tiled types use same underlying type,
you can hint at what type it should be exposed as via `@:tvar(file)` / `@:tvar(color)` / etc.

If you want the field to be loaded in `project` property mode, but not explicitly exposed in Tiled, you can add `optional` to `@:tvar` declaration.
i.e. `@:tvar(file, optional)` will parse the property as a file, however it will not list the property for Tiled.
Main use case would be for rarely used properties as to not pollute the property list in Tiled.
Keep in mind that you cannot add custom properties to nested classes, and optional property will not be available at all in such case.

If your exposed variable has a constant initializer (i.e. `@:tvar var myField: Int = 10`) - it will be reflected in Tiled, but only for constant expressions.

Supported field types are:
* `Int` - the field will be exposed as an `int` property.
  * By using `@:tvar(color)` hint - the field will be exposed as a color property and subsequently parsed on load.
  * By using `@:tvar(object)` hint - the field will be exposed as an object reference property and will contain the object ID or 0 if no object is selected.
* `String` - the field will be exposed as a `string` property
  * By using `@:tvar(file)` hint - the field will be exposed as a file property. Otherwise equivalent to string property.
  * By using `@:tvar(color)` hint - the field will be exposed as a color property. When set, color will be in `#RRGGBB` or `#AARRGGBB` format.
* `Float` - the field will be exposed as a `float` property.
  * By using `@:tvar(int)` hint - the field will be exposed as an `int` property instead.
* `Bool` - the field will be exposed as a `boolean` property.
* `TmxObject` - the field will be exposed as an object reference property. This will add a hidden `${fieldName}ID` variable to the class that will contain the object ID, and instance itself will be set during secondary finalization pass after all objects are parsed.
* Any class that implements `TiledClass` interface - will be exposed as a nested class field.
  <!-- * By using `@:tvar(object)` hint - will expose it as an object reference property, however when loading it will only load the instance if referenced object is of that type.
    This can be used to directly reference underlying object type skipping the `TmxObject` instance. -->
  > **Note:** Macro does not verify that referenced `TiledClass` exposes itself as compatible with `property` kind, and _will_ lead to compilation errors if it isn't.
* Any `enum` - Will expose the Haxe enum to Tiled. See about [enums](tiled-enums-vs-haxe-enums) below.
  * By using `@:tvar(string)` hint - the property will use a `string` type with enum names to store the values.
* Any `EnumFlags<enum>` - Will expose the Haxe enum as multi-choice enum to Tiled. See about [enums](tiled-enums-vs-haxe-enums) below.
  * By using `@:tvar(string)` hint - the property will use a `string` type with enum names to store the values.
  > **Note:** Default value for flags is not supported yet!
* Any `Array<enum>` - Same as `EnumFlags` in an Array form and by default will use `string` type. See about [enums](tiled-enums-vs-haxe-enums) below.
  * By using `@:tvar(int)` hint - the property will use an `int` bitmask type to store the values. Not recommended to use.
  > **Note:** Default value for flags is not supported yet!
* `Array<T>` - Tiled does not explicitly support array types, however this library provides a very primitive ad-hoc array support.
  Any type that is supported above wrapped around an Array will alter the way it's being loaded, in order to support multiple values.  
  Any property that starts with the property name, directly followed up by a `.` or `[` characters are treated as array values, and parsed as such. Keep in mind that there is no indexing support, hence `myField.foobar` or `myField[0]` would just cause an `Array.push` and appear in order Tiled stored them in (which is usually alphabetical).  
  By default only the default `myField` name is exposed for array types, however you can enforce exposition of multiple values at once with a `@:tfill(N)` meta where `N` is a number of properties to expose. If fill is above 1, the field is instead exposed as `myField[0]`, `myField[1]`, etc.
  > **Note:** Default values for arrays is not supported yet!

For example:
```haxe
class MyFancyObject implements tiled.project.TiledClass {
  public function new() {}
  
  @:tvar var boolProp: Bool;
  @:tvar(file) var fileProp: String;
  @:tvar var sub: MyOtherFancyObject; /* that also implements TiledClass */
  @:tvar(string) var enumField: MyFancyEnum;
  @:tvar var flags: EnumFlags<MyFancyEnum>;
  @:tvar @:tfill(3) var stringList: Array<String>; // Will be exposed as stringList[0], stringList[1] and stringList[2]
  @:tvar(optional) var unlistedFloat: Float; // Won't appear on Tiled property list, but will be parsed for project mode.
}
```

### Using `project` property mode
By using `-D tiled_props=project` you enable the project mode for the library. In this mode, classes that implement `TiledClass` will get extra generated fields and will be instantiated as the library loads the map and find those classes being used.

In Tiled instances, the `properties: Properties` field, will be replaced by a `tclass: TiledClass` field that will contain the `TiledClass` that was used in the map. Note that `tclass` is never null, and for instances that do not have a class will instead use `tiled.project.PropertyClass` that is a wrapper to classic `properties` field.

Major difference between `dynamic` and `project` is that in `project` mode any unknown properties are discarded and not stored in any way for instances that have a class attached to it.

In the future there may be added support for handling unknown properties.

<!-- TODO: Allow custom code in loadProperties/finalize -->
<!-- TODO: Allow the fallback `loadUnknownProperty(name: String, data: RawPropertyValue)` for extra properties -->

Do note that the `TiledClass` interface will have a number of methods that you _should not_ implement, as those are generated by the build macro.

## Tiled enums vs Haxe enums
Tiled offers 2 ways to store enums: `int` and `string`.
* Int enums will have enum names only for visual presentation and their index is stored instead.  
  Upside is smaller file footprint, but for active development it may break compatibility if new enum values are inserted between previously existing ones, as field indexing would change.
* String enums will have enum names used as enum values.  
  While taking more space stored and a bit more expensive to parse, biggest upside would be the fact that inserting new enums poses no risk of breaking previously configured maps.

Additionally, Tiled allows for multi-choice enums, that are stored as either comma-separated string for `string` type or a bitmask for `int` type.
Their Haxe counterparts are `Array<Enum>` and `haxe.EnumFlags<Enum>` respectively.

Enums that are exposed as string enums will have `_s` postfix added to their name, as well as `_fs` postfix for multi-choice enums. And `_f` postfix for multi-choice integer enums.

Due to how Tiled is made, using both multi-choice and single-choice on same Enum will expose it twice under different names. Same goes for string vs int types.

## Default backend support
### Heaps
* `ImageType` and `TileImageType` are an abstract over `h2d.Tile` and uses `hxd.Res` to load the images.
* `TmxPoint` is a typedef to `h2d.col.Point`.
* `Tiled.loadXML` and `Tiled.loadJson` use `hxd.Res` to load the data.
* Offers `Tiled.loadObjectTypesResource` and `Tiled.loadTMXResource` helpers methods to load from `hxd.res.Resource`.


## Define flags

<!-- * `tiled_extra_fields` - Enables the `@:build` macro for [extra fields](#extra-fields) on all Tiled types. -->
* `tiled_metadata` - Load and parse metadata that would be irrelevant in order to display the map.
  * Enables WangSets
  * `TmxMap`: Enables the `format`, `tiledVersion`, next IDs, export and editor config metadata.
  * `TmxTileset`: Enables `allowFlip`, `allowRotate` and `preferUntransformed` metadata. Loads WangSets.
  * `TmxTile`: Enables `probability` metadata.
* `tiled_rotation_degrees` - Load the rotation value as is in degrees instead of converting it to radians. <!-- You absolute degenerates. -->
* `tiled_disable_flipping_safeguard` - When doing an implicit conversion of a `TmxTileIndex` abstract into an `Int`, do not strip the flip flags. (Raw value still can be accessed via `raw` field). When not set, implicit casts into int are equivalent to `tile.gid`.
* `tiled_enable_terrains` - Re-enable support for Terrains that were deprecated in 1.5 in favor of WangSets.
* `tiled_props` - Can be either `project` or `dynamic` (default) and enforces different property loading handling.
* `tiled_disable_debug_warnings` - When compiled with `-debug` flag, some elements of Tiled will trace warnings if unexpected data is processed. Use this flag to disable said warnings. As of right now the warnings affected:
  * When unknown property is provided to the `TiledClass`.

<!-- # Extra fields

TODO
1. Enable `-D tiled_extra_fields`
2. Use `--macro tiled.types.Macros.addXData(name, type)` -->