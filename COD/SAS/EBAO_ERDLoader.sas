DATA ebaoConstraintImport; 
	set edwmeta.ebao_erdloader ;
	call execute ( ' proc import datafile = "' || kstrip(CSVPATH) 
                                                                  || '" dbms=csv replace out  = ' || kstrip(OUTDS) 
                                                                  || '(keep = ' || kstrip(KEEPVAR) || ' ' || kstrip(WHERESTATEMENT) 
                                                                  || ' ); getnames = yes ; guessingrows=max ; run ; '  ) ;
	CALL SYMPUTX( KSTRIP(outDSMcrVar) , KSTRIP(outDS) ) ;
RUN;

DATA EBAO_ERDLoader_consCatxCols ;
	SET EDWMETA.EBAO_ERDLoader_consCatxCols;
	CALL EXECUTE('%UTL_groupConcate( ' || kstrip( TBL ) || ' , ' 
                                                                          || kstrip(groupVars) || ' , ' 
                                                                          || kstrip( concateVars ) || ' , ' 
                                                                          || ' order = ' || kstrip(order) || ' , ' 
                                                                          || ' concatePrefix = ' || kstrip(concatePrefix) || ' , '
                                                                          || 'out = ' || kstrip(out) || ' ) '  );
	CALL SYMPUTX( "contraintCols", KSTRIP(OUT) ) ;
	CALL SYMPUTX( "constraintName" , KSTRIP(KSUBSTR( groupVars , 2 , KLENGTH(groupVars) -2 ) ) ) ;
	CALL SYMPUTX( "colsName" , kstrip(concatePrefix) || KSTRIP(KSUBSTR( concateVars , 2 , KLENGTH(concateVars) -2 ) ) ) ;
	STOP ; /* do only once !!*/
RUN ; 

PROC SQL ; 
	CREATE TABLE tbl_pkConstraintCols AS 
		SELECT  baseFiltered.table_name , 
                         	grpConsCols.&colsName. as pkey
		from &DS_allConstraint.( WHERE =(CONSTRAINT_TYPE = "P" AND 
									  TABLE_NAME like 'T_%' AND  
									  TABLE_NAME NOT LIKE 'TM_%') ) AS baseFiltered 
		INNER JOIN  &contraintCols. AS grpConsCols
		ON (baseFiltered.&constraintName. = grpConsCols.&constraintName. )
		;
QUIT ;

PROC SQL ; 
	CREATE TABLE tbl_fkRelatedPk AS 
		SELECT M.TABLE_NAME ,
			     C.&colsName.  AS FK,
			     A.TABLE_NAME AS RTBL ,
			     B.&colsName. AS RPK
		FROM &DS_allConstraint. (where=( CONSTRAINT_TYPE = "R" AND 
									 TABLE_NAME like 'T_%' AND 
									 TABLE_NAME NOT LIKE 'TM_%' ))  AS M
		INNER JOIN &DS_allConstraint.( where=( CONSTRAINT_TYPE = "P" AND 
                                                                                   TABLE_NAME like 'T_%' AND 
										   TABLE_NAME NOT LIKE 'TM_%' ) )  AS A 
										    ON( M.R_&constraintName. =  A.&constraintName. )
		LEFT JOIN &contraintCols. AS C ON ( M.&constraintName. = C.&constraintName. )
		LEFT JOIN &contraintCols. AS B ON (A.&constraintName. = B.&constraintName.)
	;
QUIT ;
PROC SQL;
	   CREATE TABLE LIBSTG.tbl_pKeyFkeyRPkey AS 
	   	SELECT kstrip(t1.table_name) || "." || kstrip( t1.pkey ) as pk , 
				kstrip(t2.table_name) || "." || kstrip( t2.fk ) as fk , 
			       kstrip(t2.RTBL) || "." || kstrip( t2.rpk ) as rpk
	      	FROM WORK.tbl_pkConstraintCols t1
	        INNER JOIN WORK.tbl_fkRelatedPk t2 ON (t1.TABLE_NAME = t2.TABLE_NAME);
QUIT;
PROC SORT DATA=LIBSTG.tbl_pKeyFkeyRPkey  NODUPKEY FORCE ;
	BY PK  RPK ;
RUN ;

libname Tylor "/SASDATA/USER/Tylor" ;
PROC DATASETS LIB=TYLOR KILL NOLIST NOWARN NODETAILS ;RUN ;
PROC SQL ; 
	CREATE TABLE pkeyList as 
		SELECT DISTINCT PK  
		FROM LIBSTG.tbl_pKeyFkeyRPkey
		;
QUIT;
%MACRO pkeyListExec() ;
	PROC SQL NOPRINT ; 
		SELECT DISTINCT PK
		INTO : pkeyList separated by ',' 
		FROM pkeyList 
		;
	QUIT ;
	%LOCAL i subStr;
	%LET i = 0 ; 
	%DO %WHILE ( %QKSCAN( %SUPERQ( pkeyList ) , &i. + 1 , %STR(,) ) ^= ) ;
		%LET subStr = %KSCAN( %SUPERQ( pkeyList ) , &i. + 1  , %STR(,) );
		%DQ_relationExpander( LIBSTG.tbl_pKeyFkeyRPkey  ,
				  PK, 
				  RPK  ,
		                  &subStr.  , 
				 OUT=Tylor.D_%KSUBSTR( %KSCAN(&subStr. , 1 , %str(.) )  , 3 ) )
		 %LET i = %sysevalf( &i. + 1 ) ;
	/* test line:   %IF &i EQ 2 %THEN %RETURN ;  */
	%END; 
%MEND;
%pkeyListExec

		
