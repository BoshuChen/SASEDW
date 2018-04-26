/*作        者: Andy                                                                                                                         */
/*處理概要: 將IN_TBL對DW_TBL進行SCD Type 2 轉換                                                          */
/*輸    入: IN_TBL: 本次資料                                                                                   
                , DW_TBL: 歷程資料
                ,checkSum: checkSum欄位，未寫以IN_TBL所有欄位做SHA轉換
                , index: 建立INDEX                                                        
                , sha: checkSum方法
		,  sha_format: checkSum Format
                , tran_dttm: 交易時間                                                                               		    
		, valid_to_dttm: 最大有效時間                                                                                     */
/*輸    出:  PDF                                                                                                                                  */
/*相依核心: N/A                                                                                                                           */
%MACRO SCD_type2Loader( IN_TBL , /* new snap shot data (STAGE) */
			                         DW_TBL , /* dataware house data (Detail Data Store ) */
			                         checkSum = , /* default all IN_TBL fields to create checkSum*/
			                         index= , /* optional */
			                         sha=sha256 , /* checkSum algorithm */
			                         sha_format=HEX64. , /* checkSum put format */
			                         tran_dttm= %SYSFUNC( int( ( %SYSFUNC( datetime() ) ) ) ) , /* transaction datetime default current datetime */
			                         valid_to_dttm="01JAN5999 00:00:00"dt ) ; /* maximum datatime in system */
        /* NOTE: DW_TBL will create two fields (valid_from_dttm valid_to_dttm ) after loading into DW_TBL */
        %LOCAL valid_from_dttm ;
        %LET valid_from_dttm = &tran_dttm. ; 

    /* get table name to make an identifier for preventing error */
        %LOCAL identifier ; 
        %LET identifier = %sysfunc(scan(&DW_TBL. , -1 , %str(.) ) ) ;
        %LOCAL IN_identifier ; 
        %LET IN_identifier = %sysfunc(scan(&IN_TBL. , -1 , %str(.) ) ) ;

	%PUT  NOTE:staring scd type 2 loading process , in  table  = &IN_TBL.  , out table = &DW_TBL.  ;
	%PUT NOTE:checkSum = &checkSum. index = &index. ;
	%PUT NOTE:tran_dttm = &tran_dttm.  valid_to_dttm = &valid_to_dttm.  ;

    /* if DW_TBL is not exist , it does an initial load */ 
        %IF %SYSFUNC( exist(&DW_TBL.) ) EQ 0 %THEN %DO;
		%PUT NOTE:Building Initial load .... ;
		data &DW_TBL. ;
			format VALID_FROM_DTTM  NLDATM19. ; 
			format VALID_TO_DTTM NLDATM19. ;
			set &IN_TBL. ;
			array CHR(*) _CHARACTER_ ;
			do i = 1 to DIM(CHR) ; 
				CHR(i) = kstrip( CHR(i) ) ; 
			end ;
			drop i  ;
			VALID_FROM_DTTM = &valid_from_dttm.  ;
			VALID_TO_DTTM = &valid_to_dttm. ;
		run ; %IF &syserr. gt 6 %THEN %ABORT cancel ;
		%RETURN ;
	%END;

	%IF %SYSEVALF(%SUPERQ(checkSum)=,boolean)  %THEN %DO ;
		proc contents data=&IN_TBL. out=WORK.&identifier._chkSum(KEEP=NAME) nodetails noprint ; run; 
		proc sql noprint ; 
			select * 
			into: &identifier._chkSum_list separated by ',' 
			from &identifier._chkSum
			;
		quit ; 
		%LET checkSum = (&&&identifier._chkSum_list ) ; 
	%END ;
    
    /*define checkSum by removing left and right parentheses*/
	%LOCAL chkSum ;
	%LET chkSum = %qsysfunc(kcompress( &checkSum. , "()") ) ; 
    
    /* NOTE:seperate history and last snap shot in DW_TBL and strip unprintable character */
    	data WORK.&identifier._cur
	WORK.&identifier._his(drop = checkSum)  ;
		set &DW_TBL. ;
		array CHR(*) _CHARACTER_ ;
		do i = 1 to dim(CHR) ; 
			CHR(i) = kstrip( CHR(i) ) ; 
		end ;
		drop i  ;
		checkSum =  putc( &sha.(catx("|" , &chkSum. )) , "&sha_format.");
		if valid_from_dttm <= &tran_dttm. and valid_to_dttm >= &tran_dttm. then output WORK.&identifier._cur ;
		else output  WORK.&identifier._his ;
	run;%IF &syserr. gt 6 %THEN %ABORT cancel ;
    
	proc sort data = WORK.&identifier._cur nodupkey out=WORK.&identifier._cur(index=(checkSum)) ;
		by checkSum ;
	run;%IF &syserr. gt 6 %THEN %ABORT cancel ;
    
	%PUT NOTE:extrating and sorting come in table ;

    /* generate IN_TBL's checkSum and strip unprintable character */
	data &IN_identifier._tmp ;
		set &IN_TBL. ;
		array NUM{*} _NUMERIC_ ;
		array CHR{*} _CHARACTER_ ;
		do i = 1 to dim(CHR) ; 
			CHR(i) = kstrip( CHR(i) ) ; 
		end ;
		drop i ;
		checkSum =  putc( &sha.(catx("|" , &chkSum. )) , "&sha_format.");
	run ; %IF &syserr. gt 6 %THEN %ABORT cancel ;
	proc sort data=&IN_identifier._tmp nodupkey out=&IN_identifier._tmp(index=(checkSum)) ;
		by checkSum ;
	run ; %IF &syserr. gt 6 %THEN %ABORT cancel ;

	%PUT NOTE:merge by checkSum processing ... ;
	data WORK.&identifier._merge(drop=checkSum);
		FORMAT valid_from_dttm NLDATM19. ;
		FORMAT valid_to_dttm NLDATM19. ;
		merge &IN_identifier._tmp( in= Coming )  WORK.&identifier._cur( in= haveExist) ;
		by checkSum ;
		if not Coming and haveExist then do ;
			valid_to_dttm = %SYSEVALF( &valid_from_dttm. - 1 ) ;
		end ;
		if not haveExist and Coming then do;
			valid_from_dttm = &valid_from_dttm. ;
			valid_to_dttm = &valid_to_dttm. ;
		end  ;
	run ; %IF &syserr. gt 6 %THEN %ABORT cancel ;

	%PUT NOTE:Appending data processing .... ;
	data &DW_TBL. ;
		if 0 then set WORK.&identifier._his;
		stop ; 
	run  ; %IF &syserr. gt 6 %THEN %ABORT cancel ;
	proc append base=&DW_TBL. data= WORK.&identifier._his; run ; %IF &syserr. gt 6 %THEN %ABORT cancel ;
	proc append base=&DW_TBL. data= WORK.&identifier._merge; run ; %IF &syserr. gt 6 %THEN %ABORT cancel ;

    /* sort and create index*/
	%IF %SYSEVALF(%SUPERQ(index)=,boolean) EQ 0 %THEN %DO ;
		%LET index = %qsysfunc(kcompress( &index. , "()") ) ; 
		/* check index is single or composite */
		%IF %sysfunc(FIND( &index. , %str(,) ) ) EQ 0 %THEN %DO ; 
			proc sort data=&DW_TBL. out=&DW_TBL.( index=(&index.) ) ;
				by &index. ; 
			run ;
		%END ;
		%ELSE %DO ;
			proc sort data=&DW_TBL. out=&DW_TBL(index=( &identifier._idx=( %SYSFUNC(tranwrd(&INDEX. , %STR(,) , %STR( ) )) ) )) ;
				by %SYSFUNC(tranwrd(&INDEX. , %STR(,) , %STR( ) )) ;
			run ;
		%END ;
	%END ;

    /*kill temp file*/
	proc datasets lib=WORK nolist ;
		delete &identifier._: ;
		delete &IN_identifier._tmp ;
	run; %IF &syserr. gt 6 %THEN %ABORT cancel ;
    
%MEND;
/*範例說明*/
      /*範例一: 
		proc datasets lib =work nolist nowarn; 
			delete dds_t ;
		quit ; 
                DATA t1 ; 
                        ID = "A1"  ; NAME = "王大明" ;OUTPUT ; 
                RUN ; 
		%SCD_type2Loader( t1 , dds_t ) 
		 DATA t2 ; 
                        ID = "A1"  ; NAME = "王大明" ;OUTPUT ; 
			ID = "A2"  ; NAME = "王小明" ;OUTPUT ; 
                RUN ; 
		%SCD_type2Loader( t2 , dds_t ) 
		DATA t3 ; 
                        ID = "A1"  ; NAME = "王A明" ;OUTPUT ; 
			ID = "A2"  ; NAME = "王小明" ;OUTPUT ; 
                RUN ; 
		%SCD_type2Loader( t3 , dds_t )  
        */ 
