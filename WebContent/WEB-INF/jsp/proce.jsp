<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ page import="java.io.BufferedReader, java.io.InputStreamReader, java.io.IOException, java.io.File, java.io.ByteArrayOutputStream, java.io.BufferedOutputStream, java.io.DataOutputStream" %>
<%@ page import="java.util.Random, java.util.Map, java.util.List, java.util.Iterator, java.util.Date, java.util.Base64" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ page import="java.awt.image.BufferedImage" %>
<%@ page import="java.sql.*" %>
<%@ page import="javax.imageio.ImageIO" %>
<%@ page import="java.net.*" %>
<%@ page import="com.fasterxml.jackson.databind.ObjectMapper" %>
<%@ page import="com.fasterxml.jackson.databind.JsonNode;" %>
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
	for(String dispotion : part.getHeader("Content-Disposition").split(";")) {
		if(dispotion.trim().startsWith("filename")) {
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
	@paran fext - ファイル拡張子(ファイルタイプ)
*/
String getBase64ofImage(String impath, String fext) throws IOException {
	//画像を読み込む
	File file = new File(impath);
	BufferedImage image = ImageIO.read(file);
	ByteArrayOutputStream baos = new ByteArrayOutputStream();
	BufferedOutputStream bos = new BufferedOutputStream(baos);
	image.flush();

	//バイナリデータをバイト配列へ格納する
	ImageIO.write(image, fext, bos);
	bos.flush();
	bos.close();
	byte[] bImage = baos.toByteArray();

	//バイト配列をBase64エンコードする
	String base64 = Base64.getEncoder().encodeToString(bImage);

	return base64;
}

/**
	結果のJSONをパーサし，スコアを計算する．
*/
int calcScore(String json) throws IOException {
	ObjectMapper mapper = new ObjectMapper();
	JsonNode root = mapper.readTree(json);

	//スコアの重み
	int weight = 100;
	//スコア
	int score = 0;
	for(JsonNode n : root.get("localizedObjectAnnotations")){
		if(n.get("name").asText().equals("Cat")){
			score += weight * n.get("score").asInt();
			weight /= 2;
		}
	}

	return score;
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

/**
	APIサーバへの接続クラス
*/
public class APIAccess {
    public String url = ""; /* URL */
    public String postStr = "";	/*POSTデータ*/
    public String encoding = "UTF-8"; /* レスポンスの文字コード */
    public String header = ""; /* レスポンスヘッダ文字列 */
    public String body = ""; /* レスポンスボディ */

    /**
		接続するWebサーバのURLとPOSTするデータを指定する

		@param url - WebサーバのURL
		@param postStr - POST文字列
	*/
    public APIAccess(String url, String postStr) {
		this.url = url;
		this.postStr = postStr;
    }

	/**
		Webサーバにアクセスし，headerおよびbodyに値を格納する
	*/
	public void doAccess() throws MalformedURLException, ProtocolException, IOException {
		/* 接続準備 */
		URL u = new URL(url);
		HttpURLConnection con = (HttpURLConnection)u.openConnection();
		DataOutputStream dos = null;

		con.setRequestMethod("POST");
		con.setInstanceFollowRedirects(true);

		/* POSTデータの設定 */
		con.setRequestProperty("Content-Type", String.format("text/plain; boundary=%s", String.format("%x", new Random().hashCode())));
		con.setRequestProperty("Content-Length", String.valueOf(postStr.getBytes(encoding).length));

		/* データのPOST */
		dos = new DataOutputStream(con.getOutputStream());
		dos.writeBytes(postStr);

		/* 接続 */
		con.connect();

		/* レスポンスヘッダの獲得 */
		Map<String, List<String>> headers = con.getHeaderFields();
		StringBuilder sb = new StringBuilder();
		Iterator<String> it = headers.keySet().iterator();

		while (it.hasNext()) {
		    String key = (String) it.next();
		    sb.append("  " + key + ": " + headers.get(key) + "\n");
		}

		/* レスポンスコードとメッセージ */
		sb.append("RESPONSE CODE [" + con.getResponseCode() + "]\n");
		sb.append("RESPONSE MESSAGE [" + con.getResponseMessage() + "]\n");

		header = sb.toString();

		/* レスポンスボディの獲得 */
		BufferedReader reader = new BufferedReader(new InputStreamReader(con.getInputStream(), encoding));
		String line;
		sb = new StringBuilder();

		while ((line = reader.readLine()) != null) {
		    sb.append(line + "\n");
		}

		body = sb.toString();

		/* 接続終了 */
		reader.close();
		con.disconnect();
		if(dos != null){
			dos.flush();
			dos.close();
		}
    }
}

%>
<%
StringBuilder msg = new StringBuilder();
final String apiKey = "";

try{
/*-----投稿者名の取得-----*/
String user = request.getParameter("u");

/*-----ファイルアップロード機能の実装-----*/
/*未対応形式の場合の処理については後で実装します．*/
//アップロードされた画像ファイルを補完するパス
String uploadPath = getServletContext().getRealPath("/WEB-INF/upload")+"/";

Part part = request.getPart("file");
//ファイルの拡張子を取得する．
String fext = getFileExtension(part);
//ファイル名は現在時刻から決定する．
String filename = getTimeString();
//ファイルの書き込み(上限2MB)
part.write(uploadPath+filename+"."+fext);

//Base64エンコードの導出
String imageBase64 = getBase64ofImage(uploadPath+filename+"."+fext, fext);

/*-----APIサーバへの接続-----*/
//POST文字列の生成
StringBuilder postStr = new StringBuilder();
postStr.append("{");
postStr.append("\"requests\": [");
postStr.append("{");
postStr.append("\"image\": {");
postStr.append("\"content\":  \""+imageBase64+"\"");
postStr.append("},");
postStr.append("\"features\": [");
postStr.append("{");
postStr.append("\"type\": \"OBJECT_LOCALIZATION\"");
postStr.append("}");
postStr.append("]");
postStr.append("}");
postStr.append("]");
postStr.append("}");

APIAccess api = new APIAccess("https://vision.googleapis.com/v1/images:annotate?key="+apiKey, postStr.toString());

} catch(Exception e) {
	msg.append("\"ServiceInfo\": [");
	msg.append("{\"status\": \"error\"},");
	msg.append("{\"exception\": \""+e.getClass().getName()+"\"}");
	msg.append("]");
}
%>
<%= msg %>