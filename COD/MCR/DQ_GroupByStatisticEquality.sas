/*�����W��:DQ_GroupByStatisticEquality                                                                 */
/*�@        ��: Andy                                                                                                      */
/*�B�z���n: ���Ҧh�Ӫ��̷Ӻc��group by ����έp�q�O�_�ۦP                  */
/*��    �J:  tblArr: ���}�C 
                  groupByArr: ���w�c��
                  StatisticArr : �έp�q�}�C
                  sha: ���[�K�覡
		  sha_format: sha�����榡
                  OUT: ���~������
                   */
/*��    �X:  ���                                                                                              */
%MACRO DQ_GroupByStatisticEquality( tblArr ,  groupByArr , StatisticArr , sha=SHA256 , sha_format=HEX64. , OUT=checkGroupByStatisticErr) ;
	%LOCAL UUID tblCnt groupBySpace groupByComma tblArrSpace i ; 
	%LET UUID = &SYSJOBID._&SYSINDEX. ; /*executed_id*/

	%LET groupByComma = %KSUBSTR( %SUPERQ(groupByArr)  , 2 , %KLENGTH( &groupByArr. ) - 2 ) ;
	%LET groupBySpace = %sysfunc(tranwrd( %SUPERQ(groupByComma) , %STR(,) , %STR( ) ) ) ;
	%LET StatisticArr = %KSUBSTR( %SUPERQ(StatisticArr)  , 2 , %KLENGTH( &StatisticArr. ) - 2 ) ;
	%LET tblArr = %KSUBSTR( %SUPERQ(tblArr)  , 2 , %KLENGTH( &tblArr. ) - 2 ) ;

	%LET tblCnt = 0 ;
	%LET tblArrSpace = ;
	%DO %WHILE ( %QKSCAN( %SUPERQ( tblArr ) , &tblCnt. + 1 , %STR(,) ) ^= );
                %LET tblCnt = %EVAL( &tblCnt. + 1 ) ;
                %LOCAL tbl_&UUID._&tblCnt. ;
                %LET tbl_&UUID._&tblCnt. =  %KSCAN( %SUPERQ( tblArr ) , &tblCnt. , %STR(,) ) ;
		proc sql ; 
			create table m_tbl_&UUID._&tblCnt.( index=( idx_%KSCAN(&&tbl_&UUID._&tblCnt. , -1 ,%STR(.) ) =( &groupBySpace.))) as 
				select &groupByComma. ,  
					 putc( &sha.(catx( "|" , &StatisticArr. )) , "%SYSFUNC(dequote(&sha_format.))" ) as checkSum_&tblCnt. 
				from &&tbl_&UUID._&tblCnt.
				group by &groupByComma. 
				;
		quit;
		%LET tblArrSpace = &tblArrSpace. m_tbl_&UUID._&tblCnt. ;
        %END ;
	data &OUT. ( drop=i checkSum_: ) ;
		MERGE &tblArrSpace. ;
		BY &groupBySpace. ;
		%DO i = 2 %to &tblCnt. ;
			IF checksum_1 NE checkSum_&i. then output ; 
		%END;
	run;
	proc datasets lib=work nolist nodetails nowarn;
		delete m_tbl_&UUID._: ;
	run ;
%MEND; 
/* �d�һ���*/
/* �d�Ҥ@:  master.key1 = 'b' �|��  detail.key1 = 'b' ���[�`�藍�_�� �ҥH�|�X�{�b���~����� 

	data master ; 
		key1 = "a" ; key2 = "a1" ; amt1 = 30 ; amt2 = 70 ; output ; 
		key1 = "b" ; key2 = "b1" ; amt1 = 1 ; amt2 = 3 ; output ; 
	run ; 
	data detail ; 
		key1 = "a" ; key2 = "a1" ; amt1 = 10 ; amt2 = 20 ; output ; 
		key1 = "a" ; key2 = "a1" ; amt1 = 20 ; amt2 = 50 ; output ; 
		key1 = "b" ; key2 = "b1" ; amt1 = 1 ; amt2 = 2 ; output ; 
		key1 = "b" ; key2 = "b1" ; amt1 = 1 ; amt2 = 3 ; output ; 
	run ; 
        options mprint; 
	%DQ_GroupByStatisticEquality( (master, detail) , ( key1 , key2 ) , ( SUM(amt1) , SUM(amt2) ) ) ; 
*/
