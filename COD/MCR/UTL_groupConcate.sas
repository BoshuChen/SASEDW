/*�@        ��: Andy                                                                                              */
/*�B�z���n: �̷ӫ��w�c���s�ի�N���w�ܼ�concate                                  */
/*��    �J:  TBL: ��� 
                  groupVars: �c���s��
                  concateVars : ���w�h���ܼ�
		  order: �ƧǸs��
		  concatePrefix: �s�ܼƫe�m�W��
                  concateDlm:�s�ܼƤ��e���j�Ÿ�
                  concateMaxLen:�s�ܼƳ̱`����
                  out:���X���
                   */
/*��    �X:  ���                                                                                              */
%MACRO UTL_groupConcate( TBL , 
                                                   groupVars , 
                                                   concateVars , 
                                                   order=&group. , 
						   concatePrefix=grpCon_ ,
					           concateDlm=%str(,) ,
						   concateMaxLen = 1000 ,
                                                   out=grpCon_%sysfunc(kscan( %superq(TBL) , -1 , %str(.) ) )  ) ; 

	%LOCAL groupVarsDlmSpace  groupVarsDlmComma;
	%LET groupVarsDlmComma = %KSUBSTR( %SUPERQ(groupVars)  , 2 , %KLENGTH( &groupVars. ) - 2 ) ;
	%LET  groupVarsDlmSpace = %sysfunc(tranwrd( %SUPERQ(groupVarsDlmComma) , %str(,) , %str( ) ) ) ;
	%LOCAL orderDlmSpace orderDlmComma ; 
	%LET orderDlmComma = %KSUBSTR( %SUPERQ(order)  , 2 , %KLENGTH( &order. ) - 2 ) ;
	%LET  orderDlmSpace = %sysfunc(tranwrd( %SUPERQ(orderDlmComma) , %str(,) , %str( ) ) ) ;
	%LOCAL concateVarsDlmComma  concateVarsDlmSpace concateVarsWithLen ;
	%LET concateVarsDlmComma = %KSUBSTR( %SUPERQ(concateVars)  , 2 , %KLENGTH( &concateVars. ) - 2 ) ;
	%LET  concateVarsDlmSpace = %sysfunc(tranwrd( %SUPERQ(concateVarsDlmComma) , %str(,) , %str( ) ) ) ;
	%LET concateVarsWithLen = %sysfunc(tranwrd( %SUPERQ(orderDlmComma) , %str(,) , %str( $&concateMaxLen. ) ) )%str( $&concateMaxLen. ) ;

	proc sort data=&TBL. ;
		by &orderDlmSpace. ;
	run;
	data &OUT. (keep= &groupVarsDlmSpace. &concatePrefix.: ) ; 
		set &TBL. ;
		by &groupVarsDlmSpace. ;
		%LOCAL i subStr; 
		%LET i = 0 ; 
		%DO %WHILE ( %QKSCAN( %SUPERQ( concateVarsDlmComma ) , &i. + 1 , %STR(,) ) ^= ) ;
	                %LET subStr = %CMPRES(%KSCAN( %SUPERQ( concateVarsDlmComma ) , &i. + 1  , %STR(,) ));
			length &concatePrefix.&subStr. $&concateMaxLen. ;
			retain &concatePrefix.&subStr. ;
	                if first.%CMPRES(%KSCAN( %SUPERQ( groupVarsDlmComma ) ,  1  , %STR(,) )) then &concatePrefix.&subStr. = kstrip( &subStr.) ;
			else &concatePrefix.&subStr. = catx( "%sysfunc(dequote(&concateDlm.))" , kstrip(&concatePrefix.&subStr.) , kstrip( &subStr.) );
	                %LET i = %sysevalf( &i. + 1 ) ;
        	%END;
		if last.%CMPRES(%KSCAN( %SUPERQ( groupVarsDlmComma ) ,  1  , %STR(,) )) then output ; 
	run;

%MEND;
/*�d�һ���*/
	/*�d�Ҥ@:
	data test ;
		x1 = "a" ; x2 = "b" ; x3 ="c" ;x4 = 1 ; seq = 1 ; output ;
		x1 = "a" ; x2 = "b" ; x3 ="d" ;x4 = 2 ; seq = 2 ; output ;
		x1 = "z" ; x2 = "h" ; x3 ="c" ;x4 = 3 ; seq = 1 ; output ;
		x1 = "z" ; x2 = "h" ; x3 ="d" ;x4 = 4 ; seq = 2 ; output ;
	run ; 
	options mprint ;
	%UTL_groupConcate(work.test , (x1, x2) , (x3,x4) ,order = (x1,x2,seq) ) 
	*/



