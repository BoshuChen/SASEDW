/*巨集名稱:readingSchema                                                                                */
/*作        者: Andy                                                                                                      */
/*處理概要: 將指定Lib內的檔案欄位資訊放到指定TABLE                     */
/*輸    入:  LIB , TBL( table name to output)                                                  */
/*輸    出:  TBL                                                                                              */
/*其    他:                                                                                                         */
/*修    改:                                                                                                                    */
%MACRO DOC_LIBContentor( lib_name , TBL=out ) ;
	%LOCAL libonly;
	%LET libonly = ;
	%IF %kindex(%superq(lib_name) , %str(.) )  = 0 %THEN %DO ;
		%LET libonly = YES ;
	%END ;

        proc contents data=%if %superq(libonly) = YES %then &lib_name.._ALL_  ; %else &lib_name. ; 
                       	out=tmp noprint ; run ;
        proc sql ;
                create table &TBL. as 
                        select	            LIBNAME        , 
                                                MEMNAME        ,
                                                NAME    ,
                                                VARNUM        ,
                                                CASE WHEN TYPE = 1 THEN "NUM" 
                                                            WHEN TYPE = 2 THEN "CHAR"
                                                ELSE "?" END AS TYPE ,
                                                LENGTH ,
                                                LABEL,
                                                 CASE WHEN  MISSING( FORMAT )  =0  THEN TRIM( LEFT( FORMAT ) ) || LEFT( PUT(FORMATL,20.) )
                                                          ELSE "" END AS FORMAT_COM,
                                                CASE WHEN  MISSING( INFORMAT )  =0 THEN  TRIM( LEFT( INFORMAT ) ) || LEFT( PUT(INFORML,20.) )
                                                          ELSE "" END AS INFORMAT_COM,
                                               CRDATE ,
                                               MODATE 
                        from tmp
                        order by MEMNAME, VARNUM ;
        quit;
        proc sql ;
                drop table tmp;
        quit;
%MEND;
/* 範例說明 */
         /* 範例一: 將STAGE 內的 Table 資訊列出放到 STAGE_schema  
		libname DDS "/SASDATA2/DDS_USR" ;
                 %DOC_LIBContentor( DDS , TBL=STAGE_schema ) 
                 %DOC_LIBContentor( STAGE , TBL=STAGE_schema2 ) 
        */
        /*範例二: 將單一表格資訊列出
		libname stage "/SASDATA2/stage" ; 
                %DOC_LIBContentor( stage.life_insurance_claim ) 
        */
