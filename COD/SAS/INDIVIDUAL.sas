/*�M        ��: Claim Fraud P2-2 ebao*/
/*�{���W��: INDIVIDUAL.SAS*/
/*�@        ��: Linda */
/*��        ��: 2018/05/04 */

/*�B�z���n: 

�X�֨� INDIVIDUAL */

/*��    �J:   

/*��    �X:  EDWSTG.INDIVIDUAL(IAA format) */

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

/*INPUT T_CONTRACT_BENE�̭����@��PARTY_ID, �� OUTPUT INDIVIDUAL�]���@��PARTY_ID
���γ~�Υت��O��^��*/

/*�ӤH*/
DATA  WORK.TMP_CONTRACT_BENE (DROP=CERTI_CODE label="��O��ɪ����q�H��");
    FORMAT 
                    PARTY_ID $char100.  
                    INDIVIDUAL_TYPE_CD $char1.  
                    LITIGATION_IND $char1. 
                    ;
    LABEL 
                    PARTY_ID = "���Y�H�N��" 
                    INDIVIDUAL_TYPE_CD = "���O_1�O����q�H2�z�ߨ��q�H"
                    LITIGATION_IND = "���O_�D�^"
                    ;
    SET  EDWEBA.T_CONTRACT_BENE(KEEP=CERTI_CODE WHERE = (CMISS(CERTI_CODE ) = 0)) ;
            PARTY_ID  = (TRIM(UPCASE(CERTI_CODE)) );
            INDIVIDUAL_TYPE_CD =  ('1')  ; 
            LITIGATION_IND =  ('N') ;
RUN;



/*�ӤH�ƬG��ɨ��q�H*/
DATA  WORK.TMP_CLM_BENE_FILTERED1 (label="��CUSTOMER_ID�D�ťժ��ƬG��ɨ��q�H��");
    SET  EDWEBA.T_CLM_CONTRACT_BENE(KEEP=CUSTOMER_ID WHERE = (CMISS(CUSTOMER_ID ) = 0)) ;
RUN;

PROC SQL;
   CREATE TABLE WORK.TMP_CLM_BENE_JOINED AS 
   SELECT  
            (TRIM(UPCASE(t2.CERTI_CODE))) FORMAT=$CHAR100. LENGTH=100 LABEL="���Y�H�N��" AS PARTY_ID, 
            ('2') FORMAT=$CHAR1. LENGTH=1 LABEL="���O_1�O����q�H2�z�ߨ��q�H" AS INDIVIDUAL_TYPE_CD,
            ('N') FORMAT=$CHAR1. LENGTH=1 LABEL="���O_�D�^" AS LITIGATION_IND
      FROM WORK.TMP_CLM_BENE_FILTERED1 t1
           LEFT JOIN EDWEBA.T_CLM_CUSTOMER t2 ON (t1.CUSTOMER_ID = t2.CUSTOMER_ID)
      ORDER BY PARTY_ID,
               INDIVIDUAL_TYPE_CD;
QUIT;

DATA  WORK.TMP_CLM_BENE_FILTERED2 ( label="�z���ʤ����Ҹ�");
    SET  WORK.TMP_CLM_BENE_JOINED (WHERE = (CMISS(PARTY_ID ) = 0)) ;
RUN;

/*���q*/
DATA  WORK.TMP_CLM_BENE_FILTERED1A (label="��COMPANY_ID�D�ťժ��ƬG��ɨ��q�H��");
    SET  EDWEBA.T_CLM_CONTRACT_BENE(KEEP=COMPANY_ID WHERE = (CMISS(COMPANY_ID ) = 0)) ;
RUN;

