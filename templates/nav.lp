		<div id="nav">
			<h2><a href="../docs.html">Addon Index</a></h2>
			<h3><%if file then%><a href="<%=("../"):rep(select(2, file:gsub("/","")) + 1)..addon.name%>/index.html"><%=addon.name%></a><%else%><%=addon.name%><%end%></h3>
			<%if #addon.files > 0 then%>
			<ul>
				<%for _, v in ipairs(addon.files) do%>
				<li><%if file ~= v then%><a href="<%=file and ("../"):rep(select(2, file:gsub("/","")))%><%=v%>.html"><%=v%></a><%else%><%=v%><%end%></li>
				<%end%>
			</ul>
			<%end%>
		</div>
