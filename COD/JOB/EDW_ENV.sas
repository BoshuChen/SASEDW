/* 
�B�z���n: 	
         1. �M�׬[�c�]�w:�M�׮ڥؿ��P�M�׸��|���j�r��
 	 2. �M�׸���]�]�w 
         3. injection.xml(user defined settings) �פJ��EDWmeta Library
         4. �M�ų���Ϲ�����Ƨ��P�s�س���Ϲ�����Ƨ�
         5. �sĶ�M��Macro
*/ 
/*
1. �M�׬[�c�]�w:�M�׮ڥؿ��P�M�׸��|���j�r��
*/
%MACRO setRootPath() ;
	%LOCAL thisFilePath ;
	%LET thisFilePath = %SYSFUNC(dequote( %SYSFUNC(getoption(sysin))%SUPERQ(_SASPROGRAMFILE) ) ) ;
	%GLOBAL RootPath RootPathDlm;
        /*EDW_ENV.sas �Ҧb�ؿ�(JOB)*/
	%LET RootPath = %SUBSTR( %SUPERQ(thisFilePath) , 1 , %LENGTH(&thisFilePath.) - %LENGTH(%SCAN( %SUPERQ(thisFilePath) , -1 , %STR(/)%STR(\) ) ) ) ;
	%LET RootPathDlm = %SUBSTR( %sysfunc(reverse(%SUPERQ(RootPath))) , 1 , 1 ) ;
	%LET RootPath = %SUBSTR( %SUPERQ(thisFilePath) , 1 , %LENGTH(&thisFilePath.) - %LENGTH(%SCAN( %SUPERQ(thisFilePath) , -1 , %STR(/)%STR(\) ) ) - 1 ) ;
	/*EDW_ENV.sas �W�@�h�ؿ�(COD)*/	
	%LET RootPath = %SUBSTR( %SUPERQ(RootPath) , 1 , %LENGTH(&RootPath.) - %LENGTH(%SCAN( %SUPERQ(RootPath) , -1 , %STR(/)%STR(\) ) ) - 1 ) ;
	/*EDW_ENV.sas �W��h�ؿ�(TGLEDW)*/
	%LET RootPath = %SUBSTR( %SUPERQ(RootPath) , 1 , %LENGTH(&RootPath.) - %LENGTH(%SCAN( %SUPERQ(RootPath) , -1 , %STR(/)%STR(\) ) ) - 1 ) ;
%MEND;
%setRootPath
/*
2. �M�׸���]�]�w 
*/
LIBNAME BAKDDS "&RootPath.&RootPathDlm.BAK&RootPathDlm.DDS" ; 
LIBNAME BAKRPT "&RootPath.&RootPathDlm.BAK&RootPathDlm.RPT" ; 
LIBNAME BAKSRC "&RootPath.&RootPathDlm.BAK&RootPathDlm.SRC" ; 
LIBNAME LIBABT "&RootPath.&RootPathDlm.LIB&RootPathDlm.ABT" ; 
LIBNAME LIBDDS "&RootPath.&RootPathDlm.LIB&RootPathDlm.DDS" ; 
LIBNAME LIBPBT "&RootPath.&RootPathDlm.LIB&RootPathDlm.PBT" ; 
LIBNAME LIBSTG "&RootPath.&RootPathDlm.LIB&RootPathDlm.STG" ; 
/*
3. injection.xml(user defined settings) �פJ��EDWmeta Library
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
4. �M�ų���Ϲ�����Ƨ��P�s�س���Ϲ�����Ƨ�
*/
DATA RPT_GENERATOR;
	SET EDWmeta.RPT_GENERATOR;
	IF _N_ = 1 THEN envDlm =  symget( 'RootPathDlm') ;
	/* command which rm dir including subfolder  depends on system : window or unix like */
	IF envDlm = "\" THEN CALL SYSTEM( "rmdir /S /Q &RootPath.&RootPathDlm.RPT&RootPathDlm." || KSTRIP(DIR_NAME) ) ;
	ELSE CALL SYSTEM( "rm -rf &RootPath.&RootPathDlm.RPT&RootPathDlm." || KSTRIP(DIR_NAME) ) ;
	rc = DCREATE( KSTRIP(DIR_NAME) , "&RootPath.&RootPathDlm.RPT&RootPathDlm." );
RUN;
/*
5. �sĶ�M��Macro
*/
%include "&RootPath.&RootPathDlm.COD&RootPathDlm.MCR&RootPathDlm.UTL_findExec.sas" ;
%UTL_findExec( "&RootPath.&RootPathDlm.COD&RootPathDlm.MCR" , ext=sas , cmd_prefix=' %include "' ,cmd_suffix = '";'  )

/*
*�@�@�@�@�@�@�@�@�z�{�@�@�@�z�{+ +
*�@�@�@�@�@�@�@�z�}�r�w�w�w�}�r�{ + +
*�@�@�@�@�@�@�@�x�@�@�@�@�@�@�@�x �@
*�@�@�@�@�@�@�@�x�@�@�@�w�@�@�@�x ++ + + +
*�@�@�@�@�@�@ �i�i�i�i�w�i�i�i�i �x+                      ��d���O��!!!!!!!
*�@�@�@�@�@�@�@�x�@�@�@�@�@�@�@�x +
*�@�@�@�@�@�@�@�x�@�@�@�r�@�@�@�x
*�@�@�@�@�@�@�@�x�@�@�@�@�@�@�@�x + +
*�@�@�@�@�@�@�@�|�w�{�@�@�@�z�w�}
*�@�@�@�@�@�@�@�@�@�x�@�@�@�x�@�@�@�@�@�@�@�@�@�@�@
*�@�@�@�@�@�@�@�@�@�x�@�@�@�x + + + +
*�@�@�@�@�@�@�@�@�@�x�@�@�@�x�@�@�@�@�@�@�@�@�@�@�@
*�@�@�@�@�@�@�@�@�@�x�@�@�@�x + �@�@�@�@
*�@�@�@�@�@�@�@�@�@�x�@�@�@�x
*�@�@�@�@�@�@�@�@�@�x�@�@�@�x�@�@+�@�@�@�@�@�@�@�@�@
*�@�@�@�@�@�@�@�@�@�x�@ �@�@�|�w�w�w�{ + +
*�@�@�@�@�@�@�@�@�@�x �@�@�@�@�@�@�@�u�{
*�@�@�@�@�@�@�@�@�@�x �@�@�@�@�@�@�@�z�}
*�@�@�@�@�@�@�@�@�@�|�{�{�z�w�s�{�z�} + + + +
*�@�@�@�@�@�@�@�@�@�@�x�t�t�@�x�t�t
*�@�@�@�@�@�@�@�@�@�@�|�r�}�@�|�r�}+ + + +
*/
