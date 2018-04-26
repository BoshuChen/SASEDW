/*作        者: Andy                                                                                                                         */
/*處理概要: 計算PSI 指標                                                          					     */
/*輸    入:  MODELVAR: 要計算的變數
		 PSILibrary: 讀取及存放結果的目錄
		 SourceData1: 要比較的資料集1 
		 SourceData2 : 要比較的資料集2  */
/*輸    出:  N/A                                                                                                                                  */
/*相依核心: N/A                                                                                                                           */
/* 備註: http://support.sas.com/resources/papers/proceedings10/288-2010.pdf                   */
%MACRO DQ_PSICalculator( MODELVAR , PSILibrary , SourceData1 , SourceData2  , PSIVAR=PSI) ;
	%LET PSILibrary = %SYSFUNC(dequote( &PSILibrary. ) ) ;
	%GLOBAL &PSIVAR. ; 

/* BEGIN Steps to get the data samples for the periods being compared */
	LIBNAME PSI "&PSILibrary";
	DATA PSI.PSISample1;
	SET &SourceData1
	(Keep=&MODELVAR)
	;
	Format &MODELVAR 12.2;
	/******************************************************************/
	/* This is where you can place more SAS statements to modify your */
	/* PSI Variable so it accurately represents the format and value */
	/* in your model. */
	/******************************************************************/
	RUN;
	DATA PSI.PSISample2;
	SET &SourceData2
	(Keep=&MODELVAR)
	;
	Format &MODELVAR 12.2;
	/******************************************************************/
	/* This is where you can place more SAS statements to modify your */
	/* PSI Variable so it accurately represents the format and value */
	/* in your model. */
	/******************************************************************/
	RUN;
	/* END Steps to get the data samples for the periods being compared */
	/********************************************************************/
	/**********************************/
	/*BEGIN establish ODS Output File */
	ODS Listing Close;
	ODS HTML
	Style=default
	File="&PSILibrary\PSICode&MODELVAR..htm"
	;
	Title2 "PSI (Population Stability Index) Calculations for &MODELVAR";
	/**************************/
	/* BEGIN PSI Calculations */
	/************************************/
	/* BEGIN break Sample1 into bins */
	/* BEGIN Sorting & Ranking process */
	Proc Means Noprint Data=PSI.PSISample1 ;
	Output
	Out=PSI.RankedTotal (rename=(_freq_=RankedTotal))
	;
	run;
	Data _Null_;
	Set PSI.RankedTotal (Where=(_Type_=0));
	Call Symput('RankedTotal',RankedTotal);
	run;
	Proc Means Noprint Data=PSI.PSISample2;
	Output
	Out=PSI.RankedTotal2 (rename=(_freq_=RankedTotal2))
	;
	run;
	Data _Null_;
	Set PSI.RankedTotal2 (Where=(_Type_=0));
	Call Symput('RankedTotal2',RankedTotal2);
	run;
	Proc Sort
	Data=PSI.PSISample1;
	By &MODELVAR;
	run;
	Proc Sort
	Data=PSI.PSISample2;
	By &MODELVAR;
	run;
	/*********************************************************************/
	/*BEGIN Use the Program Data Vector to override the binning of Zero's*/
	Data PSI.PSISample1 (Keep=BinVar);
	Set PSI.PSISample1;
	BinVar=Sum(&MODELVAR,(_n_/&RankedTotal));
	run;
	Data PSI.PSISample2 (Keep=BinVar);
	Set PSI.PSISample2;
	BinVar=Sum(&MODELVAR,(_n_/&RankedTotal2));
	run;
	/*END Use the Program Data Vector to override the binning of Zero's*/
	/*******************************************************************/
	Proc Sort
	Data=PSI.PSISample1;
	By BinVar;
	run;
	Proc Sort
	Data=PSI.PSISample2;
	By BinVar;
	run;
	Proc Format;
	Value DecileF
	Low-0='00'
	0-.1='01'
	.1-.2='02'
	.2-.3='03'
	.3-.4='04'
	.4-.5='05'
	.5-.6='06'
	.6-.7='07'
	.7-.8='08'
	.8-.9='09'
	.9-1='10'
	.='11'
	;
	Value DemiDecileF
	Low-0='00'
	0-.05='01'
	.05-.1='02'
	.1-.15='03'
	.15-.2='04'
	.2-.25='05'
	.25-.3='06'
	.3-.35='07'
	.35-.4='08'
	.4-.45='09'
	.45-.5='10'
	.5-.55='11'
	.55-.6='12'
	.6-.65='13'
	.65-.7='14'
	.7-.75='15'
	.75-.8='16'
	.8-.85='17'
	.85-.9='18'
	.9-.95='19'
	.95-1='20'
	.='21'
	;
	Value ZeroMiss
	0='Zero'
	11='Missing'
	21='Missing'
	;
	run;
	Data PSI.PSISample1;
	Length decile 8.;
	Set PSI.PSISample1;
	Rank=_n_/&RankedTotal;
	Decile=Put(Rank,DecileF.);
	run;
	/* END Sorting & Ranking process */
	/* END break Sample1 into 10 bins */
	/**********************************/
	/*********************************************************************/
	/* BEGIN you can see they are 10 equally sized bins with no ties in */
	/* the output of this step. */
	proc freq data=PSI.PSISample1;
	tables decile / out=PSI.out1;
	Title3 'Base-Line Sample Frequency By Decile Bin (Data=PSISample1)';
	run;
	/* END you can see they are 10 equally sized bins with no ties in */
	/* the output of this step. */
	/*********************************************************************/
	/******************************************************/
	/* BEGIN Calculate how the deciles are defined on the */
	/* Supplied Variable (MODELVAR) scale */
	/* so I want MAX(MODELVAR) in each decile */
	proc means data=PSI.PSISample1 nway;
	class decile;
	var BinVar;
	output out=PSI.endpoints max=maxVar;
	Title3 'Base-Line Sample Mean, Max & Min Values (Data=PSISample1)';
	run;
	/* END Calculate how the deciles are defined on the */
	/* Supplied Variable (MODELVAR) scale */
	/* so I want MAX(MODELVAR) in each decile */
	/******************************************************/
	/*****************************************************************************/
	/* BEGIN Data Step to write code that applies the above decile definition to */
	/* the data set with MODELVAR on it */
	data _NULL_;
	set PSI.endpoints end=last;
	file "&PSILibrary\decileSample1.sas";
	if _N_ = 1 then put " select;";
	put " when (BinVar le " maxVar ") decile = " decile ";" ;
	if last then do ;
	put " otherwise decile = " decile ";" ;
	put "end;";
	call symput('maxbin',decile);
	end;
	run;
	data PSI.PSISample2;
	set PSI.PSISample2;
	%inc "&PSILibrary\decileSample1.sas" / source;
	If BinVar=. Then decile=&maxbin;
	run;
	/* END Data Step to write code that applies the above decile definition to */
	/* the data set with MODELVAR on it */
	/*********************************************************************/
	/*********************************************************************/
	/* BEGIN Use the same definition for the buckets to establish how */
	/* much data falls in each group for the sample 2 */
	proc freq data=PSI.PSISample2;
	tables decile / out=PSI.out2;
	Title3 'Current Sample Frequency By Decile Bin (Data=PSISample2)';
	run;
	/* END Use the same definition for the buckets to establish how */
	/* much data falls in each group for the sample 2 */
	/*********************************************************************/
	/************************************************************************************/
	/* BEGIN put the % fields on the same file and calculate the terms that make up PSI */
	data PSI.PSICompare;
	merge PSI.out1 PSI.out2(rename=(percent=percent2));
	by decile;
	psi = log(percent/percent2)*(percent-percent2)/100;
	run;
	proc print data=PSI.PSICompare noobs;
	var dec: per:;
	Format decile ZeroMiss.;
	sum psi;
	Title3 "NOTE: PSI Calc Accomodates the Binning of Zero And Missing";
	run;
	/* END put the % fields on the same file and calculate the terms that make up PSI */
	/**********************************************************************************/
	/* END PSI Calculations */
	/************************/
	ODS _ALL_ Close;
	ODS Listing;
	/*END establish ODS Output File */
	/********************************/
	proc sql noprint ;
		select sum( psi ) 
		into : &PSIVAR.
		from PSI.PSICompare
		;
	quit ; 

%MEND; 

/* 範例說明 */
	/*範例1: 產生兩組隨機樣本測試PSI指標
	LIBNAME PSI "/SASDATA/USER/UAT/PSI/" ;
	data PSI.sample1 (keep=score);
		call streaminit(123);      
		do i = 1 to 10000;
		   score = rand("Uniform");    
		   output;
		end;
	run;
	data PSI.sample2 (keep=score);
		call streaminit(456);       
		do i = 1 to 10000;
		   score = rand("Uniform"); 
		   output;
		end;
	run;
	%DQ_PSICalculator( score , "/SASDATA/USER/UAT/PSI/" , PSI.sample1 , PSI.sample2 ) 
	%PUT &PSI. ; 	
	*/
