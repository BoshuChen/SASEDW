/*作        者: Andy                                                                                                                         */
/*處理概要: 將任意個數欄位CodeReference格式
                     KEY , VAL_POS , VAL_NB , VAL_PD 
                     A      , 1                , 2              , 3 
                     B      , A1              , A2           , A3
    會轉換成
    A , VAL_POS , 1 
    A , VAL_NB  , 2
    A , VAL_PD  , 3 
    B , VAL_POS , A1 
    B , VAL_NB  , A2
    B , VAL_PD  , A3
                                     */
/*輸    入: log: DSName:  CodeReference Table                                                                                    */
/*輸    出:  OUT: DataSet Name  */
%MACRO UTL_tran2KeyVal( DSName  , OUT= ) ;
	%LOCAL LIB TBL key Vals; 
	%LOCAL UUID ;
	%LET TBL = %upcase( %SYSFUNC( SCAN( &DSName. , -1 , %STR(.) ) ) ); 
	%LET LIB = %upcase( %SYSFUNC(  SCAN( &DSName. , -2 , %STR(.) ) ) ); 
	%IF %SYSEVALF( %SUPERQ( LIB ) = ) %THEN %LET LIB = WORK ; 
	%IF %SYSEVALF( %SUPERQ(OUT) = ) %THEN %LET OUT = &TBL._OUT; 
	%LET UUID = &SYSJOBID.&SYSINDEX. ;
	proc sql noprint ; 
              select name 
	      into: key_&UUID. separated by ' '
              from dictionary.columns
              where libname eq "&LIB." and memtype in('DATA') and memname = "&TBL."  and varnum = 1 
	     ;
             select name  
	      into: Vals_&UUID.  separated by ' ' 
              from dictionary.columns
              where libname eq "&LIB." and memtype in('DATA') and memname = "&TBL."  and varnum > 1 
	     ;
	quit ; 
	PROC SORT DATA= &DSName. ; BY &&key_&UUID. ; RUN ; 
	PROC TRANSPOSE data=&DSName.  OUT= A_&UUID. ;
	          BY &&key_&UUID. ;
	          VAR &&Vals_&UUID. ;
	RUN ; 
	PROC SQL ; 
		INSERT INTO &OUT. SELECT * FROM A_&UUID. ;
                DROP TABLE A_&UUID. ; 
	QUIT;
%MEND; 
/*說明範例:*/
	/*範例一
	DATA HAHAHA;
		FORMAT KEY $200. ; 
                FORMAT COL $200. ;
		FORMAT VAL $1000. ;
		STOP ;
	RUN ;
	DATA twoCol ; 
	        key = "NO001" ; Col1 = "AAA1" ; Col2 = "AAA2" ; OUTPUT ; 
	        key = "NO002" ; Col1 = "BBB1" ; Col2 = "BBB2" ; OUTPUT ; 
	        key = "NO003" ; Col1 = "CCC1" ; Col2 = "CCC2" ; OUTPUT ;
	RUN;
	%UTL_tran2KeyVal( twoCol , OUT=hahaha ) 
	*/
	/*範例二: Use DataDriven Method to generate data
	DATA twoCol ; 
	        key = "NO001" ; Col1 = "AAA1" ; Col2 = "AAA2" ; OUTPUT ; 
	        key = "NO002" ; Col1 = "BBB1" ; Col2 = "BBB2" ; OUTPUT ; 
	        key = "NO003" ; Col1 = "CCC1" ; Col2 = "CCC2" ; OUTPUT ;
	RUN;
	DATA threeCol ; 
	        key = "NNO001" ; Col1 = "AAA1" ; Col2 = "AAA2" ; Col3 = "AAA3" ; OUTPUT ; 
	        key = "NNO002" ; Col1 = "BBB1" ; Col2 = "BBB2" ; Col3 = "BBB3" ;  OUTPUT ; 
	        key = "NNO003" ; Col1 = "CCC1" ; Col2 = "CCC2" ; Col3 = "CCC3" ;  OUTPUT ;
	RUN;
        DATA HAHAHA;
		FORMAT KEY $200. ; 
                FORMAT COL $200. ;
		FORMAT VAL $1000. ;
		STOP ;
	RUN ;
	options mprint ;
	DATA DataDriven; 
                INFILE DATALINES DLM="|" TRUNCOVER  ;
                INPUT DSName $ ; 
		CALL EXECUTE( '%UTL_tran2KeyVal( ' || KSTRIP(DSName) || ' , OUT=HAHAHA ) ' ) ; 
DATALINES;
twoCol
threeCol
;
	RUN;
        */
