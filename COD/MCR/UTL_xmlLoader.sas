/*作        者: Andy                                                                                                                         */
/*處理概要: 將XML資料匯入LIB，並將GLOBAL屬性資料匯入MACRO變數                     */
/*輸    入:  LIBNAME: 指定資料館名稱
                  xmlSrc: XML 實體路徑                                                                                               */
/*輸    出:  LIB , MACRO VARIALBES   */
/*相依核心:                                                                                                                                 */
%MACRO UTL_xmlLoader( LIBNAME , xmlSrc ) ; 
	libname &LIBNAME. xml "%sysfunc(dequote( &xmlSrc. ))" ; 
	data _null_ ;
		set &LIBNAME..GLOBAL ;
		array char{*} _character_ ;
		array num{*} _numeric_ ;
		length vnames $200. ; 
		do i = 1 to dim(num) ;
			vnames = vname(num{i}) ;
			CALL EXECUTE( '%LET %UNQUOTE(' || vnames || ') = %UNQUOTE( ' || num{i} || ' ) ;' ) ;
		end ;
		do i = 1 to dim(char) ;
			vnames = vname(char{i}) ;
			CALL EXECUTE( '%LET %UNQUOTE(' || vnames || ') = %UNQUOTE( ' || KSTRIP(char{i})  || ' ) ;' ) ;
		end ;
	run ; 
%MEND ;
/*範例說明*/
	/*範例一: 將/SASDATA/USER/TGLEDW/test.xml 匯入 EDW 
		test.xml 內容如下:
		<?xml version="1.0" encoding="UTF-8" ?>
		<root>
		  <GLOBAL>
			<name>test</name>
			<tt>test2</tt>
			<tt2>2</tt2>
			<tt3>2017/01/02</tt3>
			<tm_proc>%sysfunc(datetime())</tm_proc>
			<tm_valid>%SYSFUNC( INTNX( dtDay , %SYSFUNC( DATETIME()) , -1 , E ) )</tm_valid>
		  </GLOBAL>
		  <data>
		    <id>1</id>
		    <name>Andy</name>
		    <score>100</score>
		  </data>
		  <data>
		    <id>2</id>
		    <name>Bandy</name>
		    <score>90</score>
		  </data>
		  <data>
		    <id>3</id>
		    <name>Amy</name>
		    <score>10</score>
		  </data>
		</root>
		%UTL_xmlLoader( EDW , "/SASDATA/USER/TGLEDW/test.xml" ) 
	*/




