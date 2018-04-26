/*巨集名稱:SYS_fileDeleter                                                                                */
/*作        者: Andy                                                                                                      */
/*處理概要: 刪除指定檔案                    						*/
/*輸    入:  filename                                                					  */
/*輸    出:                                                                                                */
%MACRO SYS_fileDeleter( filename ) ; 
	%LET filename = %sysfunc( dequote( &filename. ) ) ; 
	%local rc ; 
	%LET rc = %sysfunc(filename (fref , "&filename." ) ) ;
	%LET rc = %sysfunc( fdelete( &fref. ) ) ;
%MEND ; 
/*範例說明:*/
	/*範例1: 
		%SYS_fileDeleter( "/tmp/test/a.txt" ) 
	*/
