/*作        者: Andy                                                                                                                         */
/*處理概要: 檢視指定目錄下所有 SAS code 資訊               */
/*輸    入: UserDefineGroup:User 自訂群組名稱                                                                                   
                , dir: 要搜尋的指定目錄
                , OUTDS: 存放結果的DataSet(Default:WORK.reviewSourceCodeRes                                */
/*輸    出:  OUTDS: 存放結果的DataSet                                                                                  */
/*相依核心: %readSrcCode       */

%MACRO DOC_srcDirReader( UserDefineGroup , 
                                      dir /*搜尋的目錄(最後不加反斜線)*/ , 
                                      OUTDS=reviewSourceCodeRes /*各程式碼的處理概要存放DataSetName*/) /minoperator mindelimiter=','  ;

        %LET dir = %QSYSFUNC( DEQUOTE( &dir. ) ) ; 
	%put %SUBSTR( &dir. , %length( &dir.)  , 1 ) ;  
	%IF %SUBSTR( &dir. , %length( &dir.)  , 1 ) IN ( %STR(\) , %STR(/) ) %THEN %DO ; 
		%LET dir = %SUBSTR( &dir. , 1 , %length( &dir.) -1  ) ;
	%END;
        %LET UserDefineGroup = %QSYSFUNC( DEQUOTE( &UserDefineGroup. ) ) ;
        %LET OUTDS = %SYSFUNC( DEQUOTE( &OUTDS. ) ) ;

        OPTIONS CMPLIB = work.funcs ;
        %MACRO Fmacro_desc() ;         
                %LET macro_path = %sysfunc( dequote( &macro_path. ) ) ; 
                %readSrcCode( "&macro_path." , "處.*理.*概.*要" , Fmacro_desc_OUT  ) 
        %MEND;  

        %MACRO Fmacro_author() ;         
                %LET macro_path = %sysfunc( dequote( &macro_path. ) ) ; 
                %readSrcCode( "&macro_path." , "作.*者" , Fmacro_author_OUT  ) 
        %MEND; 

         %MACRO Fmacro_input() ;         
                %LET macro_path = %sysfunc( dequote( &macro_path. ) ) ; 
                %readSrcCode( "&macro_path." , "輸.*入" , Fmacro_input_OUT  ) 
        %MEND;        

         %MACRO Fmacro_output() ;         
                %LET macro_path = %sysfunc( dequote( &macro_path. ) ) ; 
                %readSrcCode( "&macro_path." , "輸.*出" , Fmacro_output_OUT  ) 
        %MEND;   
 
        %MACRO Fmacro_kernel() ;         
                %LET macro_path = %sysfunc( dequote( &macro_path. ) ) ; 
                %readSrcCode( "&macro_path." , "相.*依.*核.*心" , Fmacro_kernel_OUT  ) 
        %MEND;     

        PROC FCMP outlib=work.funcs.Fmacro_desc ; 

                 FUNCTION Fmacro_desc( macro_path $ ) $   ;                        /* 回傳文字 */                                                                                
                         length Fmacro_desc_OUT  $ 32767 ;                                               /* 回傳文字長度宣告 */                                                                        
                         rc = run_macro('Fmacro_desc', macro_path ,Fmacro_desc_OUT ) ;                                                                        
                         return ( Fmacro_desc_OUT ) ;                                                                        
                 ENDSUB;

                FUNCTION Fmacro_author( macro_path $ ) $   ;                        /* 回傳文字 */                                                                                
                         length Fmacro_author_OUT  $ 32767 ;                                               /* 回傳文字長度宣告 */                                                                        
                         rc = run_macro('Fmacro_author', macro_path ,Fmacro_author_OUT ) ;                                                                        
                         return ( Fmacro_author_OUT ) ;                                                                        
                 ENDSUB;

                FUNCTION Fmacro_input( macro_path $ ) $   ;                        /* 回傳文字 */                                                                                
                         length Fmacro_input_OUT  $ 32767 ;                                               /* 回傳文字長度宣告 */                                                                        
                         rc = run_macro('Fmacro_input', macro_path ,Fmacro_input_OUT ) ;                                                                        
                         return ( Fmacro_input_OUT ) ;                                                                        
                 ENDSUB;

                 FUNCTION Fmacro_output( macro_path $ ) $   ;                        /* 回傳文字 */                                                                                
                         length Fmacro_output_OUT  $ 32767 ;                                               /* 回傳文字長度宣告 */                                                                        
                         rc = run_macro('Fmacro_output', macro_path ,Fmacro_output_OUT ) ;                                                                        
                         return ( Fmacro_output_OUT ) ;                                                                        
                 ENDSUB;

                 FUNCTION Fmacro_kernel( macro_path $ ) $   ;                        /* 回傳文字 */                                                                                
                         length Fmacro_kernel_OUT  $ 32767 ;                                               /* 回傳文字長度宣告 */                                                                        
                         rc = run_macro('Fmacro_kernel', macro_path ,Fmacro_kernel_OUT ) ;                                                                        
                         return ( Fmacro_kernel_OUT ) ;                                                                        
                 ENDSUB;

        OPTIONS CMPLIB = work.funcs;
	data dirList ;
		LENGTH dirListDesc $1000. ;
		stop ;
	run ;
	%MACRO insertdirListDesc( arg ) ; 
		proc sql noprint ; 
			insert into dirList 
				set dirListDesc= "%sysfunc(dequote(&args.))" ; 
			;
		quit; 
	%MEND ;
	%findExec( &dir. , ext=sas , cmd_prefix=' %insertdirListDesc(' ,cmd_suffix = ') ;'  )

        FILENAME cmd PIPE  "ls &dir./*.sas |cut -d' ' -f1 " ;
        DATA dirList ;
                INFILE cmd DLM='01'x DSD TRUNCOVER ;
                LENGTH dirListDesc $1000. ;
                INPUT dirListDesc $; 
        RUN ;

        DATA &OUTDS.( KEEP=UserDefineGroup 
                                             dirListDesc 
                                             macro_namepgm
                                             macro_typefunc
                                             macro_datelastmod    

                                             macro_input
                                             macro_output
                                             macro_author 
                                             macro_desc ) ;      
                FORMAT UserDefineGroup 
                                 dirListDesc 
                                 macro_namepgm
                                 macro_typefunc
                                 macro_datelastmod

                                 macro_input 
                                 macro_output 
                                 macro_author 
                                 macro_desc ;

                SET dirList ;
                IF KSCAN( dirListDesc , -1 , "/" ) EQ "reviewSourceCode.sas" THEN DELETE ; 
                LENGTH UserDefineGroup $100. ;

                LENGTH macro_desc $300. ;
                LENGTH macro_author $300. ;
                LENGTH macro_input $300. ;
                LENGTH macro_output $300. ;       

                UserDefineGroup = RESOLVE( "&UserDefineGroup." ) ;        

                macro_desc = compbl( Fmacro_desc( dirListDesc ) );    
                macro_author = compbl( Fmacro_author( dirListDesc ) );                    
                macro_input = compbl( Fmacro_input( dirListDesc ) );                      
                macro_output = compbl( Fmacro_output( dirListDesc ) );                  
        RUN; 

       PROC DATASETS LIB=WORK NOLIST NOWARN ;
                DELETE dirList funcs macroDesc_List ;
        RUN ;
        
%MEND ;
/*範例說明:*/
	/*範例一:
	%include "/SASDATA/USER/TGLEDW/COD/MCR/findExec.sas" ;
	%findExec( "/SASDATA/USER/TGLEDW/COD/MCR" , ext=sas , cmd_prefix=' %include "' ,cmd_suffix = '";'  )
	options mprint ; 
	%DOC_srcDirReader( MACRO , 
	                       /SASDATA/USER/TGLEDW/COD/MCR  , 
	                       OUTDS=reviewSourceCodeRes )

	*/
