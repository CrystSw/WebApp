<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%!
/**
	データベース制御クラス
*/
public class DatabaseAccess{
	private Connection conn = null;
	private Statement state;
	private ResultSet rs;

	/**
		指定したデータベースへの接続を確立する

		@param dbpath - データベースファイルへのパス
	*/
	DatabaseAccess(String dbpath) throws SQLException, ClassNotFoundException{
		Class.forName("org.sqlite.JDBC");
		conn = DriverManager.getConnection(dbpath);
	}

	/**
		SQLを実行し，ResultSetを返す．

		@param sql - エスケープされたSQL文
		@return ResultSet
	*/
	public ResultSet requestSQL(String sql) throws SQLException {
		state = conn.createStatement();
		rs = state.executeQuery(sql);
		return rs;
	}

	/**
		デストラクタ呼び出し
		※実行される保証はないので，できる限り明示的にデストラクタを呼び出してください．
	*/
	@Override
	protected void finalize() throws Throwable{
		try {
			super.finalize();
		} finally {
			destructor();
		}
	}

	/**
		デストラクタ
		データベースとの接続を明示的に切断する．
		※このメソッド実行後はインスタンスにアクセスしないでください．
	*/
	public void destructor() throws SQLException{
		if(conn != null){
			conn.close();
			conn = null;
		}
	}
}
%>
<%
String id = request.getParameter("id");

StringBuilder resStr = new StringBuilder();
//データベースへ記録
try{
DatabaseAccess da = new DatabaseAccess(getServletContext().getRealPath("/WEB-INF/lib")+"/data.db");
ResultSet rs = da.requestSQL("select * from data where id = " + Integer.parseInt(id));
da.destructor();

resStr.append("{");
resStr.append("\"Response\" : [");
resStr.append("\"ServiceInfo\" : [");
resStr.append("{\"status\" : \"success\"}");
resStr.append("],");
resStr.append("\"result\" : [");
resStr.append("{\"user\" : \""+rs.getString(2)+"\"},");
resStr.append("{\"score\" : \""+rs.getString(3)+"\"}");
resStr.append("]");
resStr.append("]");
resStr.append("}");

} catch(Exception e) {
resStr.append("{");
resStr.append("\"Response\" : [");
resStr.append("\"ServiceInfo\" : [");
resStr.append("{\"status\" : \"error\"}");
resStr.append("]");
resStr.append("]");
resStr.append("}");
}

String msg = resStr.toString();

%>
<%= msg %>