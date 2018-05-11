/*專        案: Claim Fraud P2-2 ebao*/
/*程式名稱: PARTY.SAS*/
/*作        者: Linda */
/*日        期: 2018/04/24 */
/*處理概要: 將ebao 身分證字號相關檔的party id, certi_code 合併到 party, 依照 UPDATE_TIMESTAMP desc. 去重覆(身分證+PARTY_TYPE) */
/*輸    入:   
 1   EDWEBA.T_AGENT
 2   EDWEBA.T_CONTRACT_BENE
 3   EDWEBA.T_CUSTOMER
 4   EDWEBA.T_EMPLOYEE
 5   EDWEBA.T_INSURED_LIST
 6   EDWEBA.T_PAYER
 7   EDWEBA.T_POLICY_HOLDER 
 8  AMLESP.HR_EMP ;

*/
/*輸    出:  EDWSTG.PARTY(IAA format) */

/*I0000============================== MOVE TO TGLEDW/COD/JOB/EDW_ENV.SAS*/
libname edweba oracle path=odsls schema=LS_EBAO user=edweba password="edw12345" ;
libname edwESP oracle path=odsls schema=ESP user=edweba password="edw12345" ;
libname AMLESP oracle path=odsprod schema=ESP user=aml password="am123456" ;
libname EDWSTG "/SASDATA/USER/TGLEDW/LIB/STG";

/*M0000=====================================================*/
%macro CreateTmpTable(InputLibParty, InputLibTable, InputTableName, FieldPartyId);
%DO;
            PROC SQL;
               CREATE TABLE WORK.TMP_Party&InputTableName AS 
               SELECT    
                        (upper(CERTI_code)) FORMAT=$char50. LENGTH=50 LABEL="身分證字號" AS TglCertiCode, 
                        (t2.PARTY_TYPE) FORMAT=$char20. LENGTH=20 LABEL="關係人類別碼" AS Party_Type_Cd, 
                        ('EBAO') FORMAT=$char10. LENGTH=10 LABEL="編號_應用系統" AS TglAp, 
                        (left(PUT(t2.PARTY_ID,22.))) FORMAT=$char22. LENGTH=22 LABEL="關係人編號_應用系統內部" AS TglPartyIdAp,
                        ("&InputTableName") FORMAT=$char50. LENGTH=50 LABEL="編號_應用系統_檔案名" AS TglApTable,
                         (t1.UPDATE_TIMESTAMP) FORMAT=datetime20. LENGTH=8 LABEL="日期時間_更新" AS UpdateTimeStamp
                 FROM &InputLibTable.&InputTableName t1 
                       LEFT JOIN &InputLibParty.T_PARTY t2 ON ( t1.&FieldPartyId = t2.PARTY_ID)                ;
            QUIT;

            PROC SORT DATA= WORK.TMP_Party&InputTableName ;
                     BY   TglCertiCode
                              Party_Type_Cd 
                           descending UpdateTimeStamp  ;
            RUN;

            PROC SORT DATA= WORK.TMP_Party&InputTableName
                     NODUPKEY ;
                     BY TglCertiCode Party_Type_Cd ;
            RUN;
   %END;
%mend;


%MACRO CreateCntTable(InputLib, InputTableName, OutLib, OutputTableName);
    %DO;
        PROC SQL;
           CREATE TABLE &Outlib.&OutputTableName AS 
            SELECT  
                    ("&InputTableName") FORMAT=$CHAR50. LENGTH=50 AS TableName, 
                     (COUNT(TglPartyIdAp)) FORMAT=COMMA13.  AS COUNT_of_TglPartyIdAp
              FROM &InputLib.&InputTableName;
           
        QUIT;
    %END;
%MEND;

%macro AppendTable(InputLib, InputTableName, OutLib, OutputTableName);
   %DO;
            PROC APPEND BASE= &OutLib.&OutputTableName DATA= &Inputlib.&InputTableName force; RUN;
   %END;
%mend;

/*P1000===========================================================main process*/
%CreateTmpTable(EDWEBA. , EDWEBA. , T_CUSTOMER, customer_id);
PROC SQL;
   CREATE TABLE WORK.T_EMPLOYEE 
   AS  SELECT    T1.CERTI_code, t1.UPDATE_TIMESTAMP,  t3.CUSTOMER_ID 
   FROM EDWEBA.T_EMPLOYEE t1
           LEFT JOIN EDWEBA.T_CUSTOMER t3 ON (t1.EMP_ID = t3.CUSTOMER_ID);
QUIT;
%CreateTmpTable( EDWEBA. ,WORK. , T_EMPLOYEE, customer_id);
%CreateTmpTable( EDWEBA. ,EDWEBA. , T_AGENT, party_id);
%CreateTmpTable( EDWEBA. ,EDWEBA. , T_CONTRACT_BENE, party_id);
%CreateTmpTable( EDWEBA. ,EDWEBA. , T_INSURED_LIST, party_id);
%CreateTmpTable( EDWEBA. ,EDWEBA. , T_PAYER, party_id);
%CreateTmpTable( EDWEBA. ,EDWEBA. , T_POLICY_HOLDER, party_id);

