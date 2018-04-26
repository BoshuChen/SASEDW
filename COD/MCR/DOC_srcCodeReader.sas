/*作        者: Andy                                                                                                                         */
/*處理概要: 專案文件製作，依照關鍵字擷取Source Code資料                                                     */
/*輸    入: fileRef: Source Code路徑                                                                                    
                , keyword: 滿足 sas prxparese 規格關鍵字
                , VARNAME: 存放結果的變數                                                                        
                , OUTDS : 存放結果的SASDATASET 預設: _NULL_                                                              */
/*輸    出:  VARNAME , 
                 , OUTDS : 存放結果的SASDATASET 預設: _NULL_                                                       */
/*相依核心: N/A         */

%MACRO DOC_srcCodeReader( fileRef /*source code path */ , 
                                     	keyword /*關鍵字*/, 
                                        VARNAME /*回傳存放變數，取用時用SUPERQ*/ ,
                                        OUTDS = _NULL_ /*回傳存放表格*/  ) ; 

        %LET fileRef = %QSYSFUNC( DEQUOTE( &fileRef. ) ) ; 
        %LET keyword = %QSYSFUNC( DEQUOTE( &keyword. ) ) ; 
        %LET VARNAME = %SYSFUNC( DEQUOTE( &VARNAME. ) ) ;
        %LET OUTDS = %SYSFUNC( DEQUOTE( &OUTDS. ) ) ;
   
        DATA &OUTDS. ( KEEP=Comments);
              /* Use PRXPARSE to compile the Perl regular expression.    */
             INFILE "&fileRef." DLM='01'x DSD TRUNCOVER LRECL=1000   ;
             LENGTH line $1000. ;
             INPUT line $ ; 
             LENGTH Comments $1000 ;
             RETAIN strPattern endPattern Comments strFlg ;
             IF _N_  = 1 THEN DO ; 
                        strPattern = prxparse("/\/\*.*&keyword./");
                        endPattern = prxparse("/.*\*\//");
                        strFlg = "0" ;
                        Comments = "" ;
             END ;
             positionStr=prxmatch(strPattern, line);
             IF positionStr > 0 THEN DO ; 
                        strFlg = "1" ;
             END;
             IF strFlg = "1" THEN DO ; 
                        Comments = KSTRIP(Comments) || KSTRIP( line ) ;
             END;
             positionEnd=prxmatch(endPattern, line);

             IF strFlg = "1" AND positionEnd > 0 THEN DO ; 
                        CALL SYMPUTX( RESOLVE( "&VARNAME.") , Comments ,"G" ) ;
                        OUTPUT ;
                        STOP;
             END;
             
        RUN;
        %LET &VARNAME. = %SUPERQ( &VARNAME. ) ;
%MEND ;
