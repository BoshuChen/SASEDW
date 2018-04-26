/*巨集名稱: DQ_missingCounter                                                                            */
/*作        者: Andy                                                                                                 */
/*處理概要: 驗證表格missing的筆數                                 					*/
/*輸    入: DSN: 備驗證表格
                , OUT: 驗證結果
                , prefix: 驗證統計量欄位名稱前綴   */
/*輸    出:  無  */
/*相依核心: N/A         */
/*其    他:                                                                                                                    */
%MACRO DQ_missingCounter( DSN  ,OUT=&DSN._OUT , prefix=mcnt_ ) ; 
        %LET memname = %scan( &DSN. , -1 , %STR(.) ) ;
        %LET  libname = %scan( &DSN. , -2 , %STR(.) ) ;
        %IF %SYSEVALF(%SUPERQ(libname)=,boolean) %THEN %LET libname = WORK ;
        %let libname =  %upcase(&libname.) ; 
        %let memname =  %upcase(&memname.) ; 
        %PUT &memname..&libname. is processing ... ;

        proc sql noprint;
                select " SUM(IFN( cmiss( " || kstrip(name) ||  " ) , 1, 0 ))  as &prefix." || kstrip(name)  || " " 
                into :check_tmp  separated by ','
                from sashelp.vcolumn
                where memtype = "DATA" 
                and memname = "&memname." 
                and libname = "&libname" 
                ;
        quit ; 
        %put &check_tmp. ;

        proc sql ; 
                create table &OUT. as 
                        select &check_tmp. 
                        from &libname..&memname. 
                        ;
        quit; 

%MEND ;

/*範例說明*/

	/*範例1: unit test example 
		data test ; 
		        x1 = 1 ; x2 = "A" ; x3 = 1  ; output ; 
		        x1 = . ; x2 = "A" ; x3 = 2  ; output ; 
		        x1 = 1 ; x2 = "" ; x3 = 3  ; output ; 
		        x1 = 1 ; x2 = "" ; x3 = 4  ; output ; 
		        x1 = . ; x2 = "A" ; x3 = 5  ; output ; 
		run ; 
		%DQ_missingCounter(test , OUT=ooo) ;
	*/
