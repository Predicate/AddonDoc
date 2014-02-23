<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
	<head>
		<meta http-equiv="Content-Type" content="text/html;charset=utf-8" />
		<title><%=addon.name%> index - Addondoc</title>
		<link rel="stylesheet" href="../style.css" type="text/css" />
	</head>
	<body>
<%include("templates/nav.lp", { outfunc = outfunc, addon = addon, ipairs = ipairs })%>
		<div id="content">
			<h1><%=addon.name%></h1>
			<h2>TOC data</h2>
			<dl>
				<%for i, k in ipairs(addon.tocdata) do%>
				<dt><%=k%></dt>
				<dd><%=addon.tocdata[k]%></dd>
				<%end%>
			</dl>
			<%if #docs.functions > 0 then%>
			<h2>Function Summary</h2>
			<dl>
				<%for _, func in ipairs(docs.functions) do local file = docs.functions[func] local block = docs.files[file].functions[func] if not block.private then%>
				<dt><a href="<%=file%>.html#<%=block.name%>"><%=block.name%></a>(<%=block.param and concat(block.param, ", ") or ""%>)</dt>
				<%if block.summary then%><dd><%=block.summary%></dd><%end%>
				<%end end%>
			</dl>
			<%end%>
			<%if #docs.tables > 0 then%>
			<h2>Table Summary</h2>
			<dl>
				<%for _, tab in ipairs(docs.tables) do local block = docs.tables[tab]%>
				<dt><%=block.name%></dt>
				<dd><%=block.summary%></dd>
				<%end%>
			</dl>
			<%end%>
			<%if #docs.functions > 0 then%>
			<h2>Functions</h2>
			<%for _, func in ipairs(docs.functions) do local file = docs.functions[func] local block = docs.files[file].functions[func] if not block.private then%>
			<div class="doc">
				<h3><a name="<%=block.name%>"></a><%=block.name%>(<%=block.param and concat(block.param, ", ") or ""%>)</h3>
				<p><%=block.description%></p>
				<%if block.param then%>
				<h4>Parameters</h4>
				<ul>
					<%for _, p in ipairs(block.param) do%>
					<li><pre class="code"><%=p%></pre>: <%=block.param[p] or ""%></li>
					<%end%>
				</ul>
				<%end%>
				<%if block.usage then%>
				<h4>Usage</h4>
				<ul>
					<%for _, u in ipairs(block.usage) do%>
					<li><pre class="code"><%=u%></pre></li>
					<%end%>
				</ul>
				<%end%>
				<%if block["return"] then%>
				<h4>Returns</h4>
				<ol>
					<%for _, ret in ipairs(block["return"]) do%>
					<li><%= ret %></li>
					<%end%>
				</ol>
				<%end%>

				<%if block.see then%>
				<h4>See also</h4>
				<ul>
					<%for _, s in ipairs(block.see) do%>
					<li><a href="#<%=s%>"><%=s%></a></li>
					<%end%>
				</ul>
				<%end%>
			</div>
			<%end end%>
			<%end%>
			<%if #docs.tables > 0 then%>
			<h2>Tables</h2>
			<div class = "doc">
				<%for _, tab in ipairs(docs.tables) do local block = docs.tables[tab]%>
					<h3><a name="<%=block.name%>"></a><%=block.name%></h3>
					<p><%=block.description%></p>
					<%if block.field then%>
					<h4>Fields:</h4>
					<ul>
						<%for _, f in ipairs(block.field) do%>
						<li><pre class="code"><%=f%></pre>: <%=block.field[f] or ""%></li>
						<%end%>
					</ul>
					<%end%>
				<%end%>
			</div>
			<%end%>
		</div>
	</body>
</html>
