public with sharing class CustomLookupFieldController {
    public static List<String> searchFields;
    public static Set<Id> recentlyViewedIds;
    public static String inputValue;
    final static Integer RECENTLY_VIEWED_POINTS = 1;
    public CustomLookupFieldController() {

    }
    public without sharing class SystemModeQuery{
        public List<SObject> getRecords(String query){
            return Database.query(query);
        }
    }
    public class ItemWrapper implements Comparable {
        @AuraEnabled
        public String itemName;
        @AuraEnabled
        public String itemId;

        @AuraEnabled
        public List<CustomLookupFieldController.DisplayFieldWrapper> displayFields;

        public SObject record;

        public ItemWrapper(SObject record, Map<String, Schema.DisplayType> displayFieldsMap){
            this.itemName = (String) record.get('Name');
            this.itemId = (String) record.get('Id');
            this.displayFields = new List<DisplayFieldWrapper>();
            String floatClass = 'slds-float_left';
            System.debug('d ' + displayFieldsMap.keySet());
            this.record = record;
            for(String fieldName : displayFieldsMap.keySet()){
                DisplayFieldWrapper dfw = new DisplayFieldWrapper( getFieldValue(record, fieldName), fieldName, displayFieldsMap.get(fieldName));
                dfw.className = 'disabled-link ' + floatClass;
                this.displayFields.add(dfw);
                floatClass = floatClass == 'slds-float_left' ? 'slds-float_right' : 'slds-float_left';
            }
        }

        

        private String getFieldValue(SObject record, String fieldName){
            List<String> parentList = fieldName.split('\\.');
            if(parentList.size() == 1){
                
                return (String) record.get(fieldName);
            }
            SObject lastParent;
            String finalField = parentList.get(parentList.size() - 1);
            for(Integer i = 0; i < parentList.size() - 1; i++){
                lastParent = record.getSObject(parentList.get(i));
                if(lastParent == null){
                    return null;
                }
            }
            return (String) lastParent.get(finalField);
        }

        public Integer compareTo(Object compareTo) {
            ItemWrapper compareToWrapper = (ItemWrapper) compareTo;
            Integer currentPoints = 0;
            Integer comparePoints = 0;
            for(String searchField : CustomLookupFieldController.searchFields){
                String searchValue = getFieldValue(this.record, searchField);
                String searchValueCompare = getFieldValue(compareToWrapper.record, searchField);
                Integer fieldIndex = CustomLookupFieldController.searchFields.indexOf(searchField);
                if(searchValue.contains(CustomLookupFieldController.inputValue)){
                    currentPoints += CustomLookupFieldController.searchFields.size() - fieldIndex;
                }
                if(searchValueCompare.contains(CustomLookupFieldController.inputValue)){  
                    comparePoints += CustomLookupFieldController.searchFields.size() - fieldIndex;
                }
                if(CustomLookupFieldController.recentlyViewedIds.contains(this.itemId)){
                    currentPoints += CustomLookupFieldController.RECENTLY_VIEWED_POINTS;
                }
                if(CustomLookupFieldController.recentlyViewedIds.contains(compareToWrapper.itemId)){
                    comparePoints += CustomLookupFieldController.RECENTLY_VIEWED_POINTS;
                }
            }

            return currentPoints > comparePoints ? -1 : currentPoints < comparePoints ? 1 : 0;
        }
    }
    public class DisplayFieldWrapper{
        @AuraEnabled
        public String label;
        @AuraEnabled
        public String value;
        @AuraEnabled
        public String className;

        public DisplayFieldWrapper(String value, String fieldName, Schema.DisplayType fieldType){
            if(CustomLookupFieldController.searchFields.indexOf(fieldName) > -1 && String.isNotBlank(CustomLookupFieldController.inputValue)){
                String result = '';
                String temp = '' + value;
                while(temp.indexOfIgnoreCase(inputValue) > -1){
                    Integer substrIndex = temp.indexOfIgnoreCase(inputValue);
                    String substrIgnoreCase = temp.substring(0, substrIndex);
                    String inputOriginal = temp.substring(substrIndex, substrIndex + inputValue.length());
                    temp = temp.substring( substrIgnoreCase.length() + inputValue.length(), temp.length());
                    result += substrIgnoreCase + '<b>' + inputOriginal + '</b>';
                }
                    result += temp;
                    this.value = result;
            }
            else{
                this.value = value;
            }
            
        }
    }
    @AuraEnabled
    public static List<ItemWrapper> getItemsList(String objectName, List<String> searchFields, List<String> displayFields, String inputValue, String defaultFilter, Boolean systemMode){
        
        inputValue = inputValue != null ? String.escapeSingleQuotes(inputValue) : null;

        String soqlQueryRecent = 'SELECT Id FROM RecentlyViewed WHERE Type = \'' +  objectName + '\'';
        List<RecentlyViewed> recordsRecent =  (List<RecentlyViewed>) Database.query(soqlQueryRecent);
        Set<Id> recentlyViewedIds = new Map<Id, RecentlyViewed>(recordsRecent).keySet();
        Set<String> queryFieldSet = new Set<String>{'Id', 'Name'};
        queryFieldSet.addAll(displayFields);

        String soqlQuerySearch = 'SELECT ' + String.join( new List<String>(queryFieldSet), ', ' );

        soqlQuerySearch += ' FROM ' + objectName + ' WHERE ';
        if(String.isNotBlank(inputValue) && inputValue.length() >= 3){
            soqlQuerySearch += searchFields == null || searchFields.isEmpty() ? 'Name LIKE \'%' + inputValue + '%\'' :
                                                        String.join(searchFields, ' LIKE \'%' + inputValue + '%\' OR ') + ' LIKE \'%' + inputValue + '%\'';
        }
        else{
            soqlQuerySearch += 'Id in ' + '(\'' + String.join(new List<Id>(recentlyViewedIds), '\',\'') + '\')';
        }
        if(String.isNotBlank(defaultFilter)){
            soqlQuerySearch = soqlQuerySearch.substringBefore(' WHERE ') + ' WHERE (' + soqlQuerySearch.substringAfter(' WHERE ') + ') AND (' + defaultFilter + ')';
        }
        soqlQuerySearch += ' LIMIT 200';
        //soqlQuerySearch += ' WITH SYSTEM_MODE';
        System.debug('GENERATED SOQL QUERY:::: ' + soqlQuerySearch);
        List<SObject> recordList = new List<SObject>();
        try{
            recordList = systemMode == true ? new SystemModeQuery().getRecords(soqlQuerySearch) : Database.query(soqlQuerySearch);
        }
        catch(Exception ex){
            System.debug('ERROR TO PERFOM QUERY::: ' + ex.getMessage());
        }
        CustomLookupFieldController.inputValue = inputValue;
        CustomLookupFieldController.searchFields = searchFields == null || searchFields.isEmpty() ? new List<String>{'Name'} : searchFields;
        CustomLookupFieldController.recentlyViewedIds = recentlyViewedIds;
        Map<String, Schema.DisplayType> displayFieldsAndTypes = getFieldTypes(displayFields, objectName);
        List<ItemWrapper> result = generateSearchItems(recordList, displayFieldsAndTypes);

        return result;
    }
    private static Schema.DisplayType getDisplayType(String displayField, String objectName){
        return Schema.getGlobalDescribe()
                            .get(objectName)
                            .getDescribe()
                            .fields
                            .getMap()
                            .get(displayField)
                            .getDescribe()
                            .getType();
    }
    private static Map<String, Schema.DisplayType> getFieldTypes(List<String> displayFields, String objectName){
        Map<String, Schema.DisplayType> result = new Map<String, Schema.DisplayType>();
        for(String displayField : displayFields){
            List<String> parentList = displayField.split('\\.');
            if(parentList.size() == 1){
                Schema.DisplayType fieldType = getDisplayType(displayField, objectName);
                result.put(displayField, fieldType);
                //continue;                
            }
            else{
                result.put(displayField, null);
            }
            //tbd
        }
        return result;
    }
    private static List<ItemWrapper> generateSearchItems(List<SObject> records, Map<String, Schema.DisplayType> displayFields){
        List<ItemWrapper> items = new List<ItemWrapper>();

        for(SObject record : records){
            ItemWrapper item = new ItemWrapper(record, displayFields);
            items.add(item);
        }
        return items;
    }
}