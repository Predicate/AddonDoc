<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
	<head>
		<meta http-equiv="Content-Type" content="text/html;charset=utf-8" />
		<title>Addon index - Addondoc</title>
		<link rel="stylesheet" href="style.css" type="text/css" />
	</head>
	<body>
		<div id="center">
			<a href="addons.png"><img src="addons.png" alt="addon graph"/></a>
			<h2>Addons<%=author and " by "..author or ""%></h2>
			<table class="list">
				<tr>
					<th>TOC</th>
					<th>Name</th>
					<th>Description</th>
					<%if not author then%>
					<th>Author</th>
					<%end%>
				</tr>
				<%for i, name in ipairs(addons) do tocdata = addons[name].tocdata%>
				<tr>
					<td><span class=<%if tocdata.Interface == INTERFACE.CURRENT then%>"current"<%elseif tocdata.Interface < INTERFACE.CURRENT and tocdata.Interface >= INTERFACE.MINIMUM then%>"outdated"<%else%>"incompatible"<%end%>><%=tocdata.Interface%></span></td>
					<td><a href="<%=name%>/index.html"><%=tocdata.Title or name%><%=tocdata.Title and name ~= tocdata.Title and "<br />("..name..")" or ""%></a></td>
					<td><%=tocdata.Notes%></td>
					<%if not author then%>
					<td><%=tocdata.Author%></td>
					<%end%>
				</tr>
				<%end%>
			</table>
		</div>
	</body>
</html>
