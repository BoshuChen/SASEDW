/*�M        ��: Claim Fraud P2-2 ebao*/
/*�{���W��: PRODUCER.SAS*/
/*�@        ��: Linda */
/*��        ��: 2018/04/25 */
/*�B�z���n: �H ebao T_agent���D ��Ū������. �h����(������+PARTY_TYPE) */
/*��    �J:   
 1   EDWEBA.T_AGENT
*/
/*��    �X:  EDWSTG.PRODUCER(IAA format) */

/*I0000============================== MOVE TO TGLEDW/COD/JOB/EDW_ENV.SAS*/
libname edweba oracle path=odsls schema=LS_EBAO user=edweba password="edw12345" ;
libname edwESP oracle path=odsls schema=ESP user=edweba password="edw12345" ;
libname AMLESP oracle path=odsprod schema=ESP user=aml password="am123456" ;
libname EDWSTG "/SASDATA/USER/TGLEDW/LIB/STG";
