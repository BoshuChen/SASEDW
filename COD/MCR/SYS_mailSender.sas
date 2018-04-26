/*作        者: Andy                                                                                                                         */
/*處理概要: 系統寄發通知信                                                          					     */
/*輸    入: FROM: 寄件者                                                                                   
                , TO: 收件者( email1 , email2 , ... , emailn )
                , CC: 收件者( email1 , email2 , ... , emailn )
                , BCC: 收件者( email1 , email2 , ... , emailn )                                                      
                , SUBJECT: 寄件主旨
		, ATTACH: 附加檔案( "file1" , "fil2" , ... , "filen" ) 
		, BODY: 內文( "line1" , "line2" , ... , "linen" ) */
/*輸    出:  N/A                                                                                                                                  */
/*相依核心: N/A                                                                                                                           */
%MACRO SYS_mailSender( FROM , 
				  TO=( ) , 
				  CC=( ) , 
				  BCC=( ) , 
			          SUBJECT="System Mail message" , 
				  ATTACH=( ) ,
				  BODY=("sas system mail" , "thanks") ) ;
	%LET FROM = %QSYSFUNC(DEQUOTE( &FROM.) ) ; 
	%LET SUBJECT = %QSYSFUNC(DEQUOTE( &SUBJECT. ) ) ;
	%LET TO = %QKSUBSTR( %SUPERQ(TO) , 2 , %KLENGTH( &TO. ) - 2 ) ;
	%LET CC = %QKSUBSTR( %SUPERQ(CC) , 2 , %KLENGTH( &CC. ) - 2 ) ;
	%LET BCC = %QKSUBSTR( %SUPERQ(BCC) , 2 , %KLENGTH( &BCC. ) - 2 ) ;
	%LET ATTACH = %QKSUBSTR( %SUPERQ(ATTACH) , 2 , %KLENGTH( &ATTACH. ) - 2 ) ;
	%LET BODY = %QKSUBSTR( %SUPERQ(BODY) , 2 , %KLENGTH( &BODY. ) - 2 ) ;
	
	%IF %EVAL( %SUPERQ( TO )= ) %THEN %DO ;
		%PUT ERROR: RECIEPT PARAMETER "TO" IS  INVALID ;
		%RETURN ;
		%END;

	filename Mailbox email;  
	data _null_;   
		file Mailbox  ; 
		put "!EM_FROM! &FROM. ";
		%IF %EVAL( %SUPERQ(TO)= ) %THEN;
		%ELSE %DO ;
			%LET TO = %SYSFUNC( translate( &TO. , %str(%')%str( ) , %str(%")%str(,) ) ) ;
			put "!EM_TO! ( &TO. )" ;
		%END ;
		%IF %EVAL( %SUPERQ(CC)= ) %THEN;
		%ELSE %DO ;
			%LET CC = %SYSFUNC( translate( &CC. , %str(%')%str( ) , %str(%")%str(,) ) ) ;
			put "!EM_CC! ( &CC.  )"   ;
		%END ;

		%IF %EVAL( %SUPERQ(BCC)= ) %THEN;
		%ELSE %DO ;
			%LET BCC = %SYSFUNC( translate( &BCC. , %str(%')%str( ) , %str(%")%str(,) ) ) ;
			put "!EM_BCC! ( &BCC.  )"   ;
		%END ;

		put "!EM_SUBJECT! &SUBJECT." ;
		%IF %EVAL( %SUPERQ(ATTACH)= ) %THEN;
		%ELSE %DO ;
			%LET ATTACH = %SYSFUNC( translate( &ATTACH. , %str(%')%str( ) , %str(%")%str(,) ) ) ; 
			put "!EM_ATTACH! ( &ATTACH. ) " ;
		%END;

		%IF %EVAL( %SUPERQ(BODY)= ) %THEN;
		%ELSE %DO ;
			%LET BODY = %QSYSFUNC( tranwrd( &BODY. , %STR(,) , %STR(; PUT)) );
			put %UNQUOTE(&BODY.) %str(;) ;
		%END;
	run ;

%MEND;
/*範例說明*/
      /*範例一:
	options mprint ; 
	%SYS_mailSender( "andywang@transglobe.com.tw" , 
			TO=( "andywang@transglobe.com.tw" ) ,
			BODY=( "Hello" , "world")  )
*/
