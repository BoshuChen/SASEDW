/*巨集名稱: DQ_UKChecker                                                                                            */
/*作        者: Andy                                                                                                      */
/*處理概要: 驗證TBL p_key 是否 unique                                                               */
/*輸    入:  TBL: 驗證表格 , 
           keyArr: (key1 , key2 , ... , keyn )  , 
                   WHERE_CONDITION : condition1 and condition2 and ...  ,
                   maxOut: 最大輸出筆數                                    */
/*輸    出:   errOut                                                                                */
/*其    他:                                                                                                                    */
%MACRO DQ_UKChecker( TBL , 
				                    keyArr , 
				                    whereClus=  , 
				                    errOut=%kscan( &tbl. , -1 , str(.) )_uniErr , 
				                    maxOut=10 ) ;
    %IF %SUPERQ(whereClus) ^= %THEN %LET whereClus = %SYSFUNC( dequote( &whereClus. ) ) ; 
    %LET keyArr = %ksubstr( %SUPERQ(keyArr) , 2 , %klength(&keyArr.) -2 ) ;
        proc sql %IF %UPCASE(%SUPERQ(maxOut)) ^= MAX %THEN OUTOBS=&maxOut. ; ;
        create table &errOut. as
                    select &keyArr. , *
                    from &TBL. 
                    %IF %SUPERQ(whereClus) ^= %THEN where &whereClus. ;
                    group by &keyArr. 
                    having count(*) > 1 
                    ;
        quit;
%MEND ;
/* 範例說明*/
        /* 範例一: check ok case
        data abc ;
            xx = 1 ; yy = "ab" ; zz = 5 ; output ;
            xx = 1 ; yy = "ac" ; zz = 5 ; output ;
            xx = 1 ; yy = "ad" ; zz = 5 ; output ;
        run ; 
        options mprint ; 
        %DQ_UKChecker( work.abc ,  ( xx , yy ) ) 

        */
     /* 範例二: check not ok case
        data abc ;
            xx = 1 ; yy = "ab" ; zz = 5 ; output ;
            xx = 1 ; yy = "ac" ; zz = 5 ; output ;
            xx = 1 ; yy = "ad" ; zz = 5 ; output ;
        run ; 
        options mprint ; 
        %DQ_UKChecker( work.abc ,  ( xx  ) ) 
        */