PROC SQL;
   CREATE TABLE WORK.TMP_CLM_BENE_JOINEDA AS 
   SELECT  
            (TRIM(UPCASE(t2.REGISTER_CODE))) FORMAT=$CHAR100. LENGTH=100 LABEL="���Y�H�N��" AS PARTY_ID, 
            ('2') FORMAT=$CHAR1. LENGTH=1 LABEL="���O_1�O����q�H2�z�ߨ��q�H" AS INDIVIDUAL_TYPE_CD,
            ('N') FORMAT=$CHAR1. LENGTH=1 LABEL="���O_�D�^" AS LITIGATION_IND
      FROM WORK.TMP_CLM_BENE_FILTERED1A t1
           LEFT JOIN EDWEBA.T_CLM_COMPANY_CUSTOMER t2 ON (t1.COMPANY_ID = t2.COMPANY_ID)
      ORDER BY PARTY_ID,
               INDIVIDUAL_TYPE_CD;
QUIT;

DATA  WORK.TMP_CLM_BENE_FILTERED2A ( label="�z���ʲνs");
    SET  WORK.TMP_CLM_BENE_JOINEDA (WHERE = (CMISS(PARTY_ID ) = 0)) ;
RUN;



/*�ӤHCUR*/
DATA  WORK.TMP_CLM_BENE_CUR_FILTERED1 (label="�z����CUSTOMER_ID���z�ߨ��q�H�� CUR");
    SET  EDWEBA.T_CLM_CONTRACT_BENE_CUR(KEEP=CUSTOMER_ID WHERE = (CMISS(CUSTOMER_ID ) = 0)) ;
RUN;

PROC SQL;
   CREATE TABLE WORK.TMP_CLM_BENE_CUR_JOINED AS 
   SELECT  
            (TRIM(UPCASE(t2.CERTI_CODE))) FORMAT=$CHAR100. LENGTH=100 LABEL="���Y�H�N��" AS PARTY_ID, 
            ('2') FORMAT=$CHAR1. LENGTH=1 LABEL="���O_1�O����q�H2�z�ߨ��q�H" AS INDIVIDUAL_TYPE_CD,
            ('N') FORMAT=$CHAR1. LENGTH=1 LABEL="���O_�D�^" AS LITIGATION_IND
      FROM WORK.TMP_CLM_BENE_CUR_FILTERED1 t1
           LEFT JOIN EDWEBA.T_CLM_CUSTOMER t2 ON (t1.CUSTOMER_ID = t2.CUSTOMER_ID)
      ORDER BY PARTY_ID,
               INDIVIDUAL_TYPE_CD;
QUIT;

DATA  WORK.TMP_CLM_BENE_CUR_FILTERED2 ( label="�z���ʤ����Ҹ� CUR");
    SET  WORK.TMP_CLM_BENE_CUR_JOINED (WHERE = (CMISS(PARTY_ID ) = 0)) ;
RUN;

/*���qCUR*/
DATA  WORK.TMP_CLM_BENE_CUR_FILTERED1A (label="��COMPANY_ID�D�ťժ��ƬG��ɨ��q�H��");
    SET  EDWEBA.T_CLM_CONTRACT_BENE(KEEP=COMPANY_ID WHERE = (CMISS(COMPANY_ID ) = 0)) ;
RUN;

PROC SQL;
   CREATE TABLE WORK.TMP_CLM_BENE_CUR_JOINEDA AS 
   SELECT  
            (TRIM(UPCASE(t2.REGISTER_CODE))) FORMAT=$CHAR100. LENGTH=100 LABEL="���Y�H�N��" AS PARTY_ID, 
            ('2') FORMAT=$CHAR1. LENGTH=1 LABEL="���O_1�O����q�H2�z�ߨ��q�H" AS INDIVIDUAL_TYPE_CD,
            ('N') FORMAT=$CHAR1. LENGTH=1 LABEL="���O_�D�^" AS LITIGATION_IND
      FROM WORK.TMP_CLM_BENE_CUR_FILTERED1A t1
           LEFT JOIN EDWEBA.T_CLM_COMPANY_CUSTOMER t2 ON (t1.COMPANY_ID = t2.COMPANY_ID)
      ORDER BY PARTY_ID,
               INDIVIDUAL_TYPE_CD;
QUIT;

DATA  WORK.TMP_CLM_BENE_CUR_FILTERED2A ( label="�z���ʲνs");
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


/*�L�X DATA STRUCTURE
data test ;
    if 0 then set EDWEBA.T_CONTRACT_BENE ;
     stop ;
run ;
*/
