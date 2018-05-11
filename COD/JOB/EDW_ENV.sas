/* 
處理概要: 	
         1. 專案架構設定:專案根目錄與專案路徑分隔字元
 	 2. 專案資料館設定 
         3. injection.xml(user defined settings) 匯入為EDWmeta Library
         4. 清空報表區對應資料夾與新建報表區對應資料夾
         5. 編譯專案Macro
*/ 
/*
1. 專案架構設定:專案根目錄與專案路徑分隔字元
*/
%MACRO setRootPath() ;
	%LOCAL thisFilePath ;
	%LET thisFilePath = %SYSFUNC(dequote( %SYSFUNC(getoption(sysin))%SUPERQ(_SASPROGRAMFILE) ) ) ;
	%GLOBAL RootPath RootPathDlm;
        /*EDW_ENV.sas 所在目錄(JOB)*/
	%LET RootPath = %SUBSTR( %SUPERQ(thisFilePath) , 1 , %LENGTH(&thisFilePath.) - %LENGTH(%SCAN( %SUPERQ(thisFilePath) , -1 , %STR(/)%STR(\) ) ) ) ;
	%LET RootPathDlm = %SUBSTR( %sysfunc(reverse(%SUPERQ(RootPath))) , 1 , 1 ) ;
	%LET RootPath = %SUBSTR( %SUPERQ(thisFilePath) , 1 , %LENGTH(&thisFilePath.) - %LENGTH(%SCAN( %SUPERQ(thisFilePath) , -1 , %STR(/)%STR(\) ) ) - 1 ) ;
	/*EDW_ENV.sas 上一層目錄(COD)*/	
	%LET RootPath = %SUBSTR( %SUPERQ(RootPath) , 1 , %LENGTH(&RootPath.) - %LENGTH(%SCAN( %SUPERQ(RootPath) , -1 , %STR(/)%STR(\) ) ) - 1 ) ;
	/*EDW_ENV.sas 上兩層目錄(TGLEDW)*/
	%LET RootPath = %SUBSTR( %SUPERQ(RootPath) , 1 , %LENGTH(&RootPath.) - %LENGTH(%SCAN( %SUPERQ(RootPath) , -1 , %STR(/)%STR(\) ) ) - 1 ) ;
%MEND;
%setRootPath
/*
2. 專案資料館設定 
*/
LIBNAME BAKDDS "&RootPath.&RootPathDlm.BAK&RootPathDlm.DDS" ; 
LIBNAME BAKRPT "&RootPath.&RootPathDlm.BAK&RootPathDlm.RPT" ; 
LIBNAME BAKSRC "&RootPath.&RootPathDlm.BAK&RootPathDlm.SRC" ; 
LIBNAME LIBABT "&RootPath.&RootPathDlm.LIB&RootPathDlm.ABT" ; 
LIBNAME LIBDDS "&RootPath.&RootPathDlm.LIB&RootPathDlm.DDS" ; 
LIBNAME LIBPBT "&RootPath.&RootPathDlm.LIB&RootPathDlm.PBT" ; 
LIBNAME LIBSTG "&RootPath.&RootPathDlm.LIB&RootPathDlm.STG" ; 

/*
3. 匯入專案設定檔
*/
LIBNAME EDWmeta XML "&RootPath.&RootPathDlm.injection.xml" ; 
DATA GLOBAL ; 
	SET EDWmeta.GLOBAL ; 
	ARRAY char{*} _CHARACTER_ ;
	ARRAY num{*} _NUMERIC_ ;
	DO i = 1 TO dim(num) ;
		CALL EXECUTE( '%LET %UNQUOTE(' ||  kstrip(vname(num{i}) ) || ') = %UNQUOTE( ' || KSTRIP(num{i})  || ' ) ;' ) ;
	END ;
	DO i = 1 TO dim(char) ;
		CALL EXECUTE( '%LET %UNQUOTE(' ||  kstrip(vname(char{i}) ) || ') = %UNQUOTE( ' || KSTRIP(char{i})  || ' ) ;' ) ;
	END ;
RUN ;
/*
4. oracle db libname construct 
*/
DATA ORACLE ; 
	SET EDWmeta.ENV_ORACLE ; 
	CALL EXECUTE( ' LIBNAME ' || KSTRIP(lib_name) ||
                                       ' oracle path = ' || KSTRIP(path) || 
                                       ' schema = ' || KSTRIP(layout) || 
                                       ' user = ' || KSTRIP(user) || 
				       ' password = "' || KSTRIP(password) || '" ; ' ) ;
RUN ;

/*
5. 編譯專案Macro
*/
%include "&RootPath.&RootPathDlm.COD&RootPathDlm.MCR&RootPathDlm.UTL_findExec.sas" ;
%UTL_findExec( "&RootPath.&RootPathDlm.COD&RootPathDlm.MCR" , ext=sas , cmd_prefix=' %include "' ,cmd_suffix = '";'  )

/*
6. 建立 Oracle DB LIBRARY
*/

