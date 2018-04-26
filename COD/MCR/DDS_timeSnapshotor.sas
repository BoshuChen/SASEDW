/*巨集名稱:DDS_timeSnapshotor                                                                                */
/*作        者: Andy                                                                                                      */
/*處理概要: 撈取DDS快照                    						*/
/*輸    入:  DSName:DDS表格名稱 
                  timePoint: 指定時間點
                  timeInterval: 指定區間
                  OUT: 產出表格名稱
                  INFORMAT: 輸入時間格式
                  validFromDttm: 時間戳記欄位名稱
                  validToFromDttm: 時間戳記欄位名稱
                   */
/*輸    出:  表格                                                                                              */
%MACRO DDS_timeSnapshotor(  DSName , 
                                                    timePoint= , 
                                                    timeInterval= , 
                                                    OUT=%SYSFUNC(SCAN( &DSName. , -1 ,%str(.) ))_OUT , 
                                                    INFORMAT=nldatm19. , 
                                                    validFromDttm = valid_from_dttm , 
						    validToDttm = valid_to_dttm 
                                                 ) ;	
        %PUT _LOCAL_ ;
	%LET INFORMAT = %SYSFUNC(DEQUOTE( &INFORMAT. ) ) ;
	%LOCAL timePointVal timeStr timeEnd /*timeInterval*/ timeStr1 timeEnd1 /*timePoint*/;
	%IF %SYSEVALF( %SUPERQ( timePoint ) ^= ) %THEN  %DO ;
        	%LET timePointVal = %SYSFUNC(INPUTN( &timePoint. , &INFORMAT. ) ) ;
		%LET timeStr1 = &timePointVal. ;
		%LET timeEnd1 = &timePointVal. ;
	%END;
	%IF %SYSEVALF( %SUPERQ( timeInterval ) ^= ) %THEN %DO; 
		%LET timeInterval = %KSUBSTR( &timeInterval. , 2  , %KLENGTH( &timeInterval. ) - 2 ) ;		
		%LET timeStr = %SYSFUNC( SCAN( %SUPERQ(timeInterval) , 1 , %STR(,) ) ) ;
		%LET timeStr = %SYSFUNC(INPUTN( &timeStr. , &INFORMAT. ) ) ;
		%LET timeEnd = %SYSFUNC( SCAN( %SUPERQ(timeInterval) , 2 , %STR(,) ) ) ;
		%LET timeEnd = %SYSFUNC(INPUTN( &timeEnd. , &INFORMAT. ) ) ;
                %IF %SYSEVALF(%SUPERQ(timePoint) =) %THEN %DO ;
                	%LET timeStr1 = &timeStr. ;
			%LET timeEnd1 = &timeEnd. ;
                 %END;
	%END;
	%ELSE %DO ;
                %IF %SYSEVALF( %SUPERQ(timePointVal) = ) %THEN %DO ;
			%PUT ERROR: Both timePoint AND timeInterval are invalid ; 
			%ABORT CANCEL ; 
		%END;
		%ELSE %DO ;
			%LET timeStr = &timeStr1. ; 
			%LET timeEnd = &timeEnd1. ;
		%END;
	%END;
	DATA &OUT. ; 
		SET &DSName. ; 
                IF &validToDttm. >= &timeStr1. AND 
                    &validFromDttm. <= &timeEnd1. AND
                    &validFromDttm. <= &timeEnd. AND 
		    &validToDttm. >= &timeStr. THEN OUTPUT  ;
	RUN;
%MEND ;

/*範例說明:*/
        /*範例一: 找出單一時間點的快照
	DATA testtimeSnapshotor ;
               format valid_from_dttm nldatm19. ;
	       format valid_to_dttm nldatm19. ; 
               valid_from_dttm = "01JAN2018 00:00:00"dt ; valid_to_dttm = "03JAN2018 23:59:59"dt ; 
               pkey = "NO1" ; value = 1 ; output ; 
               valid_from_dttm = "04JAN2018 00:00:00"dt ; valid_to_dttm = "07JAN2018 23:59:59"dt ; 
               pkey = "NO2" ; value = 2 ; output ; 
               valid_from_dttm = "08JAN2018 00:00:00"dt ; valid_to_dttm = "12JAN2018 23:59:59"dt ; 
               pkey = "NO3" ; value = 3 ; output ; 
               valid_from_dttm = "13JAN2018 00:00:00"dt ; valid_to_dttm = "19JAN2018 23:59:59"dt ; 
               pkey = "NO4" ; value = 4 ; output ; 
               valid_from_dttm = "20JAN2018 00:00:00"dt ; valid_to_dttm = "01JAN5999 00:00:00"dt ; 
               pkey = "NO5" ; value = 5 ; output ; 
        RUN ; 
  
         %DDS_timeSnapshotor(testtimeSnapshotor , timePoint=2018/01/02 00:00:00 ,OUT=tmp ) 
         */
         /*範例二: 找出指定時間區間的快照
	DATA testtimeSnapshotor ;
               format valid_from_dttm nldatm19. ;
	       format valid_to_dttm nldatm19. ; 
               valid_from_dttm = "01JAN2018 00:00:00"dt ; valid_to_dttm = "03JAN2018 23:59:59"dt ; 
               pkey = "NO1" ; value = 1 ; output ; 
               valid_from_dttm = "04JAN2018 00:00:00"dt ; valid_to_dttm = "07JAN2018 23:59:59"dt ; 
               pkey = "NO2" ; value = 2 ; output ; 
               valid_from_dttm = "08JAN2018 00:00:00"dt ; valid_to_dttm = "12JAN2018 23:59:59"dt ; 
               pkey = "NO3" ; value = 3 ; output ; 
               valid_from_dttm = "13JAN2018 00:00:00"dt ; valid_to_dttm = "19JAN2018 23:59:59"dt ; 
               pkey = "NO4" ; value = 4 ; output ; 
               valid_from_dttm = "20JAN2018 00:00:00"dt ; valid_to_dttm = "01JAN5999 00:00:00"dt ; 
               pkey = "NO5" ; value = 5 ; output ; 
        RUN ; 
	 %DDS_timeSnapshotor(testtimeSnapshotor , timeInterval=( 2018/01/02 00:00:00 , 2018/01/09 00:00:00) ,OUT=tmp2 ) 
	*/
 
