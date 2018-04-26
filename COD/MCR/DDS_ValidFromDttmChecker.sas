/*巨集名稱:DDS_ValidFromDttmChecker                                                                  */
/*作        者: Andy                                                                                                      */
/*處理概要: DDS 根據群組驗證最後更新時間                   				     */
/*輸    入:  LIB:DDS資料館名稱
                  group: 群組欄位( col1 , col2 , col3 , ... , coln)
                  validDttm: 驗證時間欄位名稱
                  LIBPath: 宣告LIB實體位置
                  testCnt: 限制測試筆數
                  noclear: 預設清空工作檔，給定值不清除
                   */
/*輸    出:  報表                                                                                                       */
%MACRO DDS_ValidFromDttmChecker( LIB , group , validDttm=valid_from_dttm , LIBPath= , testCnt= ,noclear= , OUT=&LIB._checkOut  ) ;
	%LOCAL group_commaDlm UUID group_spaceDlm; 
	%LET UUID = &SYSJOBID._&SYSINDEX. ;
	%PUT NOTE: this call UUID = &UUID. ; 
	%LET group_commaDlm = %ksubstr( %superq(group) , 2 , %klength( &group. ) - 2 ) ;
	%LET group_spaceDlm = %sysfunc(tranwrd( %SUPERQ(group_commaDlm) , %str(,) , %str( ) ) ) ;
	%LOCAL group_quoteAndCommaDlm i subStr;
	%LET i = 0 ; 
	%LET group_quoteAndCommaDlm = ; 
	%DO %WHILE ( %QKSCAN( %SUPERQ( group_commaDlm ) , &i. + 1 , %STR(,) ) ^= ) ;
		%LET subStr = %STR(%")%CMPRES(%KSCAN( %SUPERQ( group_commaDlm ) , &i. + 1  , %STR(,) ))%STR(%") ;
		%IF &i. = 0 %THEN %LET group_quoteAndCommaDlm =  &subStr. ;
		%ELSE %LET group_quoteAndCommaDlm = &group_quoteAndCommaDlm. %str(,) &subStr. ;
		%LET i = %sysevalf( &i. + 1 ) ; 
	%END;
	%PUT NOTE: &=group_quoteAndCommaDlm. ;
	%IF %SYSEVALF( %SUPERQ(LIBPath) ^= ) %THEN %DO ;
		libname &LIB. "%SYSFUNC(DEQUOTE( &LIBPath. ) ) " ; 
		%PUT NOTE: &LIB. is assign to &LIBPath. ;  
	%END; 
	proc contents data=&LIB.._all_ out= T&UUID._A nodetails noprint  ; run ; 
	proc sql noprint ; 
		create table T&UUID._B0 as 
			select distinct MEMNAME  as tblname 
			from T&UUID._A
			where UPCASE(NAME) in ( %upcase( &group_quoteAndCommaDlm.) ) 
			;
		create table T&UUID._B1 as 
			select distinct MEMNAME  as tblname 
			from T&UUID._A
			where UPCASE(NAME) = %upcase( "&validDttm.")  
			;
		create table T&UUID._B as 
			select distinct a.tblname 
			from T&UUID._B0 as a  inner join T&UUID._B1 as b on (a.tblname = b.tblname ) 
			;
	quit;
	data T&UUID._C ; 
		set T&UUID._B ; 
		if _N_ = 1 then do ; 
			call execute( " data &OUT. ;  if 0 then do ; length tblname $32 ; set &LIB.." ||kstrip(tblname) || "( KEEP= &group_spaceDlm. ) ; format &validDttm.  nldatm19.   ; end ; stop ; run ; " ) ;
		end ; 
		call execute( " proc sql ;  insert into &OUT.  select  '" || kstrip(tblname) || "' as tblname , &group_commaDlm.  , 
                                      max( &validDttm. ) AS &validDttm. format = nldatm19. from &LIB.." 
                                      || kstrip(tblname) || " group by &group_commaDlm. ; quit ; " ) ;
		%if %sysevalf( %superq( testCnt ) ^= ) %then %do ; 
			if _N_ = &testCnt. then stop ; 
		%end;
	run ;
	PROC PRINT DATA= &OUT. ; RUN ; 
	%IF %SYSEVALF( %SUPERQ( noclear ) = ) %THEN %DO ; 
		PROC DATASETS LIB=WORK nolist nodetails ; 
			DELETE T&UUID.: ; 
		RUN ; 
	%END;  
%MEND ;
/*範例說明*/
/*  範例一: 驗證 AMLDDS 內表格，各來源最後資料異動時間
	%DDS_ValidFromDttmChecker( amldds , group= ( source_system  )  , validDttm=valid_from_dttm , LIBPath= "/SASDATA2/AMLLIB/DDS" , noclear=yes  );
*/
 
