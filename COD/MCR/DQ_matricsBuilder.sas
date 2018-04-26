/*作        者: Andy                                                                                                                         */
/*處理概要: 資料分群後計算統計量，並指定一個變數展開成統計量矩陣                          */
/*輸    入:  DSNAME: 要轉換的DataSet
		 BYVAR: 分群變數
		 IDVAR: 要轉置的變數(變數值會變成欄位名稱)
                 PREFIX: 變數前綴名稱
                 SUFFIX: 變數後綴名稱
		 OUT : 轉換後結果 
                  AGGREGATE: 統計量 */
/*輸    出:  N/A                                                                                                                                  */
/*相依核心: N/A                                                                                                                           */
%MACRO DQ_matricsBuilder( DSNAME , 
						 BYVAR/*variable to group by (var1, var2, ... ,varn) */ , 
						  IDVAR /* variable to expand to columns */ , 
						  PREFIX= /* idvar 前綴名稱 */,
                                                  SUFFIX= /* idvar 後綴名稱 */ ,
						  OUT=%scan( &DSNAME. , -1  , %str(.) )_&SYSJOBID.&SYSINDEX. /*Result DataSet*/ ,
						  AGGREGATE=count(*) ) ; 
	%LOCAL TAB UUID BYVAR_SPACE BYVAR_COMMA ;
	%LET TAB = %scan( &DSNAME. , -1  , %str(.) ) ;
	%LET UUID = &SYSJOBID.&SYSINDEX. ;
	%LET BYVAR_COMMA = %KSUBSTR( %SUPERQ(BYVAR) , 2 , %KLENGTH( %SUPERQ(BYVAR) ) - 2 ) ;
	%LET BYVAR_SPACE = %SYSFUNC(TRANWRD( &BYVAR_COMMA. , %STR(,) ,%STR( ) ) ) ;

	proc sql ; 
	create table &TAB._&UUID. as 
		select &BYVAR_COMMA. , ifc( missing(&IDVAR.) , "MISSING" , &IDVAR. ) as &IDVAR.  , &AGGREGATE. as statistic
		from &DSNAME. 
		group by &BYVAR_COMMA. , &IDVAR.
	;
	quit ; 
	proc sort data=&TAB._&UUID. ; by &BYVAR_SPACE. ; run ;
	proc transpose data=&TAB._&UUID. out=&OUT.(drop=_name_)  
                              %IF %SYSEVALF(%SUPERQ(PREFIX) ^= ,BOOLEAN) %THEN PREFIX=&PREFIX. ; 
                              %IF %SYSEVALF(%SUPERQ(SUFFIX) ^= ,BOOLEAN) %THEN SUFFIX=&SUFFIX. ;
                ;
		by &BYVAR_SPACE. ;
		id &IDVAR. ;
		var statistic ;
	run ;
	proc sql ; 
		drop table &TAB._&UUID. ; 
	quit ;
%MEND; 
/*範例說明*/
	/*範例一:
                data test;
			index_group = "COMPLETENESS .." ; index_name="missingCnt "; index_value = 20;  phase = "STG" ; output;
			index_group = "UNIQUENESS" ; index_name="pkey"; index_value = 1;  phase = "STG" ; output;
			index_group = "UNIQUENESS" ; index_name="UK"; index_value = 3;  phase = "STG" ; output;
			index_group = "VALIDITY" ; index_name="prem "; index_value = 50;  phase = "STG" ; output;
			index_group = "COMPLETENESS .." ; index_name="missingCnt "; index_value = 120;  phase = "DDS" ; output;
			index_group = "UNIQUENESS" ; index_name="pkey"; index_value = 11;  phase = "DDS" ; output;
			index_group = "UNIQUENESS" ; index_name="UK"; index_value = 13;  phase = "DDS" ; output;
			index_group = "VALIDITY" ; index_name="prem "; index_value = 150;  phase = "DDS" ; output;
		run;
		%DQ_matricsBuilder( test , (index_group ) , phase ,out= tt ,PREFIX= phase_  , AGGREGATE=sum(index_value) ) 
	*/
	/*範例二:
                data test;
			index_group = "COMPLETENESS .." ; index_name="missingCnt "; index_value = 20;  phase = "STG" ; output;
			index_group = "UNIQUENESS" ; index_name="pkey"; index_value = 1;  phase = "STG" ; output;
			index_group = "UNIQUENESS" ; index_name="UK"; index_value = 3;  phase = "STG" ; output;
			index_group = "VALIDITY" ; index_name="prem "; index_value = 50;  phase = "STG" ; output;
			index_group = "COMPLETENESS .." ; index_name="missingCnt "; index_value = 120;  phase = "DDS" ; output;
			index_group = "UNIQUENESS" ; index_name="pkey"; index_value = 11;  phase = "DDS" ; output;
			index_group = "UNIQUENESS" ; index_name="UK"; index_value = 13;  phase = "DDS" ; output;
			index_group = "VALIDITY" ; index_name="prem "; index_value = 150;  phase = "DDS" ; output;
		run;
		%DQ_matricsBuilder( test , (index_group ) , phase ,out= tt ,PREFIX= phase_   ) 
	*/

