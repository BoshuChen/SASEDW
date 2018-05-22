/*巨集名稱:DQ_GroupByStatisticEquality                                                                 */
/*作        者: Andy                                                                                                      */
/*處理概要: 驗證多個表格依照構面group by 後比對統計量是否相同                  */
/*輸    入:  tblArr: 表格陣列 
                  groupByArr: 指定構面
                  StatisticArr : 統計量陣列
                  sha: 比對加密方式
		  sha_format: sha對應格式
                  OUT: 錯誤報表表格
                   */
/*輸    出:  表格                                                                                              */
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
/* 範例說明*/
/* 範例一:  master.key1 = 'b' 會跟  detail.key1 = 'b' 的加總對不起來 所以會出現在錯誤報表裡 

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
