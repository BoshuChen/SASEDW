/*專        案: Claim Fraud P2-2 ebao*/
/*程式名稱: INDIVIDUAL.SAS*/
/*作        者: Linda */
/*日        期: 2018/05/04 */

/*處理概要: 

合併到 INDIVIDUAL */

/*輸    入:   

/*輸    出:  EDWSTG.INDIVIDUAL(IAA format) */

%let _sdtm=%sysfunc(datetime());

data _NULL_;
put "=====================================================================";
put "PROGRAM LOG======INDIVIDUAL Start Datetime: %sysfunc(datetime(),nldatm19.)";
put "=====================================================================";
run;

/*I0000============================== MOVE TO TGLEDW/COD/JOB/EDW_ENV.SAS*/
libname edweba oracle path=odsls schema=LS_EBAO user=edweba password="edw12345" ;
libname edwESP oracle path=odsls schema=ESP user=edweba password="edw12345" ;
libname AMLESP oracle path=odsprod schema=ESP user=aml password="am123456" ;
libname EDWSTG "/SASDATA/USER/TGLEDW/LIB/STG";

%macro AppendTable(InputLib, InputTableName, OutLib, OutputTableName);
   %DO;
            PROC APPEND BASE= &OutLib.&OutputTableName DATA= &Inputlib.&InputTableName force; RUN;
   %END;
%mend;

/*INPUT T_CONTRACT_BENE裡面有一個PARTY_ID, 而 OUTPUT INDIVIDUAL也有一個PARTY_ID
但用途及目的是兩回事*/

/*個人*/
DATA  WORK.TMP_CONTRACT_BENE (DROP=CERTI_CODE label="投保當時的受益人檔");
    FORMAT 
                    PARTY_ID $char100.  
                    INDIVIDUAL_TYPE_CD $char1.  
                    LITIGATION_IND $char1. 
                    ;
    LABEL 
                    PARTY_ID = "關係人代號" 
                    INDIVIDUAL_TYPE_CD = "類別_1保單受益人2理賠受益人"
                    LITIGATION_IND = "註記_訴訟"
                    ;
    SET  EDWEBA.T_CONTRACT_BENE(KEEP=CERTI_CODE WHERE = (CMISS(CERTI_CODE ) = 0)) ;
            PARTY_ID  = (TRIM(UPCASE(CERTI_CODE)) );
            INDIVIDUAL_TYPE_CD =  ('1')  ; 
            LITIGATION_IND =  ('N') ;
RUN;



/*個人事故當時受益人*/
DATA  WORK.TMP_CLM_BENE_FILTERED1 (label="選CUSTOMER_ID非空白的事故當時受益人檔");
    SET  EDWEBA.T_CLM_CONTRACT_BENE(KEEP=CUSTOMER_ID WHERE = (CMISS(CUSTOMER_ID ) = 0)) ;
RUN;

PROC SQL;
   CREATE TABLE WORK.TMP_CLM_BENE_JOINED AS 
   SELECT  
            (TRIM(UPCASE(t2.CERTI_CODE))) FORMAT=$CHAR100. LENGTH=100 LABEL="關係人代號" AS PARTY_ID, 
            ('2') FORMAT=$CHAR1. LENGTH=1 LABEL="類別_1保單受益人2理賠受益人" AS INDIVIDUAL_TYPE_CD,
            ('N') FORMAT=$CHAR1. LENGTH=1 LABEL="註記_訴訟" AS LITIGATION_IND
      FROM WORK.TMP_CLM_BENE_FILTERED1 t1
           LEFT JOIN EDWEBA.T_CLM_CUSTOMER t2 ON (t1.CUSTOMER_ID = t2.CUSTOMER_ID)
      ORDER BY PARTY_ID,
               INDIVIDUAL_TYPE_CD;
QUIT;

DATA  WORK.TMP_CLM_BENE_FILTERED2 ( label="篩掉缺分身證號");
    SET  WORK.TMP_CLM_BENE_JOINED (WHERE = (CMISS(PARTY_ID ) = 0)) ;
RUN;

/*公司*/
DATA  WORK.TMP_CLM_BENE_FILTERED1A (label="選COMPANY_ID非空白的事故當時受益人檔");
    SET  EDWEBA.T_CLM_CONTRACT_BENE(KEEP=COMPANY_ID WHERE = (CMISS(COMPANY_ID ) = 0)) ;
RUN;

PROC SQL;
   CREATE TABLE WORK.TMP_CLM_BENE_JOINEDA AS 
   SELECT  
            (TRIM(UPCASE(t2.REGISTER_CODE))) FORMAT=$CHAR100. LENGTH=100 LABEL="關係人代號" AS PARTY_ID, 
            ('2') FORMAT=$CHAR1. LENGTH=1 LABEL="類別_1保單受益人2理賠受益人" AS INDIVIDUAL_TYPE_CD,
            ('N') FORMAT=$CHAR1. LENGTH=1 LABEL="註記_訴訟" AS LITIGATION_IND
      FROM WORK.TMP_CLM_BENE_FILTERED1A t1
           LEFT JOIN EDWEBA.T_CLM_COMPANY_CUSTOMER t2 ON (t1.COMPANY_ID = t2.COMPANY_ID)
      ORDER BY PARTY_ID,
               INDIVIDUAL_TYPE_CD;
QUIT;

