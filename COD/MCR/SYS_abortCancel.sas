/*作        者: Andy                                                                                                                         */
/*處理概要: 當發生錯誤 記錄LOG 並中斷程式                                                    */
/*輸    入: log: 指定LOG內容 預設: error occur   */
/*輸    出:  N/A  */
/*相依核心: %sasMail                                                                                                                                 */
%MACRO SYS_abortCancel( log=error occur  /*要顯示的訊息,預設為 error occur */ , 
                                       from = "pearlmale@gmail.com" , 
                                       email=( "pearlmale@gmail.com" ) );
        %IF &syserr. gt 6 %THEN %DO;
		%LET log = %QSYSFUNC(dequote( &log. ) ) ;
                %PUT ERROR:  Error_Flag %SYSFUNC(dequote( &log. ) ) ;
		%SYS_mailSender( &from., TO= &email. , BODY = ( "&log.") )
                %ABORT cancel ;
        %END ;
%MEND;

/*範例說明*/
      /*範例一: 
		OPTIONS MPRINT ; 
                DATA TEST ; 
                        123a = "A1"  ; NAME = "王大明" ;OUTPUT ; 
                run ; %SYS_abortCancel( log="error occur" , from = "andywang@transglobe.com.tw" , email =( "andywang@transglobe.com.tw" ) ) ; 
        */ 
