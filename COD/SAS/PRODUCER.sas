/*專        案: Claim Fraud P2-2 ebao*/
/*程式名稱: PRODUCER.SAS*/
/*作        者: Linda */
/*日        期: 2018/04/25 */
/*處理概要: 以 ebao T_agent為主 串讀相關檔. 去重覆(身分證+PARTY_TYPE) */
/*輸    入:   
 1   EDWEBA.T_AGENT
*/
/*輸    出:  EDWSTG.PRODUCER(IAA format) */

/*I0000============================== MOVE TO TGLEDW/COD/JOB/EDW_ENV.SAS*/
libname edweba oracle path=odsls schema=LS_EBAO user=edweba password="edw12345" ;
libname edwESP oracle path=odsls schema=ESP user=edweba password="edw12345" ;
libname AMLESP oracle path=odsprod schema=ESP user=aml password="am123456" ;
libname EDWSTG "/SASDATA/USER/TGLEDW/LIB/STG";
