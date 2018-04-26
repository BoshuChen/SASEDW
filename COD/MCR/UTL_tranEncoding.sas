/*作        者: Andy                                                                                                                         */
/*處理概要: DataSet 強制編碼轉換，避免SAS DATASET 因編碼問題造成無法開啟                     */
/*輸    入: in:要轉換的表格                                                                                   
                , out: 轉換後的表格
                , from: 原編碼,預設big5
                , to: 轉換後編碼,預設big5                                                        
                , sub:  
                , file_opt:                                                                                                                     */
/*輸    出:  N/A                                                                                                                                    */
/*相依核心: N/A                                                                                                                    */
%MACRO UTL_tranEncoding( in /*要轉換的表格*/  ,
                                    out /*轉換後的表格*/  ,
                                    from=big5 /*原編碼,預設big5*/ ,
                                    to=big5 /*轉換後編碼,預設big5*/ ,sub='?',file_opt=);
        data &out(encoding=asciiany);
                set &in;
                array cc (*) _character_;

                do _n_=1 to dim(cc);
                        cc(_n_)=kpropdata(cc(_n_),&sub,"&from","&to");
                end;
        run;
        %LET lib=%SCAN(&out,1,%STR(.));
        %LET mem=%SCAN(&out,2,%STR(.));
        %IF %LENGTH(&mem) =0 %THEN
                %DO;
                        %LET mem=&lib;
                        %LET lib=work;
                %END;
        proc datasets lib=&lib nolist;
                modify &mem /correctencoding="&to";
        run;
        quit;
%MEND;
