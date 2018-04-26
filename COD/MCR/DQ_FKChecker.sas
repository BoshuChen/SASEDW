/*巨集名稱: DQ_FKChecker                                                                            */
/*作        者: Andy                                                                                                     */
/*處理概要: 驗證DS 是否滿足ForeignKey Constraint                                               */
/*輸    入:  DS: 要驗證FK的表格
		   fkArr: ( fk1 , fk2 , fk3 , ... ) 
		   ConsDS: Constraint Table
		   ConsArr: Constraint Fk's
		   OUT: 錯誤表格名稱
		   MissExcludeInd: 是否排除有missing的record default 0 
                   maxOut: 最大輸出筆數                                    */
/*輸    出:   errOUT                                                                                */
/*其    他:                                                                                                                    */
%MACRO DQ_FKChecker( DS , fkArr , ConsDS , ConsArr , errOUT= %kscan( &DS. , -1 , str(.) )_fkErr , maxOut=10 , MissExcludeInd = 0 ) ; 
	%LOCAL fkArrCnt  ConsArrCnt joinCondition i cmissCondition ; 
	%LET fkArr = %QKSUBSTR( %SUPERQ( fkArr ) , 2 , %KLENGTH( &fkArr. )  -2  ) ;
	%LET ConsArr = %QKSUBSTR( %SUPERQ( ConsArr ) , 2 , %KLENGTH( &ConsArr. )  -2  ) ;
	%LET fkArrCnt = 0 ;
	%LET ConsArrCnt = 0 ;
	%DO %WHILE ( %QKSCAN( %SUPERQ( fkArr ) , &fkArrCnt. + 1 , %STR(,) ) ^= ) ;
		%LET fkArrCnt = %EVAL( &fkArrCnt. + 1 ) ;
	%END;
	%DO %WHILE ( %QKSCAN( %SUPERQ( ConsArr ) , &ConsArrCnt. + 1 , %STR(,) ) ^= ) ;
		%LET ConsArrCnt = %EVAL( &ConsArrCnt. + 1 ) ;
	%END;
	%IF &fkArrCnt. ^= &ConsArrCnt. %THEN %DO ; 
		%PUT _local_ ; 
		%PUT ERROR: fkArr size should equal to ConsArr size ; 
	%END;
	%DO i = 1 %TO &fkArrCnt. ; 
		%IF &i. = 1 %THEN %DO ;
			%LET joinCondition = A.%KSCAN( %SUPERQ( fkArr ) , &i. , %STR(,) ) = B.%KSCAN( %SUPERQ( ConsArr ) , &i. , %STR(,) )  ;
			%LET cmissCondition = A.%KSCAN( %SUPERQ( fkArr ) , &i. , %STR(,) )  ;
		%END;
		%ELSE %DO ;
			%LET joinCondition = &joinCondition. AND A.%KSCAN( %SUPERQ( fkArr ) , &i. , %STR(,) ) = B.%KSCAN( %SUPERQ( ConsArr ) , &i. , %STR(,) ) ;
			%LET cmissCondition = &cmissCondition. , A.%KSCAN( %SUPERQ( fkArr ) , &i. , %STR(,) )  ;
		%END;
	%END ;

	PROC SQL MAGIC = 103 REMERGE %if %UPCASE(%SUPERQ(maxOut) ) ^= MAX %THEN OUTOBS= &maxOut. ; ; 
		create table &errOUT. as 
			select A.*
			from &DS. AS A left join &ConsDS. AS B
			on ( &joinCondition. ) 
			where B.%KSCAN( %SUPERQ( ConsArr ) , 1 , %STR(,) )  is null
			%IF MissExcludeInd ^= 0 %THEN AND cmiss( &cmissCondition. ) = 0 ;
			;
%MEND; 
/*範例說明*/
	/*範例一: 
		data abc  ;
			xx = 1 ; yy = "A" ; output ; 
			xx = 2 ; yy = "b" ; output ; 
			xx = 3 ; yy = "b" ; output ; 
		run ; 

		data def  ;
			xx = 2 ; yy = "b" ; output ; 
			xx = 3 ; yy = "b" ; output ; 
		run ; 

		%DQ_FKChecker( abc , ( xx ) , def , (xx ) ) 
	*/
