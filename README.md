# SASEDW
## 專案結構
### BAK: 備份區，當批次有誤時重跑的必要資料
+ ODS: Operation Data Cummulated (SCD Type 2 )
+ SRC: Operation Data 
+ DDS: DDS備份
+ RPT: report ralated data

### COD: 程式碼
+ JOB: 批次程式(包含dependency)
+ SAS: 獨立目的SAS Code
+ MCR: 共用巨集程式

### LIB: 資料館
+ ODS: Operation Data(需定期做HouseKeeping)
+ STG: 合併個來源資料檔
+ DDS: STG歷程檔
+ ABT: 建模用分析型表格

### RPT: 報表區
+ COM: 系統監控報表區
+ MDL: 模型監控報表區
+ OPR: 業務用報表區

### injection.xml(專案設定檔)
