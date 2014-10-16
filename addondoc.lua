#!/usr/bin/env lua

local GRAPHVIZ = true --whether to generate dependency graph (requires graphviz)
local INTERFACE = {
	CURRENT = 60000, --current interface version. below this, addons are "out of date"
	MINIMUM = 20000, --minimum required interface version. below this, addons are "incompatible"
}

local io = require "io"
local lfs = require "lfs"
local lp do
	local ret
	ret, lp = pcall(require,"luadoc.lp")
	if not ret then
		ret, lp = pcall(require, "cgilua.lp")
	end
	if not ret then
		lp = require("lp")
	end
end

--tag parsing
local parse do
	local handletag do
		local function singlehandler(block, tag, text)
			block[tag] = text
		end

		local function multihandler(block, tag, text)
			block[tag] = block[tag] or {}
			table.insert(block[tag], text)
		end

		local function kvhandler(block, tag, text)
			local name, desc = text:match("^([_%w%.]+)%s+(.*)")
			if name and desc then
				block[tag] = block[tag] or {}
				if not block[tag][name] then
					block[tag][name] = desc
					table.insert(block[tag], name)
				elseif block[tag][name] == "" then
					block[tag][name] = desc
				end
			end
		end

		local handlers = {
			class = singlehandler,
			name = singlehandler,
			description = singlehandler,
			field = kvhandler,
			param = kvhandler,
			release = singlehandler,
			["return"] = multihandler,
			see = multihandler,
			usage = multihandler,
		}

		function handletag(block, tag, text)
			if handlers[tag] then
				handlers[tag](block, tag, text)
			end
		end
	end

	local identifiers_list_pattern = "%s*(.-)%s*"
	local identifier_pattern = "[^%(%s]+"
	local function_patterns = {
		"^()%s*function%s*("..identifier_pattern..")%s*%("..identifiers_list_pattern.."%)",
		"^%s*(local%s)%s*function%s*("..identifier_pattern..")%s*%("..identifiers_list_pattern.."%)",
		"^()%s*("..identifier_pattern..")%s*%=%s*function%s*%("..identifiers_list_pattern.."%)",
	}

	local function parse_block(chunk, code)
		local block = {}
		if code then
			for _, pat in ipairs(function_patterns) do
				local l, id, param = code:match(pat)
				if l then
					block.class = "function"
					block.name = id
					block.param = {}
					block.private = (l == "local")
					for p in param:gmatch("[%a_][%w_]*") do
						block.param[p] = ""
						table.insert(block.param, p)
					end
					break
				end
			end
		end

		local currenttag = "description"
		local currenttext
		for _, line in ipairs(chunk.comment) do
			local tag, text = line:match("@([_%w%.]+)%s+(.*)")
			if tag then
				handletag(block, currenttag, currenttext)
				currenttag = tag
				currenttext = text
			else
				if currenttext and currenttext ~= "" then
					currenttext = currenttext .. " " .. line
				else
					currenttext = line
				end
			end
		end
		handletag(block, currenttag, currenttext)
		block.summary = string.match((block.description or "") .. " ", "(.-%.)%s") or block.description
		return block
	end

	local function parse_file(filepath)
		local filedoc = {
			type = "file",
			name = filepath,
			functions = {},
			tables = {},
		}
		local f = io.open(filepath)
		if not f then return filedoc end

		local line = (f:read() or ""):match("^\239?\187?\191?(.*)")
		local incomment, blockcomment, chunk
		while line ~= nil do
			if line:find("^%s*%-%-%-") and not incomment then
				chunk = { comment = {} }
				incomment = true
			end

			if incomment then
				local _, blockstart = line:find("%-%-%[%[%s*") --TODO: this doesn't work for [==[ long bracket blocks ]==]
				if blockstart then
					line = line:sub(blockstart + 1)
					blockcomment = true
				end
				if blockcomment then
					local start, finish = line:find("%]%]")
					if start then
						table.insert(chunk.comment, line:sub(1, start - 1))
						line = line:sub(finish + 1)
						blockcomment = false
					else
						table.insert(chunk.comment, line)
						line = nil
					end
				else
					local _, commentstart = line:find("^%s*%-%-%-?%s*")
					if commentstart then
						table.insert(chunk.comment, line:sub(commentstart + 1))
						line = nil
					elseif not line:match("^%s*$") then
						incomment = false
						local block = parse_block(chunk, line) --TODO: get more lines as needed to complete function definitions
						if block.class and filedoc[block.class .. "s"] then
							table.insert(filedoc[block.class .. "s"], block.name)
							filedoc[block.class.."s"][block.name] = block
						else
							for k, v in pairs(block) do
								filedoc[k] = filedoc[k] or v
							end
						end
					else
						line = nil
					end
				end
			else
				line = nil
			end
			line = line or f:read()
		end
		f:close()
		return filedoc
	end

	function parse(files)
		local docs = {
			files = {},
			functions = {},
			tables = {},
		}
		for _, path in ipairs(files) do
			if not docs.files[path] then
				docs.files[path] = parse_file(path)
				table.insert(docs.files, path)
			end
		end
		table.sort(docs.files)
		for file, doc in pairs(docs.files) do
			if doc.functions then
				table.sort(doc.functions)
				for _, name in ipairs(doc.functions) do
					docs.functions[name] = file
					table.insert(docs.functions, name)
				end
			end
			if doc.tables then
				table.sort(doc.tables)
				for _, name in ipairs(doc.tables) do
					docs.tables[name] = file
					table.insert(docs.tables, name)
				end
			end
		end
		table.sort(docs.functions)
		table.sort(docs.tables)
		return docs
	end

