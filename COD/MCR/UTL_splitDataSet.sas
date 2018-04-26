/*巨集名稱: splitDataSet                                                                                           */
/*作        者: Andy                                                                                                      */
/*處理概要:  將一個 sasdataset 分割成指定個數 sasdataset 	                              */
/*輸    入:   DS: dataset name 
		   DScnt: 分割次數
                    pbuff(&syspbuff.) ,VAR=V ,CNT=Vcnt                                                   */
/*輸    出:   &VAR.  ,&CNT.                                                                                   */
/*其    他:   del_gbl_arr /coount_var                                                                       */
/*修    改:                                                                                                                    */
%MACRO UTL_splitDataSet(DS ,DScnt=2 ,OUT=splitDataSet );

        data %DO i = 1 %TO &DScnt.;
                &OUT.&i.
                %END;
                ;
                retain x;
                set &DS. nobs=nobs;

                if _n_ eq 1 then
                        do;
                                if mod(nobs,&DScnt.) eq 0 then
                                        x=int(nobs/&DScnt.);
                                else x=int(nobs/&DScnt.)+1;
                        end;

                if _n_ le x then
                        output &OUT.1;

                %DO i = 2 %TO &DScnt.;
                else if _n_ le (&i.*x) then
                        output &OUT.&i.;
                %END;
		drop x ;
        run;

%MEND ;


/* 範例說明*/
        /*範例一: 將 aaa 拆成10個檔 
        data aaa;
                 do i = 1 to 82; output; end;
        run; 
        %UTL_splitDataSet( aaa ,DScnt = 3 ,OUT = test ) 
         */

