AddonDoc
========

AddonDoc is a documentation generation tool for WoW addons, loosely based on LuaDoc. It generates documentation from TOC metadata and LuaDoc tags found in .lua files. An addon index and dependency graph is also created, with optional filtering by author. Output is XHTML formatted using configurable LuaPages templates.

Usage: `addondoc.lua -t /path/to/templates -p /path/to/WoW/Interface/AddOns -o /path/to/output/ [-a authorname] [addon1 addon2 ... addonN]`

	* If `-a` is specified, only addons with a TOC Author field equal to `authorname` will be processed.
	* If `addon1..addonN` are omitted, docs will be generated for all addons (subject to `-a` filter).

Dependencies:

	* Lua 5.1
	* LuaFileSystem ("lfs") module. <http://keplerproject.github.com/luafilesystem/>
	* Graphviz for dependency graphing. <http://www.graphviz.org/>

Known Issues:

	* The script must be run from its own directory unless LuaDoc or CGILua is installed.
	* Comments in `--[==[ long brackets ]==]` are not parsed correctly.
	* Functions with argument lists spanning multiple lines are not parsed correctly.
	* Graphviz is run using io.popen(), which may not work on all platforms. Set GRAPHVIZ to false to skip this.
	* Current and minimum Interface versions must be manually updated for new WoW releases. They can be set in the INTERFACE table.
