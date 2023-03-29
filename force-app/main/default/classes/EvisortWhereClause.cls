public with sharing class EvisortWhereClause {
    public EvisortWhereClause() {
    }
    
    public String whereClause(String filterDetailsObjStr){
        String result;
        EvisortFilterDetails FilterDetailsObj = (EvisortFilterDetails)JSON.deserialize(filterDetailsObjStr, EvisortFilterDetails.class);
        if(!FilterDetailsObj.rows.isEmpty()){
            result = prepareWhereClause(FilterDetailsObj.rows,FilterDetailsObj.condition);
        }
        return result;
    }


    public static string prepareWhereClause(List<Filters> filterConditions, String condition){
        String filterStr = '';
        if( filterConditions != null ){
            for(Filters filterRecord : filterConditions){
                if(String.isBlank(filterRecord.value)){
                    filterRecord.value = '';
                    
                    if(filterRecord.fieldType == 'MULTIPICKLIST' && filterRecord.operator == 'IN' ){
                        continue;
                    }
                }

                filterRecord.value = String.escapeSingleQuotes(filterRecord.value);
                filterRecord.fieldName = String.isNotBlank(filterRecord.fieldName) ? String.escapeSingleQuotes(filterRecord.fieldName) : '';
                if(!String.IsBlank(filterRecord.fieldName) && !String.IsBlank(filterRecord.operator)){
                    
                    if((filterRecord.fieldName == 'ContentSize' || filterRecord.fieldName == 'BodyLength') && String.isNotBlank(filterRecord.value) ){
                        Integer sizeInKB = Integer.valueof(filterRecord.value) * 1024;
                        filterRecord.value = String.Valueof(sizeInKB);
                    }
                    if(filterRecord.fieldType == 'DATETIME' || filterRecord.fieldType == 'TIME'){
                        if(String.isNotBlank(filterRecord.value)){
                            List<String> splitedDate = filterRecord.value.split(' ');
                            if(splitedDate.size() >= 2 ){
                                filterRecord.value = splitedDate[0]+'T'+splitedDate[1]+'Z';
                            }else {
                                filterRecord.value = splitedDate[0]+'T00:00:00Z';
                            }
                            
                        }
                    }
                    if(filterRecord.operator == 'Not Contains'){
                         filterStr += ' (NOT ' + filterRecord.fieldName + ' LIKE \'%' + filterRecord.value + '%\') '; 
                    }
                    else if(filterRecord.operator == 'Contains'){
                    
                        filterStr += ' ' + filterRecord.fieldName + ' LIKE \'%' + filterRecord.value.replace('_','\\_') + '%\' '; 

                    }else if(filterRecord.operator == 'Start With'){
                            filterStr += ' ' + filterRecord.fieldName + ' LIKE \'' + filterRecord.value + '%\' '; 

                    }else if(filterRecord.operator == 'End With'){
                        filterStr += ' ' + filterRecord.fieldName + ' LIKE \'%' + filterRecord.value + '\' '; 
                    }
                    else if(filterRecord.operator == 'Equals'){
                        if( filterRecord.fieldType == 'DATE'  || filterRecord.fieldType == 'NUMBER'  || filterRecord.fieldType == 'DOUBLE' || filterRecord.fieldType == 'INTEGER'  || filterRecord.fieldType == 'CURRENCY' || filterRecord.fieldType == 'DATETIME' || filterRecord.fieldType == 'PERCENT' || filterRecord.fieldType == 'TIME' ){
                            
                            if(filterRecord.value == ''){
                                filterRecord.value = null;
                            }
                            filterStr += ' ' + filterRecord.fieldName + ' =  ' + filterRecord.value;
                            
                        }else if(filterRecord.fieldType == 'BOOLEAN') 
                        {
                            if(filterRecord.value  == 'True'){
                                filterStr += ' ' + filterRecord.fieldName + ' =  TRUE';
                            }else{
                                filterStr += ' ' + filterRecord.fieldName + ' =  FALSE';
                            }
                        }
                        else{
                            filterStr += ' ' + filterRecord.fieldName + ' = \'' + filterRecord.value + '\'';
                        }
                        
                    }
                    else if(filterRecord.operator == 'Not Equals To')
                    {
                        if( filterRecord.fieldType == 'DATE'  || filterRecord.fieldType == 'NUMBER'  || filterRecord.fieldType == 'DOUBLE' || filterRecord.fieldType == 'INTEGER'  || filterRecord.fieldType == 'CURRENCY' || filterRecord.fieldType == 'DATETIME' || filterRecord.fieldType == 'TIME' || filterRecord.fieldType == 'PERCENT' || filterRecord.fieldType == 'BOOLEAN'){
                            if(filterRecord.value == ''){
                                filterRecord.value = null;
                            }
                            filterStr += ' ' + filterRecord.fieldName + ' !=  ' + filterRecord.value;
                            
                        }else{
                            filterStr += ' ' + filterRecord.fieldName + ' != \'' + filterRecord.value + '\'';
                        }
                    }else if(filterRecord.operator == 'Less Than'){
                        filterStr += ' ' + filterRecord.fieldName + ' < ' + filterRecord.value + ' ';
                    }else if(filterRecord.operator == 'Greater Than'){
                        filterStr += ' ' + filterRecord.fieldName + ' > ' + filterRecord.value + ' ';
                    }else if(filterRecord.operator == 'Less Than Equals To'){
                        filterStr += ' ' + filterRecord.fieldName + ' <= ' + filterRecord.value + ' ';
                    }else if(filterRecord.operator == 'Greater Than Equals To'){
                        filterStr += ' ' + filterRecord.fieldName + ' >= ' + filterRecord.value + ' ';
                    }else if(filterRecord.operator == 'IN'){
                        String val = '';
                        List<String> filterValueList = filterRecord.value.split(',');
                        for(String str : filterValueList){
                            val += '\'' + Str + '\'' + ',';
                        }
                        val = val.removeEnd(',');
                        filterStr += ' ' + filterRecord.fieldName + ' IN (' + val + ') ';
                    }
                    if(String.isNotBlank(condition)){
                        filterStr += (' ' + String.escapeSingleQuotes(condition));  
                    }
                }
            }
        }
        if( filterStr.endsWith('AND')){
            filterStr = filterStr.substring(0, filterStr.length()-3);
        }else if( filterStr.endsWith('OR')){
            filterStr = filterStr.substring(0, filterStr.length()-3);
        }

        if( filterStr != '' ){
            String temp = '(' + filterStr + ')';
            filterStr = temp;
        } 
        
        return filterStr;    
    }

    public String replaceFieldNames(String fileFilterBody) {
        String fileWhereClause;
        EvisortFilterDetails FilterDetailsObj = (EvisortFilterDetails)JSON.deserialize(fileFilterBody, EvisortFilterDetails.class);
        if(!FilterDetailsObj.rows.isEmpty()){
            for (Filters filter : FilterDetailsObj.rows) {
                switch on filter.fieldName {
                    when 'Title' {
                        filter.fieldName = 'Name';
                        filter.fieldLabel = 'Name';
                    }
                    when 'ContentSize' {
                        filter.fieldName = 'BodyLength';
                        filter.fieldLabel = 'Body Length';
                    }
                    when 'FileExtension' {
                        filter.fieldName = 'ContentType';
                        filter.fieldLabel = 'Content Type';
                    }
                }
            }
            fileWhereClause = JSON.serialize(FilterDetailsObj);
        }
        return fileWhereClause;
    }

    public class EvisortFilterDetails{
        @AuraEnabled
        public List<Filters> rows {get;set;}
        @AuraEnabled
        public String customLogic {get;set;}
        @AuraEnabled
        public String ObjectName {get;set;}
        @AuraEnabled
        public String taskName {get;set;}
        @AuraEnabled
        public String condition {get;set;}  
    }

    public class Filters{
        
        @AuraEnabled
        public Integer sequence {get;set;}
        @AuraEnabled
        public String fieldName {get;set;}
        @AuraEnabled
        public String fieldLabel {get;set;}
        @AuraEnabled
        public String fieldType {get;set;}
        @AuraEnabled
        public String operator {get;set;}
        @AuraEnabled
        public String value {get;set;}
        @AuraEnabled
        public String condition {get;set;}
    }
}