/*巨集名稱:FuzzyMatcher                                                                                */
/*作        者: Andy                                                                                            */
/*處理概要: 指定關鍵字跟對應要搜尋的欄位給出相似度分數                  */
/*輸    入:  keywords : (keyWord1 ,keyWord2 ,keyWord3 , ..., keyWordn)
                 DS: 資料字典
		 VAR:對應欄位
                 disVarName: 使用時指定相似度分數的欄位名稱                        
                 DisMethod:  使用時指定計算方法  COMPGED SPEDIS COMPLEV COMPARE
                 OUT: 產出資料集
                  CNT: 筆數限制 */
/*輸    出:  OUT: 產出資料集                                                                                              */
%MACRO DOC_FuzzyMatcher( keywords /*多個關鍵字，逗號分隔*/, 
                                       DS /*資料字典*/ , 
                                       VAR /*關鍵字對應欄位*/  ,
                                       disVarName=probability /*相似度欄位名稱*/  ,
                                       DisMethod = COMPGED /*計算方法  COMPGED SPEDIS COMPLEV COMPARE */ , 
                                       OUT=   /*產出資料集*/ ,
                                       CNT=  ) ;
	%LOCAL UUID keywordsCnt i ;
	%LET UUID = &SYSJOBID._&SYSINDEX. ; /*execute_id*/
	/*計算陣列維度*/ 
	%LET keywordsCnt = 0 ;
	/*去頭去尾*/
	%LET keywords = %KSUBSTR( %SUPERQ(keywords) , 2 , %KLENGTH( %SUPERQ( keywords) ) - 2  ) ;
	%DO %WHILE ( %QKSCAN( %SUPERQ( keywords ) , &keywordsCnt. + 1 , %STR(,) ) ^= );
		%LET keywordsCnt = %EVAL( &keywordsCnt. + 1 ) ;
		%LOCAL m_&UUID._&keywordsCnt. ;
		%LET m_&UUID._&keywordsCnt. = %KSCAN( %SUPERQ( keywords ) , &keywordsCnt. , %STR(,) ) ;
	%END ;
	%PUT _LOCAL_ ; 
	%IF %SYSEVALF(%SUPERQ(OUT) = ) %THEN %DO ; 
		%LET OUT = O_&UUID. ;
	%END;
	data T_&UUID.  (drop= c_&UUID.:  i);
		set &DS. ; 
		c_&UUID. = upcase( kcompress(  &VAR. , " _,|" ) ) ;
		&disVarName. = 0 ; 
		c_&UUID._lenSum = 0 ;
		%DO i = 1 %TO &keywordsCnt. ; 
			c_&UUID._len = %KLENGTH( &&m_&UUID._&i. ) ; /*關鍵字長度*/
			c_&UUID._lenSum = c_&UUID._lenSum + c_&UUID._len ; /* 關鍵字長度總和*/
			c_&UUID._dis = &DisMethod.( "%upcase(%sysfunc(kcompress( &&m_&UUID._&i.  , %str(_,|) ) ))" , c_&UUID.)  ;
			&disVarName. = &disVarName. + 1/( c_&UUID._dis + 1)  ;
		%END;
		&disVarName. = &disVarName. / &keywordsCnt.   ;
	run ; 
	proc sql  %IF %SYSEVALF(%SUPERQ(CNT) ^= ) %THEN outobs = &CNT.; ;
		create table &OUT. as 
			select * 
			from T_&UUID.
			order by &disVarName. desc 
			;
		drop table T_&UUID. ;
	quit; 
	
%MEND; 
/*範例說明*/
	/*範例一:
	data abc ; 
		format desc xx yy ;  
		length desc $100 ;
		desc = "policy_no" ; xx = "no1" ; yy = 1 ;  output ;
		desc = "po_no" ; xx = "no2" ; yy = 2 ;  output ;
		desc = "no_no" ; xx = "no3" ; yy = 3 ;  output ;
		desc = "acct_no" ; xx = "no4" ; yy = 4 ;  output ;
		desc = "policy_chg_no" ; xx = "no5" ; yy = 5 ;  output ;
	run ; 
	%DOC_FuzzyMatcher( (  policy , no ,po  ) , abc , desc ) ;
*/
/*範例二:
	libname edwstg "/SASDATA/USER/TGLEDW/LIB/STG" ;
	%DOC_FuzzyMatcher( (  policy , id  ) , edwstg.ebao_data_dictionary_field , COLUMN_NAME) ;
*/
