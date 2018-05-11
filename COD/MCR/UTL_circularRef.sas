/*�@        ��: Andy                                                                                              */
/*�B�z���n: �Q�����p���Y���p PK(�D��) , FK( �~����) ,RPK(�~���D��)������Ʋ��Ͷ��� */
/*��    �J:  TBL: ��� 
                  NODE: ���`�I�p PK
                  LEAF : �l�`�I�p RPK
		  level: ���w���p����
		  OUT(optional): ���X���G��
                  KEEP(optional): �n�O�d���ܼ�
                  TYPE(optional): ���p����
                              ( self :����wlevel�U�ۤv���p��ۤv����� /
				other :����wlevel�U�ۤv�����p��ۤv����� /
                                 all: ����wlevel�U�Ҧ����p )                                
                   */
/*��    �X:  ���                                                                                              */
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
/*�d�һ���*/
/* �d�Ҥ@: ��X���p�@���|���p��ۤv�����
	options mprint ;
	LIBNAME LIBSTG "/SASDATA/USER/TGLEDW/LIB/STG" ;
	%UTL_circularRef( LIBSTG.tbl_pkeyfkeyrpkey , pk ,rpk , 1 ,KEEP =(FK) ,TYPE=self )
*/
/* �d�ҤG: ��X���p�@�������(�ư��ۤv���s�ۤv)
	options mprint ;
	LIBNAME LIBSTG "/SASDATA/USER/TGLEDW/LIB/STG" ;
	%UTL_circularRef( LIBSTG.tbl_pkeyfkeyrpkey , pk ,rpk , 1 ,KEEP =(FK) ,TYPE=other )
*/