end

--do some mildly intelligent command-line parsing
local opts, todoc = {}, {} do
	local first_non_opt
	for k = 1, #arg, 2 do
		local v = arg[k]
		if v:sub(1, 1) == "-" then
			local opt = v:sub(2)
			assert(opts[opt] == nil, ("Option %s specified twice"):format(v))
			opts[opt] = arg[k + 1]
		else
			first_non_opt = k
			break
		end
	end
	if first_non_opt then
		for i = first_non_opt, #arg do
			todoc[#todoc+1] = arg[i]
		end
	end

	local function assertpathopt(opt, message)
		assert(opts[opt], message)
		if not opts[opt]:match("/$") then
			opts[opt] = opts[opt].."/"
		end
	end

	assertpathopt("t", "Required argument missing: -t <templates path>")
	assertpathopt("p", "Required argument missing: -p <path to AddOns dir>")
	assertpathopt("o", "Required argument missing: -o <output path>")
end

local addons = {}

--scan addons
for addon in lfs.dir(opts.p) do
	if not addon:match("^%.+$") then
		local f = opts.p..addon
		if lfs.attributes(f, "mode") == "directory" then
			local toc = io.open(f.."/"..addon..".toc")
			if toc then
				local new = {
					name = addon,
					tocdata = {},
					files = {},
				}
				local line = (toc:read() or ""):match("^\239?\187?\191?(.*)")
				while line do
					line = line:match("^%s*(.-)%s*$")
					if line:sub(1,1) == "#" then
						local field, value = line:match("^##%s*(.-)%s*:%s*(.*)$")
						if field then
							if field == "RequiredDeps" or field == "Dependancies" then field = "Dependencies" end --aliases
							new.tocdata[field] = tonumber(value) or value
							table.insert(new.tocdata, field)
						end
					elseif line:find("%.lua$") then
						table.insert(new.files, (line:gsub("\\", "/")))
					end
					line = toc:read()
				end
				toc:close()
				if not opts.a or not new.tocdata.Author or new.tocdata.Author == opts.a then
					addons[addon] = new
					table.insert(addons, addon)
				end
			end
		end
	end
end
table.sort(addons)

local function makepathexist(path)
	if lfs.attributes(path, "mode") == "directory" then return end
	path = path:gsub("\\", "/") --just in case someone happens to be running Windows
	local dir = ""
	for d in path:gmatch(".-/") do
		dir = dir .. d
		lfs.mkdir(dir)
	end
end

local function smartopen(filename)
	local f = io.open(filename, "w")
	if not f then
		makepathexist(filename:match("^(.+/).-$"))
		f = assert(io.open(filename, "w"))
	end
	return f
end

makepathexist(opts.o)

if GRAPHVIZ then
	--generate dependency graph
	local f = io.popen('ccomps -x | dot | gvpack | neato -n2 -Tsvg -o "'..opts.o..'addons.svg"', "w")
	f:write([[
	digraph addons {
		graph [bgcolor=transparent]
		node [shape=box, color=gray, fontcolor="#ffcc00"]
		edge [dir=back, color=gray]
	]])
	for i, name in ipairs(addons) do
		f:write('\t"', name, '"', ' [URL="' .. name .. '/index.html" target="_parent"' .. (addons[name].tocdata.LoadOnDemand == 1 and (', color=blue, tooltip="' .. name .. '"') or "") .. "]\n")
	end

	--TOC fields that generate graph edges, and the extra attributes for their edge types
	local edgefields = {
		Dependencies = '[tooltip="Requires"]',
		OptionalDeps = '[style=dashed, tooltip="Optionally requires"]',
		LoadWith = '[color=purple, tooltip="Loaded with"]',
		LoadManagers = '[style=dashed, color=purple, tooltip="Loaded by"]',
	}

	for i, name in ipairs(addons) do
		for k, v in pairs(edgefields) do
			if addons[name].tocdata[k] then
				for dep in addons[name].tocdata[k]:gmatch("[%w_%-%.]+") do
					if addons[dep] then f:write('\t"', dep, '" -> "', name, '" '..v..'\n') end
				end
			end
		end
	end
	f:write('}')
	f:close()
end

local outfunc = function(str) if str then return io.write(str) end end
lp.setoutfunc("outfunc")

--generate index page
local f = smartopen(opts.o.."docs.html")
io.output(f)
local env = {
	outfunc = outfunc,
	ipairs = ipairs,

	author = opts.a,
	INTERFACE = INTERFACE,
	addons = addons,
}
lp.include(opts.t.."index.lp", env)
f:close()

--generate addon docs
local function addondoc(name)
	local addon = addons[name]
	if not addon then return end
	local current_dir = lfs.currentdir()
	lfs.chdir(opts.p..name)
	local doc = parse(addon.files)
	lfs.chdir(current_dir)
	local f = smartopen(opts.o .. name .. "/index.html")
	io.output(f)
	local env = {
		outfunc = outfunc,
		pairs = pairs,
		ipairs = ipairs,
		select = select,
		concat = table.concat,
		include = lp.include,

		addons = addons,
		addon = addon,
		docs = doc,
	}
	lp.include(opts.t.."addon.lp", env)
	f:close()

	--generate file pages
	for _, v in ipairs(addon.files) do
		local f = smartopen(opts.o .. name .. "/" .. v .. ".html")
		io.output(f)
		env.docs = doc.files[v]
		lp.include(opts.t.."file.lp", env)
		f:close()
	end
end

if #todoc > 0 then
	for _, name in ipairs(todoc) do
		addondoc(name)
	end
else
	for i, name in ipairs(addons) do
		addondoc(name)
	end
end
