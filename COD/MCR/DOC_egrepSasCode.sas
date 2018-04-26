/*巨集名稱: DOC_egrepSasCode                                                                                      */
/*作        者: Andy                                                                                                      */
/*處理概要: 尋找滿足內容有關鍵字的程式                                                   */
/*輸    入: pattern(關鍵字:Regular Expressions) ,code_dir(程式所在目錄)                                         */
/*輸    出:                                                                                                                */
/*其    他:  pattern中可包含模糊字眼以*取代                                                   */
%MACRO DOC_egrepSasCode( pattern ,code_dir , OUT=egrepRes) /minoperator mindelimiter=',' ;

	%IF %upcase(&SYSSCPL.) IN ( LINUX , %str(HP-UX) ,AIX , SUNOS )  %THEN  %DO ;
		%PUT NOTE: environment is ok ; 
	%END; 
	%ELSE %DO ;
		%PUT ERROR: execute egrepSasCode only in unix like system ;
		%ABORT CANCEL ;
	%END ;
	%LOCAL cmd ;
        %LET code_dir = %sysfunc(dequote( &code_dir. ) ) ;
        %LET pattern = %qsysfunc( dequote( &pattern. ) ) ;
        %LET pattern = %sysfunc( tranwrd( &pattern. ,*  ,.* ) ) ;
	%LET cmd =  "cd &code_dir. ; egrep -sin '&pattern.' *.sas" ; 
	
	FILENAME test pipe &cmd.;
        DATA &OUT.;
                infile test truncover;
                input line $char1000. ;
        RUN;

%MEND;

/*範例說明:*/
	/*範例一: 找/SASDATA/USER/TGLEDW/COD/MCR 有包含 macro egrep 的程式與所在行數 
		options mprint; 
		%DOC_egrepSasCode( "macro.*egrep"  , "/SASDATA/USER/TGLEDW/COD/MCR" ) 
		res: 
			egrepSasCode.sas:7:%MACRO egrepSasCode( pattern ,code_dir , OUT=egrepRes) ;
			egrepSasCode.sas:25:		%egrepSasCode( ""macro.*egrep""  , ""/SASDATA/UER/TGLEDW/COD/MCR"" )
	*/
