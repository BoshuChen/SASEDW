/*作        者: Andy                                                                                                                        */
/*處理概要: 因應個人資料保護法以MD5 Function遮蔽敏感個資並留下還原LOG檔                      */
/*輸    入: Table2Mask: 要遮蔽個人資料的表格
                , Column2Mask :要遮蔽的個資欄位格式為pbuff ex: (col1 ,col2 , col3 ,.... )
                , LogTablePrefix: 遮蔽留存的Log DataSet名稱前綴
                 , LogDSName: 若Column2Mask 包含中文名稱需額外指定Column2Mask對應的英文名稱 */
/*輸    出: SAS 資料集: LogTablePrefix_LogDSName                                                                       */
/*相依核心: N/A                                                                                                                          */
%MACRO UTL_SHAMasker( Table2Mask     /* 要遮蔽個人資料的表格 */ , 
	                                  Column2Mask  /* 要遮蔽的個資欄位 */         , 
					  SHA=MD5 ,
					  SHAFormat="$hex32." ,
	                                  LogTablePrefix=SHALog        /* 遮蔽留存的Log DataSet 名稱為 LogTablePrefix_Column2Mask  */ ,
	                                  LogDSName= ) ;

        %LOCAL i  MaskCnt MaskPbuff UUID ;
        %LET UUID = &SYSJOBID._&SYSINDEX. ;
	%LET MaskPbuff = %QKSUBSTR( %SUPERQ( Column2Mask ) , 2 , %KLENGTH( &Column2Mask. )  -2  ) ;
	%LET MaskCnt = 0  ;
	%DO %WHILE (%QKSCAN( %SUPERQ( MaskPbuff ) , &MaskCnt. + 1  , %STR(,) ) ^= );
		%LET MaskCnt = %EVAL( &MaskCnt. + 1 ) ; 
		%LET Mask&MaskCnt. = %KSCAN( %SUPERQ( MaskPbuff ) , &MaskCnt. , %STR(,) ) ;
	%END;
	%LET SHAFormat = %SYSFUNC(DEQUOTE( &SHAFormat. ) ) ; 
        
        %LOCAL LogDSNameCnt ;
        %IF %sysevalf(%superq( LogDSName )=,boolean) %THEN %DO;
                %LET LogDSNameCnt = &MaskCnt. ;
                 %DO i = 1 %TO &LogDSNameCnt.;
                        %LOCAL LogDSName&i. ; 
                        %LET LogDSName&i. = &&Mask&i. ;
                        %END;
                %END;
        %ELSE %DO ;
                %LET LogColumnPbuff = %QSYSFUNC( KSTRIP( %QSUBSTR( &LogDSName. ,2 ,%EVAL( %LENGTH( &LogDSName. ) -2 ) ) ) );
                %LET LogDSNameCnt = %EVAL( %SYSFUNC( KLENGTH( &LogColumnPbuff. ) ) - %SYSFUNC( KLENGTH( %SYSFUNC( KCOMPRESS( &LogColumnPbuff. ,%str(,) ) ) ) ) + 1 )  ;
                %DO i = 1 %TO &LogDSNameCnt.;
                        %LOCAL LogDSName&i. ; 
                        %LET LogDSName&i. = %SYSFUNC(KSTRIP( %QSYSFUNC( KSCAN( &LogColumnPbuff. , &i. , %str(,) ) ) ) );
                        %END;
                %END;

        proc datasets lib=work nolist ;
                delete &SHA._&UUID. ;
                append base=&SHA._&UUID. data=&Table2Mask. ;
        run;

        %DO i = 1 %TO &MaskCnt. ;
                proc sql ;
                        create table %KCMPRES(&LogTablePrefix.)_%KCMPRES(%UNQUOTE(%NRSTR(&)LogDSName&i.))  as 
                                select    distinct 
                                                %UNQUOTE( %NRSTR(&)Mask&i.) ,
                                                putc( &SHA.( %UNQUOTE( %NRSTR(&)Mask&i.) ) , "&SHAFormat." )  as  %KCMPRES(%UNQUOTE(%NRSTR(&)LogDSName&i.))_hash 
                                from &SHA._&UUID. ;
                quit;
        %END;

        proc sql  ;
                create table &Table2Mask.  ( DROP= %DO i = 1 %TO &maskCnt. ;
                                                                        %KCMPRES(%UNQUOTE(%NRSTR(&)Mask&i.))_drop  %str( )
                                                                %END ;  ) AS 
                        select        %DO i = 1 %TO &maskCnt. ;
                                putc( &SHA.( %KCMPRES(%UNQUOTE(%NRSTR(&)Mask&i.))_drop ) , "&SHAFormat." ) as &&Mask&i. ,
                        %END;
                        %unquote( %str(*) ) 
                        from &SHA._&UUID. ( RENAME=( %DO i = 1 %TO &maskCnt. ;
                                                                                     %UNQUOTE( %NRSTR(&)Mask&i.) = %KCMPRES(%UNQUOTE(%NRSTR(&)Mask&i.))_drop %str( )
                                                                           %END ;
                                                                        ) 
                                                        )
                        ;
        quit ;

        proc datasets lib=WORK NOLIST ;
                delete &SHA._&UUID. ;
        run;

%MEND; 

/*範例說明*/
      /*範例一: 遮蔽敏感資料
                DATA personalInfoAA ; 
                        ID = "A1"  ; NAME = "王大明" ;OUTPUT ; 
                RUN ; 
		options mprint ;
                %UTL_SHAMasker( personalInfoAA    , 
		                                  ( ID ,NAME)     , 
		                                  LogTablePrefix=MD5Log        ) ;
        */ 
