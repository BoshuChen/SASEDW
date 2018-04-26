/*作        者: Andy                                                                                                                  */
/*處理概要: 依照 SORT_KEYS 排序後 取排序後第一筆 reduce to GROUP_KEYS                 */
/*輸    入: DSN:處理前檔案                                                                                   
               , GROUP_KEYS: reduce後的key值
               , SORT_KEYS: 定義資料排序
               ,  OUT: reduce後的檔案                                                                                   */
/*輸    出:  OUT.                                                                                                        */
/*其    他:                                                                                 */
/*修    改:                                                                                              */
%MACRO DQ_groupSampleFetcher( DSN , GROUP_KEYS , SORT_KEYS  ,OUT ) ;
        %LET GROUP_KEYS = %SYSFUNC( KCOMPRESS( &GROUP_KEYS.  , () ) ) ;
        %LET SORT_KEYS = %SYSFUNC( KCOMPRESS( &SORT_KEYS.  , () ) ) ;
 
        %LOCAL /* GROUP_KEY_noParentheses*/ SORT_KEYS_BY_SPACE  GROUP_KEYS_BY_SPACE ;
        %LET SORT_KEYS_BY_SPACE= %sysfunc(tranwrd(&GROUP_KEYS. , %str(,) , %str( ) ));
        %LET GROUP_KEYS_BY_SPACE = %sysfunc(tranwrd(&GROUP_KEYS. , %str(,) , %str( ) )) ;

    /*    %LET GROUP_KEY_noParentheses =  %SUBSTR( &GROUP_KEYS. ,2 ,%EVAL( %LENGTH( &GROUP_KEYS. ) -2 ) )  ; */
        %LOCAL UUID ; 
        %LET UUID = &SYSINDEX. ;

        proc sort  threads data=&DSN. out=reduceKey&UUID.  ; 
                by &SORT_KEYS_BY_SPACE. ; 
        run ;
        
        data &OUT. ;
                set reduceKey&UUID.(idxwhere=YES) ;
                by &GROUP_KEYS_BY_SPACE. ;
                if FIRST.%scan( &GROUP_KEYS_BY_SPACE. , 1 , %str( ) ) then output ;
        run;
        
        proc datasets lib=WORK memtype=dat nowarn nolist ;
                delete reduceKey&UUID. ;
        quit;

%MEND ;
/*範例說明*/
      /*範例一: 同一個ID 不同日期都有日期，依照日期降冪排序後取第一筆
        DATA ABC ;
		format tdate nldate10. ;
		ID = "A"  ; tdate = "01JAN2017"d ; SCORE = 1 ; SEQ = 1 ; OUTPUT ;
                ID = "A"  ; tdate = "03JAN2017"d ; SCORE = 1 ;SEQ = 2 ; OUTPUT ;
        RUN ;
	options mprint ; 
        %DQ_groupSampleFetcher( ABC , ID , (ID , DESCENDING tdate ) , ABC)
        */
