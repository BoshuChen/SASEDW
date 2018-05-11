/*作        者: Andy                                                                                                                         */
/*處理概要: 遞迴尋找檔案並執行找到後的路徑作為參數執行 command                                                      */
/*輸    入: dir: 待處理檔案路徑                                                                                    
                , ext: 指定附檔名
                , cmd_prefix: 指令前綴
                , cmd_suffix : 指令後綴                                                              
        , dirDlm: 路徑分隔字元     */
/*輸    出:  無  */
/*相依核心: N/A         */
/* 備註: 參考 http://support.sas.com/kb/45/805.html 加以修改為較彈性的版本*/ 
%MACRO UTL_findExec( dir, ext=sas , cmd_prefix='%include "' , cmd_suffix = '"; '  , dirDlm = "/");                                                                                                                
    %LOCAL filrf rc did memcnt name i; 
    %LET dir = %QSYSFUNC(dequote( &dir. ) ) ; 
    %LET ext = %QSYSFUNC(dequote( &ext. ) ) ;
    %LET cmd_prefix = %QSYSFUNC(dequote( &cmd_prefix. ) ) ;
    %LET cmd_suffix = %QSYSFUNC(dequote( &cmd_suffix. ) ) ;
    %LET dirDlm = %QSYSFUNC(DEQUOTE( &dirDlm. ) ) ;
                                                                                                              
    /* Assigns a fileref to the directory and opens the directory */                                                           
    %LET rc=%SYSFUNC(filename(filrf,&dir.));                                                                                               
    %LET did=%SYSFUNC(dopen(&filrf.));                                                                                                     
                                                                                                                            
    /* Make sure directory can be open */                                                                                                 
    %IF &did eq 0 %THEN %DO;                                                                                                              
        %PUT ERROR: Directory &dir cannot be open or does not exist ;
        %RETURN;                                                                                                                             
    %END;                                                                                                                                 
                                                                                                                                    
    /* Loops through entire directory */                                                                                                 
    %DO i = 1 %TO %SYSFUNC(dnum(&did.));                                                                                                                                                                                                                                
        /* Retrieve name of each file */                                                                                                   
        %LET name=%QSYSFUNC(dread(&did.,&i.)) ; 
        %put &=name. ;
        %if "&name." = "UTL_findExec.sas" %then %goto continue ;
        /* Checks to see if the extension matches the parameter value */                                                                   
        /* If condition is true print the full name to the log        */                                                                   
        %IF %QUPCASE(%QSCAN(&name.,-1,.)) = %UPCASE(&ext.) %THEN 
            %DO;   
                %put &cmd_prefix.&dir.&dirDlm.&name.&cmd_suffix.  ;                                                                    
                %UNQUOTE( &cmd_prefix. )&dir.&dirDlm.&name.%UNQUOTE( &cmd_suffix. )                                                                                                    
            %END;                                                                                                                         
        /* If directory name call macro again */                                                                                           
        %ELSE %IF %QSCAN(&name.,2,.) = %THEN 
            %DO;                                                                                          
                %UTL_findExec(&dir.&dirDlm.%UNQUOTE(&name.), ext= &ext.) ;                                                                                              
            %END;      
        %continue:                                                                                        
    %END;                                                                                                                                
                                                                                                                                    
    /* Closes the directory and clear the fileref */                                                                                      
    %LET rc=%SYSFUNC(dclose(&did));                                                                                                       
    %LET rc=%SYSFUNC(filename(filrf));                                                                                                                            
%mend; 
/*範例說明:*/
    /*範例1: 編譯指定目錄下程式
        %UTL_findExec( "&RootPath./COD/MCR" , ext=sas , cmd_prefix=' %include "' ,cmd_suffix = '";'  )
    */

    /*範例2: 刪除檔案
        %MACRO deleteFile( filename ) ; 
            %LET filename = %sysfunc( dequote( &filename. ) ) ; 
            %local rc ; 
            %LET rc = %sysfunc(filename (fref , "&filename." ) ) ;
            %LET rc = %sysfunc( fdelete( &fref. ) ) ;
        %MEND ; 
        %UTL_findExec( "/tmp/test" , ext=txt , cmd_prefix=' %deleteFile( ' ,cmd_suffix = ' ) ; '  )
    */
