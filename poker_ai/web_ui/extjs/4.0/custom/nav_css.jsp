<%@ page import="sms.ColorScheme" %>
<%@ page import="util.UtilityMethods" %>
<%
	UtilityMethods.setHttpReponseHeader(response, false, "text/css");
	
	ColorScheme userColors = ColorScheme.getByName((String)session.getAttribute("color_scheme"));
	final String linkColor     = userColors.getBaseColor();
	final String tabColor      = userColors.getHeaderFontColor();
	final String textColor     = userColors.getFontColor();
	final String excludedColor = userColors.getExcludedColor();
	final String bgColor       = userColors.getHeaderColor();
%>
.sub-menu-text-color .x-grid-cell-inner {
	background-color: #<%= excludedColor %> !important;
	color: #<%= textColor %>;
}

.x-grid-row-over .x-panel-header-default {
	background-color: #<%= tabColor %> !important;
	background-image: none !important;
}

.x-grid-row-over .x-panel-header-default .x-grid-cell-inner {
	color: #<%= bgColor %> !important;
}

.x-grid-table .x-grid-row-selected .x-panel-header-default {
	background-color: #<%= tabColor %> !important;
	background-image: none !important;
}

.x-grid-row-selected .x-panel-header-default .x-grid-cell-inner {
	color: #<%= bgColor %> !important;
}

.x-panel-header-default .x-grid-cell-inner {
	color: #<%= tabColor %> !important;
}

.x-grid-row-selected .sub-menu-text-color .x-grid-cell-inner {
	background-color: #<%= linkColor %> !important;
}

.x-grid-row-over .sub-menu-text-color .x-grid-cell-inner {
	background-color: #<%= linkColor %> !important;
}

.x-grid-row-selected .sub-menu-text-color .x-grid-cell-inner .nav-bullet {
	background-image:url(nav_selected.gif) !important;
	background-repeat: no-repeat;
	background-position: 0px 9px;
}
