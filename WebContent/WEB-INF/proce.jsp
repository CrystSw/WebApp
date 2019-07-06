<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ page import="java.io.IOException, java.io.File, java.io.ByteArrayOutputStream, java.io.BufferedOutputStream" %>
<%@ page import="java.util.Date, java.util.Base64" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ page import="java.awt.image.BufferedImage" %>
<%@ page import="java.sql.*" %>
<%@ page import="javax.imageio.ImageIO" %>
<%!
/**
	現在時刻を文字列で返す

	@return 現在時刻の文字列
*/
String getTimeString(){
	String name = "";
	Date now = new Date();
	SimpleDateFormat df = new SimpleDateFormat("yyyyMMddHHmmssSSS");
	return df.format(now);
}

/**
	ファイルの拡張子を取得する

	@param part - Partオブジェクト
*/
public String getFileExtension(Part part) {
	String name = null;
    for (String dispotion : part.getHeader("Content-Disposition").split(";")) {
        if (dispotion.trim().startsWith("filename")) {
            name = dispotion.substring(dispotion.indexOf("=") + 1).replace("\"", "").trim();
            name = name.substring(name.lastIndexOf(".") + 1);
            break;
        }
    }
    return name;
}

/**
	指定したパスに存在する画像をBase64エンコードする

	@param impath - 画像ファイルへのパス
*/
String getBase64ofImage(String impath) throws IOException {
	//画像を読み込む
	File file = new File(impath);
	BufferedImage image = ImageIO.read(file);
	ByteArrayOutputStream baos = new ByteArrayOutputStream();
	BufferedOutputStream bos = new BufferedOutputStream(baos);
	image.flush();

	//バイナリデータをバイト配列へ格納する
	ImageIO.write(image, "png", bos);
    bos.flush();
    bos.close();
    byte[] bImage = baos.toByteArray();

    //バイト配列をBase64エンコードする
    String base64 = Base64.getEncoder().encodeToString(bImage);

    return base64;
}

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
/*-----投稿者名の取得-----*/
String user = request.getParameter("u");

/*-----ファイルアップロード機能の実装-----*/
/*未対応形式の場合の処理については後で実装します．*/
Part part = request.getPart("file");
//ファイル名は現在時刻から決定する
String filename = getTimeString();
//"/WEB-INF/upload/"に書き込む(上限2MB)
part.write(getServletContext().getRealPath("/WEB-INF/upload")+"/"+filename);



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