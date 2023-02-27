# Legacy of format-tiled

Hello, I'd like to write up on the history of this library and its predecessor - format-tiled. How it came to be, and why.

Consider it more a rambly blog-post, if anything.

## 2014 - the year I had enough
At the time, there wasn't a tiled library that didn't do unnecessary engine integrations and chains to a specific framework/engine. Moreso, every single one of them was horrendously lagging behind capabilities of Tiled. There was OFL-exclusive tiled parser, there was Flixel-exclusive parser, HaxePunk parser. All of them lacking in one thing or another. I did not understand why nobody ever bothered to make just a tiled library that does what it is expected to do - parse the goddamn thing. Not convert it into internal objects. Not attempt to load images, or apply some other framework/engine angle on the output.

And so it began. I started working on a library that just parsed the .tmx files and was much more capable of all others combined, but sacrificing the questionable feature of it being able to load images (it's not the parser job to load those anyway, who knows where those are sources, what if those images are bundled on a singular atlas, not in a file?). 

Library took after the well-known `format` library - you create `Parser`, you have helpers in `Tools`, all data is described inside `Data`. Yet I did a number of bad design decisions mimicking format style, especially with layers and struggled with it for years after.

The library evolved and changed a lot over the years, but it remained true to its core principle - being framework-agnostic. You can drop it in whatever engine you use, even use it for headless server instances if you need it for pure logic, not display. Yet frustration with its flaws grew. 

Tiled didn't stagnate either, it also evolved over time. Properties now were typed. Tilesets now could be offloaded into separate files and reused. Objects got more complex. Layers were no longer linear, but also nested. And the longer I had to maintain specific feature the more my frustrations grew.

## 2020 - the year I had enough, electric boogaloo
I reached the tipping point. By the time I no longer used OpenFL nor HaxePunk and was pretty much exclusively using Heaps. Yet every time I needed to parse .tmx files I had to repeat same things over and over again, tripping over same design flaws and gritting my teeth. But what if I didn't have to? I could just rewrite the library from scratch! Out with the `format` style, we're parsing a map that contains more than just one specific thing as most `format` supported formats do. Especially since there were now tileset files, object templates, .tiled-project and such. Out with old typedefs as much as possible, we can use classes, less dynamics - better performance. And finally, _finally_ I can get rid of some design flaws I was struggling with for years. And also scrap the "no frameworks allowed" ideology. We still aren't chained to one specific framework or engine, but at least we can integrate into one. And since I shown middle finger to OFL/HP and pretty much never touched Flixel - only supported integration was Heaps. Deal with it. :^) (You are free to PR integrations for other engines tho)

Therefore aptly named `tiledhx` library was born. Initial implementation wasn't anything fancy. It just parsed the thing and it worked. But I did spend a lot of attention on property support, so I can get those nice and typed out of the box. I even experimented with statically typed properties at the time, but it was clunky and prone to breaking, so I scrapped the whole idea. 

I planned to publish the library when it was more presentable. Yet the time won't come for 3 years...

## 2023 - no, I didn't snap this time, I just decided to finally finish it up

And that bring us to february of 2023. The library undergone quite a few internal changes, experiments and just polishing, but I still couldn't say it was ready. What was still bothering me is properties. They were still a bit more fancy `Map<String, T>`, with a layer of glimmer atop. I wanted something more concrete.

And in summer 2022 Tiled 1.9 came out. And boy did it bring with changes. Entire type system got internal rework. `objecttypes.xml` became completely obsolete, in favor of project-centric class system. It even had enums! And nested properties due to classes! (Still no arrays tho, give me those lists bjorn, I beg you.) What a day to be alive. So I started to rewrite properties, and it game a lot of headaches, since I also wanted to properly integrate the class system into the library. And I kind of did. But I still felt that it could be better.

And so, I had a striking idea: What if it's not Tiled that supplies the classes, but Haxe? Lo and behold - the project property mode was born. Inspiration struck and I went to work. I've got it working surprisingly fast even with a few design changes. Now you could declare your types on Haxe side, and then all those types are parsed into the classes! It's not perfect, there's a lot to be improved upon (like injecting custom code into parse process and extending classes), but it works, and it works decently well.

In fact, it changed the way I handle object processing _drastically_. In order to expose the class to Tiled all you need is to implement an interface, provide factory methods and mark exposed variables. But what exactly that class is - library doesn't care. Hence I made them actual in-game entities. So I construct them just as the map is being parsed, and then just extract them while iterating over the objects in the map and finish up the initialization. And presto, object is primed and ready. Much less code, much less hassle, no need for some internal indexing or objects types and classes they belong to. They are already registered. Filled with property values and (almost) ready to go by the time I get my TmxMap instance.

## Final touches and first public release
And so, here we are. The 1.0.0 version of the library. I can finally ditch `format-tiled` and just tell people to use that library instead. Because it's better. It has more features supported. It has more capacity for engine integration with project mode. It still defaults to classic wrapper around `Map`, so for short-term projects you don't need to do much to get it going, just plop it in, and load the maps. You can even use project generator without project mode enabled, it will work, if you want to just declare your classes for Tiled, but not commit to much more strict project mode.

I achieved my goal - I removed pesky design issues as hiding values behind enums (by the most part), simplified multiple elements and introduced a unified loader approach. Because cache your goddamn tilesets people. Yet there is more work to do.

What's next? Probably not a lot until next Tiled release. I plan to do some fixes here and there, maybe some new project mode feature, more/better samples, an _example game_, finishing up the docs... Ah yes, most of the library is documented! Crazy thing in Haxe ecosystem, I know, but it is a thing.

On that note, thanks for reading my ramblings regarding this journey of someone who simply wanted a Tiled library that just did the thing without having to fight the needless integrations introduced by whoever made the framework-chained ones.

`format-tiled` is dead, long live `tiledhx`!