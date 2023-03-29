@isTest
private class EvisortWhereClauseTest {
    @TestSetup
    static void testSetup() {
        User u = UserTest.getEvisortUser();
        System.runAs(u) {
            Account accountData = TestFactory.getAccount('Test');
            insert accountData;
            Opportunity opportunityData = TestFactory.getOpportunity('TestOpportunity',accountData.Id);
            insert opportunityData;
            ContentVersion contentVersionData = TestFactory.getContentVersion('Test', 'Data ', null);
            insert contentVersionData;
        }
    }
    
    @isTest
    static void getWhereClauseTestForObject() {
        User u = UserTest.getEvisortAdminUser();
        String objectFilter = getObjectFilter();
        System.runAs(u) {
            String WhereClause;
            Test.startTest();
            EvisortWhereClause eviWhereClause = new EvisortWhereClause();
            WhereClause = eviWhereClause.whereClause(objectFilter);
            CSUtils.itShouldNotBe('WhereClause', null, WhereClause);
            Test.stopTest();
            String query = 'SELECT Id, Name FROM Opportunity';
            query += ' WHERE '+ WhereClause;
          
            List<Opportunity> filterOpprtunityList = Database.query(query); 
            CSUtils.itShouldBe('Total Record', 1, filterOpprtunityList.size());
        }
    }
    
    @isTest
    static void getWhereClauseTestForLibrary() {
        User u = UserTest.getEvisortAdminUser();
       
        System.runAs(u) {
            String FileFilter = getFileFilter();
            String WhereClause;
            Test.startTest();   
            EvisortWhereClause eviWhereClause = new EvisortWhereClause();
            WhereClause = eviWhereClause.whereClause(FileFilter);
            
            Test.stopTest();
            CSUtils.itShouldNotBe('WhereClause', null, WhereClause);       
        }
    }
    
    static String getObjectFilter(){
        String objectFilter = '{ "rows": [ ';
        objectFilter += '{ "fieldName": "Name", "fieldLabel": "Name", "fieldType": "STRING", "operator": "Equals", "value": "TestOpportunity", "isPicklist": false, "fieldTypeLabel": "STRING", "fieldSOAPType": "STRING", "sequence": 1 }';
        objectFilter += ', { "fieldName": "CreatedDate", "fieldLabel": "Created Date", "fieldType": "DATETIME", "operator": "Not Equals To", "value": "2022-05-05", "isPicklist": false, "fieldTypeLabel": "DATETIME", "fieldSOAPType": "DATETIME", "sequence": 2 }';
        objectFilter += ', { "fieldName": "Fiscal", "fieldLabel": "Fiscal Period", "fieldType": "STRING", "operator": "Not Contains", "value": "", "isPicklist": false, "fieldTypeLabel": "STRING", "fieldSOAPType": "STRING", "sequence": 3 }';
        objectFilter += ', { "fieldName": "CloseDate", "fieldLabel": "Close Date", "fieldType": "DATE", "operator": "Equals", "value": "2022-05-05", "isPicklist": false, "fieldTypeLabel": "DATE", "fieldSOAPType": "DATE", "sequence": 4 }';
        objectFilter += ', { "fieldName": "IsPrivate", "fieldLabel": "Private", "fieldType": "BOOLEAN", "operator": "Equals", "value": "True", "isPicklist": false, "fieldTypeLabel": "BOOLEAN", "fieldSOAPType": "BOOLEAN", "sequence": 5 }';
        objectFilter += ', { "fieldName": "IsPrivate", "fieldLabel": "Private", "fieldType": "BOOLEAN", "operator": "Equals", "value": "False", "isPicklist": false, "fieldTypeLabel": "BOOLEAN", "fieldSOAPType": "BOOLEAN", "sequence": 6 }';
        objectFilter += ', { "fieldName": "Amount", "fieldLabel": "Amount", "fieldType": "CURRENCY", "operator": "Equals", "value": "", "isPicklist": false, "fieldTypeLabel": "CURRENCY", "fieldSOAPType": "DOUBLE", "sequence": 8 }';
        objectFilter += ', { "fieldName": "LastModifiedDate", "fieldLabel": "Last Modified Date", "fieldType": "DATETIME", "operator": "Greater Than", "value": "2022-05-02", "isPicklist": false, "fieldTypeLabel": "DATETIME", "fieldSOAPType": "DATETIME", "sequence": 9 }';
        objectFilter += ', { "fieldName": "AccountId", "fieldLabel": "Account ID", "fieldType": "REFERENCE", "operator": "Equals", "value": "0011700001TiaqiAAB", "isPicklist": false, "fieldTypeLabel": "ID", "fieldSOAPType": "ID", "sequence": 10 }';
        objectFilter += ', { "fieldName": "CreatedDate", "fieldLabel": "Created Date", "fieldType": "DATETIME", "operator": "Not Equals To", "value": "", "isPicklist": false, "fieldTypeLabel": "DATETIME", "fieldSOAPType": "DATETIME", "sequence": 11 }';
        objectFilter += ', { "fieldName": "CloseDate", "fieldLabel": "Close Date", "fieldType": "DATE", "operator": "Less Than", "value": "2022-05-05", "isPicklist": false, "fieldTypeLabel": "DATE", "fieldSOAPType": "DATE", "sequence": 12 }';
        objectFilter += ', { "fieldName": "IsDeleted", "fieldLabel": "Deleted", "fieldType": "BOOLEAN", "operator": "Equals", "value": "True", "isPicklist": false, "fieldTypeLabel": "BOOLEAN", "fieldSOAPType": "BOOLEAN", "sequence": 13 }';
        objectFilter += ' ], "condition": "OR" }';
        
        return objectFilter;
    }
    
    static String getFileFilter(){
        String objectFilter = '{ "rows": [ ';
        objectFilter += ' { "fieldName": "FileExtension", "fieldLabel": "File Extension", "fieldType": "STRING", "operator": "IN", "value": "pdf,doc,txt", "isPicklist": false, "fieldTypeLabel": "STRING", "fieldSOAPType": "STRING", "sequence": 1 }';
        objectFilter += ' ], "condition": "OR" }';
        
        return objectFilter;
    }
}