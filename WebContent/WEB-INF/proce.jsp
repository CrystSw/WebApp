<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ page import="java.util.Date, java.text.SimpleDateFormat" %>
<%!
/*
	現在時刻を文字列で返す関数

	@return 現在時刻の文字列
*/
String getTimeString(){
	String name = "";
	Date now = new Date();
	SimpleDateFormat df = new SimpleDateFormat("yyyyMMddHHmmssSSS");
	return df.format(now);
}
%>
<%
/*-----ファイルアップロード機能の実装-----*/
Part part = request.getPart("file");
//ファイル名は現在時刻から決定する
String name = getTimeString();
//"/WEB-INF/upload/"に書き込む(上限2MB)
part.write(getServletContext().getRealPath("/WEB-INF/upload")+"/"+name);


%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Insert title here</title>
</head>
<body>

</body>
</html>