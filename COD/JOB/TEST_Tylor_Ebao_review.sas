/* nohup /sas94/config/Lev1/SASApp/BatchServer/sasbatch.sh -log /sas94/config/Lev1/SASApp/BatchServer/Logs/TEST_Tylor_Ebao_review_#Y.#m.#d_#H.#M.#s.log  -batch -noterminal -logparm "rollover=session"  -sysin /SASDATA/USER/Andy/TGLEDW/COD/JOB/TEST_Tylor_Ebao_review.sas & */

%MACRO currenttPath() ;
	%LOCAL thisFilePath ;
	%LET thisFilePath = %SYSFUNC(dequote( %SYSFUNC(getoption(sysin))%SUPERQ(_SASPROGRAMFILE) ) ) ;
	%GLOBAL currenttPath PathDlm;
        /*EDW_ENV.sas ©Ò¦b¥Ø¿ý(JOB)*/
	%LET currenttPath = %SUBSTR( %SUPERQ(thisFilePath) , 1 , %LENGTH(&thisFilePath.) - %LENGTH(%SCAN( %SUPERQ(thisFilePath) , -1 , %STR(/)%STR(\) ) ) ) ;
	%LET PathDlm = %SUBSTR( %sysfunc(reverse(%SUPERQ(currenttPath))) , 1 , 1 ) ;
	%LET currenttPath = %SUBSTR( %SUPERQ(thisFilePath) , 1 , %LENGTH(&thisFilePath.) - %LENGTH(%SCAN( %SUPERQ(thisFilePath) , -1 , %STR(/)%STR(\) ) ) - 1 ) ;
%MEND;
%currenttPath
%LET strTime = %sysfunc(datetime()) ; 
%put %sysfunc(putn(&strTime. , nldatm19. ) ) ;

%include "&currenttPath.&PathDlm.EDW_ENV.sas" ; 
%put Execute &rootPath.&rootPathDlm.COD&rootPathDlm.SAS&rootPathDlm.EBAO_ERDLoader.sas  ;
%include "&rootPath.&rootPathDlm.COD&rootPathDlm.SAS&rootPathDlm.EBAO_ERDLoader.sas" ;

%LET endTime = %sysfunc(datetime()  ) ; 
%put %sysfunc(putn(&endTime. , nldatm19. ) ) ;
%put run time cost: %sysfunc(putn(%SYSEVALF( &endTime. - &strTime.) , nltime19. ) ) ;