DATA  WORK.TMP_CLM_BENE_FILTERED2A ( label="篩掉缺統編");
    SET  WORK.TMP_CLM_BENE_JOINEDA (WHERE = (CMISS(PARTY_ID ) = 0)) ;
RUN;



/*個人CUR*/
DATA  WORK.TMP_CLM_BENE_CUR_FILTERED1 (label="篩掉缺CUSTOMER_ID的理賠受益人檔 CUR");
    SET  EDWEBA.T_CLM_CONTRACT_BENE_CUR(KEEP=CUSTOMER_ID WHERE = (CMISS(CUSTOMER_ID ) = 0)) ;
RUN;

PROC SQL;
   CREATE TABLE WORK.TMP_CLM_BENE_CUR_JOINED AS 
   SELECT  
            (TRIM(UPCASE(t2.CERTI_CODE))) FORMAT=$CHAR100. LENGTH=100 LABEL="關係人代號" AS PARTY_ID, 
            ('2') FORMAT=$CHAR1. LENGTH=1 LABEL="類別_1保單受益人2理賠受益人" AS INDIVIDUAL_TYPE_CD,
            ('N') FORMAT=$CHAR1. LENGTH=1 LABEL="註記_訴訟" AS LITIGATION_IND
      FROM WORK.TMP_CLM_BENE_CUR_FILTERED1 t1
           LEFT JOIN EDWEBA.T_CLM_CUSTOMER t2 ON (t1.CUSTOMER_ID = t2.CUSTOMER_ID)
      ORDER BY PARTY_ID,
               INDIVIDUAL_TYPE_CD;
QUIT;

DATA  WORK.TMP_CLM_BENE_CUR_FILTERED2 ( label="篩掉缺分身證號 CUR");
    SET  WORK.TMP_CLM_BENE_CUR_JOINED (WHERE = (CMISS(PARTY_ID ) = 0)) ;
RUN;

/*公司CUR*/
DATA  WORK.TMP_CLM_BENE_CUR_FILTERED1A (label="選COMPANY_ID非空白的事故當時受益人檔");
    SET  EDWEBA.T_CLM_CONTRACT_BENE(KEEP=COMPANY_ID WHERE = (CMISS(COMPANY_ID ) = 0)) ;
RUN;

PROC SQL;
   CREATE TABLE WORK.TMP_CLM_BENE_CUR_JOINEDA AS 
   SELECT  
            (TRIM(UPCASE(t2.REGISTER_CODE))) FORMAT=$CHAR100. LENGTH=100 LABEL="關係人代號" AS PARTY_ID, 
            ('2') FORMAT=$CHAR1. LENGTH=1 LABEL="類別_1保單受益人2理賠受益人" AS INDIVIDUAL_TYPE_CD,
            ('N') FORMAT=$CHAR1. LENGTH=1 LABEL="註記_訴訟" AS LITIGATION_IND
      FROM WORK.TMP_CLM_BENE_CUR_FILTERED1A t1
           LEFT JOIN EDWEBA.T_CLM_COMPANY_CUSTOMER t2 ON (t1.COMPANY_ID = t2.COMPANY_ID)
      ORDER BY PARTY_ID,
               INDIVIDUAL_TYPE_CD;
QUIT;

DATA  WORK.TMP_CLM_BENE_CUR_FILTERED2A ( label="篩掉缺統編");
    SET  WORK.TMP_CLM_BENE_CUR_JOINEDA (WHERE = (CMISS(PARTY_ID ) = 0)) ;
RUN;


/*PM000_MERGE*/

PROC DATASETS Lib=EDWSTG ;
    delete INDIVIDUAL ;
RUN;

%AppendTable(WORK. , TMP_CONTRACT_BENE, WORK. , TMP_INDIVIDUAL);
%AppendTable(WORK. , TMP_CLM_BENE_FILTERED2, WORK.,  TMP_INDIVIDUAL);
%AppendTable(WORK. , TMP_CLM_BENE_FILTERED2A, WORK.,  TMP_INDIVIDUAL);
%AppendTable(WORK. , TMP_CLM_BENE_CUR_FILTERED2, WORK.,  TMP_INDIVIDUAL);
%AppendTable(WORK. , TMP_CLM_BENE_CUR_FILTERED2A, WORK.,  TMP_INDIVIDUAL);


PROC SORT DATA= WORK.TMP_INDIVIDUAL ;
     BY   PARTY_ID  INDIVIDUAL_TYPE_CD 
           ;
RUN;
PROC SORT DATA= WORK.TMP_INDIVIDUAL
    out=edwstg.INDIVIDUAL
     NODUPKEY ;
     BY  PARTY_ID  INDIVIDUAL_TYPE_CD ;
RUN;

PROC DATASETS Lib=WORK ;
    delete TMP_: ;
RUN;

%let _edtm=%sysfunc(datetime());
%let _runtm=%sysfunc(putn(&_edtm - &_sdtm, 12.4));


data _NULL_;
put "=====================================================================";
put "PROGRAM LOG======INDIVIDUAL End Datetime: %sysfunc(datetime(),nldatm19.)";
put "=====================================================================";
run;

%put =========================The INDIVIDUAL program took &_runtm seconds to run;


/*印出 DATA STRUCTURE
data test ;
    if 0 then set EDWEBA.T_CONTRACT_BENE ;
     stop ;
run ;
*/
