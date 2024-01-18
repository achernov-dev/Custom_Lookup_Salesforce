@isTest
public with sharing class CustomLookupFieldController_Test {
    private static final String LEAD_EMAIL = 'john.doe@self.com';
    @testSetup
    static void setupTestData() {

       insert new List<Account>{ new Account( Name = 'Test Account 1', Website = 'testrun.com' ),
                                 new Account(Name = '2 Test Account 2', Website = 'testrun2.com')};
                
        
    }

    @isTest
    private static void getSearchedItems() {
        List<CustomLookupFieldController.ItemWrapper> itemList = CustomLookupFieldController.getItemsList('Account', new List<String>{'Name', 'Website'}, new List<String>{'Name', 'Website', 'Owner.Name'}, 'Test', ' Id != null', true);
        itemList.sort();
        System.assertEquals(2, itemList.size());
    }
}