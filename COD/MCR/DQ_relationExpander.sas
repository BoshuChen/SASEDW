/*作        者: Andy                                                                                               */
/*處理概要: 整理具方向性關聯                                                                          */
/*輸    入:  表格名稱，父節點，子節點，產出資料名稱(optional)         		*/
/*輸    出:                                                                                                            */
/*其    他: 若DataSet(TBL) 如下
                  NODE       LEAF
	          ------------------------------
                  a                b 
		  a                 c
                  b                 c
                  c                 d 
                給定a 可以找出 a 的子孫，整理成關聯(OUT)
		NODE        LEAF        LEVEL
		-----------------------------------------
		ROOT         a               0
		a                  b               1
		a                  c               1
		a                  d               2		
			            */
/*修    改:                                                                                                             */
%MACRO DQ_relationExpander( TBL /* mapping relation including node (1) to leaf (many) */ , 
						NODE , 
						LEAF ,
						NODE_VAL ,
						OUT=TREE /*output dataset with link level */ ,
						MAX=20  /* maximum iteration */ );
        %LET TBL =  %SYSFUNC( dequote( &TBL. ) ) ;
        %LET NODE =  %SYSFUNC( dequote( &NODE. ) ) ;
        %LET LEAF =  %SYSFUNC( dequote( &LEAF. ) ) ;
        %LET NODE_VAL = %QSYSFUNC( dequote( &NODE_VAL. ) ) ; /*鎖定祖先只找誰，沒指定就是全找*/ 

	%IF %SYSEVALF(%SUPERQ(NODE_VAL)=,boolean) %THEN %DO ;
		%PUT ERROR:INPUT NODE_VAL INVALID ;
		%ABORT CANCEL ;
	%END;
        %LOCAL level nlevel ii UUID;
	%LET UUID = &SYSJOBID._&SYSINDEX.  ;  /* session_id + execute macro count */
        %LET   level = 1;

        PROC SQL;
		/*留下有效族譜包含父節點與父節點的資料*/
                CREATE TABLE  S&UUID. AS 
                        SELECT                *
                        FROM                 &TBL. 
                        WHERE                 &NODE.         NE &LEAF. 
                        AND                 MISSING(&NODE.) = 0 
                        AND                 MISSING(&LEAF.) = 0 
                        ; 
	QUIT ;%IF &SYSERR. > 6 %THEN %ABORT CANCEL ; 
	PROC SQL ;
		/* 第一層關聯*/
                CREATE table L&UUID._1 AS
                        SELECT * ,1 as level
                        FROM S&UUID.
                        WHERE 
                                %IF "&NODE_VAL." NE "" %THEN &NODE. = "&NODE_VAL."  ; 
                        ;  
	QUIT ; %IF &SYSERR. > 6 %THEN %ABORT CANCEL ; 
	/* append root node */
	DATA L&UUID._0 ;
		IF 0 THEN SET L&UUID._1 ;
		&NODE. = "ROOT"  ;
		&LEAF. = "&NODE_VAL." ;
		LEVEL = 0 ;
	RUN ;	%IF &SYSERR. > 6 %THEN %ABORT CANCEL ; 

        %DO %WHILE(&SQLOBS > 0);
		/* use node to find leaf as node and go on finding leaf */
		/* append nodes in levels */
		DATA S0&UUID. ; 
			SET %DO ii = 1 %TO &level.;
				 L&UUID._&ii.  
				%END ; ;
		RUN ;
		PROC SQL ; 
		/* 迴圈停止條件是查無資料或是次數達上限MAX */
	                %LET nlevel = %EVAL(&level + 1);
	                CREATE TABLE L&UUID._&nlevel. AS
	                        SELECT A.* , &nlevel. as level
	                        FROM S&UUID.  A INNER JOIN ( SELECT DISTINCT &LEAF. FROM L&UUID._&level. ) B
	                                ON ( A.&NODE. = B.&LEAF. ) 
				WHERE A.&LEAF. NOT IN (SELECT &NODE. FROM S0&UUID. );
	                %LET level = &nlevel;
	                %if  &nlevel. GT &MAX. %THEN %do ;
	                        %put ERROR: LOOP TOO MUCH ,CHK DEPENDENCY ; 
	                        %goto LEAVE_LOOP ;
	                %end ;
		QUIT ; %IF &SYSERR. > 6 %THEN %ABORT CANCEL ; 
        %END; 
%LEAVE_LOOP:

	/* 併檔*/
	DATA &OUT. ; 
		SET L&UUID._: ;
	RUN ; %IF &SYSERR. > 6 %THEN %ABORT CANCEL ; 
	
	/*清TEMP檔*/
	PROC DATASETS LIB=WORK NOLIST NOWARN ;
		DELETE L&UUID._: S&UUID.  S0&UUID. ;
	QUIT;%IF &SYSERR. > 6 %THEN %ABORT CANCEL ; 

%MEND;
/* 範例說明*/
	/*範例1: 
		data relation ; 
			father= "a1" ; son = "b1"  ; output ; 
		 	father= "b1" ; son = "c1"  ; output ;
			father= "c1" ; son = "d1"  ; output ;
			father= "b1" ; son = "e1"  ; output ;
			father= "e1" ; son = "f1"  ; output ;
			father= "f1" ; son = "g1"  ; output ;
			father= "f1" ; son = "h1"  ; output ;
			father= "g1" ; son = "c1"  ; output ;
			father= "h1" ; son = "d1"  ; output ;
		run ;
		%DQ_relationExpander( relation , 	father , son , "b1" ) 	
	*/