/* !!!!!  AMLESP*/
PROC SQL;
CREATE TABLE WORK.TMP_PartyHR_EMP AS 
SELECT    
        (upper(PERSON_ID)) FORMAT=$char50. LENGTH=50 LABEL="身分證字號" AS TglCertiCode, 
        ('1') FORMAT=$char20. LENGTH=20 LABEL="關係人類別碼" AS Party_Type_Cd, 
        ('EBAO') FORMAT=$char10. LENGTH=10 LABEL="編號_應用系統" AS TglAp, 
        (EMP_ID) FORMAT=$char22. LENGTH=22 LABEL="關係人編號_應用系統內部" AS TglPartyIdAp,
        ('HR_EMP') FORMAT=$char50. LENGTH=50 LABEL="編號_應用系統_檔案名" AS TglApTable,
         (LAST_UPDATE_TIME) FORMAT=datetime20. LENGTH=8 LABEL="日期時間_更新" AS UpdateTimeStamp
 FROM  AMLESP.HR_EMP 
;
QUIT;

PROC SORT DATA= WORK.TMP_PartyHR_EMP ;
     BY   TglCertiCode Party_Type_Cd 
           descending UpdateTimeStamp  ;
RUN;
PROC SORT DATA= WORK.TMP_PartyHR_EMP
     NODUPKEY ;
     BY TglCertiCode Party_Type_Cd ;
RUN;


/* output=work.tmp_party*/
%AppendTable(WORK. , TMP_PartyT_AGENT, WORK. , TMP_PARTY);
%AppendTable(WORK. , TMP_PartyT_Contract_Bene, WORK. ,  TMP_PARTY);
%AppendTable(WORK. , TMP_PartyT_CUSTOMER, WORK. ,  TMP_PARTY);
%AppendTable(WORK. , TMP_PartyT_Employee, WORK. ,  TMP_PARTY);
%AppendTable(WORK. , TMP_PartyT_Insured_List, WORK. ,  TMP_PARTY);
%AppendTable(WORK. , TMP_PartyT_Payer, WORK. ,  TMP_PARTY);
%AppendTable(WORK. , TMP_PartyT_Policy_Holder, WORK. ,  TMP_PARTY);
%AppendTable(WORK. , TMP_PartyHR_EMP, WORK. ,  TMP_PARTY);

PROC SORT DATA= WORK.TMP_PARTY ;
     BY   TglCertiCode Party_Type_Cd 
           descending UpdateTimeStamp  ;
RUN;

PROC SORT DATA= WORK.TMP_PARTY
    OUT=EDWSTG.PARTY (LABEL="PARTY")
    NODUPKEY    ;
    BY TglCertiCode  Party_Type_Cd;
RUN;

%CreateCntTable(EDWSTG.,PARTY, WORK.,TMP_CntParty);
%CreateCntTable(WORK.,TMP_PARTYT_AGENT, WORK.,TMP_CntPartyAGENT);
%CreateCntTable(WORK. , TMP_PARTYT_Contract_Bene, WORK. ,  TMP_CntPartyContractBene);
%CreateCntTable(WORK. , TMP_PARTYT_CUSTOMER, WORK. ,  TMP_CntPartyCUSTOMER);
%CreateCntTable(WORK. , TMP_PartyT_Employee, WORK. ,  TMP_CntPartyEmployee);
%CreateCntTable(WORK. , TMP_PartyT_Insured_List, WORK. ,  TMP_CntPartyInsuredList);
%CreateCntTable(WORK. , TMP_PartyT_Payer, WORK. , TMP_CntPartyPayer);
%CreateCntTable(WORK. , TMP_PartyT_Policy_Holder, WORK. ,  TMP_CntPartyPolicyHolder);
%CreateCntTable(WORK. , TMP_PartyHR_EMP, WORK. ,  TMP_CntPartyHR_EMP);

proc sql;
  delete from EDWSTG.EDWCTL_PARTY_CNT   ;
quit;
%AppendTable(WORK. , TMP_CntPARTY, EDWSTG. , EDWCTL_PARTY_CNT);
%AppendTable(WORK. , TMP_CntPARTYAGENT, EDWSTG. ,  EDWCTL_PARTY_CNT);
%AppendTable(WORK. , TMP_CntPARTYContractBene, EDWSTG. ,  EDWCTL_PARTY_CNT);
%AppendTable(WORK. , TMP_CntPARTYCUSTOMER, EDWSTG. ,  EDWCTL_PARTY_CNT);
%AppendTable(WORK. , TMP_CntPartyEmployee, EDWSTG. ,  EDWCTL_PARTY_CNT);
%AppendTable(WORK. , TMP_CntPartyInsuredList, EDWSTG. ,  EDWCTL_PARTY_CNT);
%AppendTable(WORK. , TMP_CntPartyPayer, EDWSTG. ,  EDWCTL_PARTY_CNT);
%AppendTable(WORK. , TMP_CntPartyPolicyHolder, EDWSTG. ,  EDWCTL_PARTY_CNT);
%AppendTable(WORK. , TMP_CntPartyHR_EMP, EDWSTG. ,  EDWCTL_PARTY_CNT);

/*
PROC DATASETS Lib=WORK ;
    delete TMP_: ;
RUN;

*/
/*
PROC SQL;
    DROP TABLE WORK.T_EMPLOYEE;
QUIT;
*/

