/*作        者: Andy                                                                                              */
/*處理概要: 利用關聯關係表格如 PK(主鍵) , FK( 外部鍵) ,RPK(外部主鍵)探索資料產生順序 */
/*輸    入:  TBL: 表格 
                  NODE: 父節點如 PK
                  LEAF : 子節點如 RPK
		  level: 指定關聯次數
		  OUT(optional): 產出結果檔
                  KEEP(optional): 要保留的變數
                  TYPE(optional): 關聯條件
                              ( self :找指定level下自己關聯到自己的資料 /
				other :找指定level下自己不關聯到自己的資料 /
                                 all: 找指定level下所有關聯 )                                
                   */
/*輸    出:  表格                                                                                              */
%MACRO UTL_circularRef( TABLE , NODE , LEAF , level ,OUT=res_&level. , KEEP= , TYPE=self) ;
	%LOCAL i j  keepMember ; 
	%LET KEEP = %SYSFUNC( KCOMPRESS( %SUPERQ(KEEP) , () ) ) ; 

	proc sql ; 
		drop table &out. ; 
		create table &out. as 
			select %DO i = 0 %TO &level. ;
					%IF &i. > 0 %THEN %STR(,)  ;
					a&i..&node. as &node._&i. 
					%let j = 0 ;
					%DO %WHILE ( %QKSCAN( %SUPERQ( KEEP ) , &j. + 1 , %str(,) ) ^= ) ;
						%LET keepMember =  %KSCAN( %SUPERQ( KEEP ) , &j. + 1 , %str(,) ) ;
						%LET j = %SYSEVALF( &j. + 1 ) ;
						%STR(,) a&i..&keepMember. as &keepMember._&i. 
					%END; 
                                        %STR(,) a&i..&leaf. as &leaf._&i.					
				 %END ; 
			from &TABLE. AS a0 
			%DO i = 1 %TO &level. ;
				INNER join &TABLE.(where=(&node. NE &leaf.)) as a&i. 
				on( a%sysevalf( &i. - 1 ).&LEAF. = a&i..&NODE. )
			%END;
			%IF %SYSEVALF( %UPCASE( %SUPERQ( TYPE) )=SELF ) %THEN where a0.&node. = a&level..&LEAF. ;
			%ELSE %IF %SYSEVALF( %UPCASE( %SUPERQ( TYPE) )=OTHER ) %THEN where a0.&node. ^= a&level..&LEAF. ;
			%ELSE %IF %SYSEVALF( %UPCASE( %SUPERQ( TYPE) )^=ALL  ) %THEN %DO ;
				%PUT ***%UPCASE( %SUPERQ( TYPE) )****;
				%ABORT CANCEL ;
			%END; 
			;
	quit ; 
%MEND; 
/*範例說明*/
/* 範例一: 找出關聯一次會關聯到自己的資料
	options mprint ;
	LIBNAME LIBSTG "/SASDATA/USER/TGLEDW/LIB/STG" ;
	%UTL_circularRef( LIBSTG.tbl_pkeyfkeyrpkey , pk ,rpk , 1 ,KEEP =(FK) ,TYPE=self )
*/
/* 範例二: 找出關聯一次的資料(排除自己關連自己)
	options mprint ;
	LIBNAME LIBSTG "/SASDATA/USER/TGLEDW/LIB/STG" ;
	%UTL_circularRef( LIBSTG.tbl_pkeyfkeyrpkey , pk ,rpk , 1 ,KEEP =(FK) ,TYPE=other )
*/
