@isTest
private class Test_KitHoldEmailNotificationSPI {
    
    @testSetup static void createTestData() {
        // First, set up test price book entries.
        // Insert a test product.
        Product2 prod = new Product2(Name = 'Alpha DNA Kit', Type__c = 'KIT', Prep_Request__c = 'Helix Saliva Extraction',
            Delivery_Mode__c = 'Deliver', Sample_Source__c = 'Customer Saliva');
        insert prod;
        
        // Get standard price book ID.
        // This is available irrespective of the state of SeeAllData.
        Id pricebookId = Test.getStandardPricebookId();
        
        // 1. Insert a price book entry for the standard price book.
        // Standard price book entries require the standard price book ID we got earlier.
        PricebookEntry standardPrice = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = prod.Id,
                                                UnitPrice = 10000, IsActive = true);
        insert standardPrice;
        
        Account acc = new Account(Name = 'Test');
        insert acc;
        Contact con = new Contact(LastName = 'Test', AccountId = acc.Id, UserId__c = '1111');
        insert con;
        Order o = new Order(AccountId = acc.id, EffectiveDate = System.today(), Status = 'Draft', Pricebook2Id = pricebookId,
                        BillToContactId = con.id, ShipToContactId = con.id);
        insert o;
        List<OrderItem> oiList = new List<OrderItem>();
        for(Integer i = 100; i < 150; i++) {
            OrderItem oi = new OrderItem(OrderId = o.id, Required_Yield__c = 4.5, Project_Name__c = 'TestProject_5-31',
                Analysis_Workflow__c = 'ExomePlusFastq2GvcfV1.0-WFV1.0', Sample_Status__c = 'Ready for Submission',
                PricebookEntryId = standardPrice.id, Quantity = 1, UnitPrice = 100, BillTo_Contact__c = con.id, ShipTo_Contact__c = con.id,
                registeredBy__c = con.id);
            oi.Kit_ID__c = 'AAAAAAA' + String.valueOf(i);
            oiList.add(oi);
        }
        insert oiList;
        
        Marketing_Email_Template_Name__c setting = new Marketing_Email_Template_Name__c(
                    Name = 'Kit on hold', Email_Template_Name__c = 'Kit on hold');
        insert setting;
        // Next, perform some tests with your test price book entries.
    }

    static testmethod void testKitHoldEmailNotification() {
        Test_APIDataUtil.serviceCredSettings('SingleEmailService');
        Test_APIDataUtil.createKitHoldFakeResponse();
        
        Test.startTest();
        List<OrderItem> oiList = [select OrderId, Order.BillToContactId from OrderItem where Type__c = 'KIT'];
        Set<Id> oiIds = new Set<Id>();
        Map<Id, OrderItem> orderIdMap = new Map<Id, OrderItem>();
        
        for(OrderItem oi :oiList) {
            oi.Accessioning_Status__c = 'HOLD';
            oiIds.add(oi.id);
            orderIdMap.put(oi.OrderId, oi);
        }
        
        update oiList;
        HelixApiUtil.updateAccessToken('SingleEmailService', '12345');
        Test.stopTest();
        
        List<Task> tskList = [select WhatId, WhoId, Subject, Status from Task where Order_Product__c in :oiIds];
        
        System.assertEquals(tskList.size(), oiList.size());
        
        for(Task tsk :tskList) {
            if(orderIdMap != null && orderIdMap.containsKey(tsk.WhatId)) {
                System.assertEquals(tsk.WhoId, orderIdMap.get(tsk.WhatId).Order.BillToContactId);
                System.assertEquals(tsk.WhatId, orderIdMap.get(tsk.WhatId).OrderId);
                System.assert(tsk.Subject.contains('Kit on hold'));
                System.assertEquals('Sent', tsk.Status);
            }
        }
    }
    
    static testmethod void testKitHoldErrorEmailNotification() {
        Test_APIDataUtil.serviceCredSettings('SingleEmailService');
        Test_APIDataUtil.createKitHoldErrorFakeResponse();
        
        Test.startTest();
        List<OrderItem> oiList = [select OrderId, Order.BillToContactId from OrderItem where Type__c = 'KIT'];
        Set<Id> oiIds = new Set<Id>();
        Map<Id, OrderItem> orderIdMap = new Map<Id, OrderItem>();
        
        for(OrderItem oi :oiList) {
            oi.Accessioning_Status__c = 'HOLD';
            oiIds.add(oi.id);
            orderIdMap.put(oi.OrderId, oi);
        }
        
        update oiList;
        HelixApiUtil.updateAccessToken('SingleEmailService', '12345');
        Test.stopTest();
        
        List<Task> tskList = [select WhatId, WhoId, Subject, Status from Task where Order_Product__c in :oiIds];
        
        System.assertEquals(tskList.size(), oiList.size());
        
        for(Task tsk :tskList) {
            if(orderIdMap != null && orderIdMap.containsKey(tsk.WhatId)) {
                System.assertEquals(tsk.WhoId, orderIdMap.get(tsk.WhatId).Order.BillToContactId);
                System.assertEquals(tsk.WhatId, orderIdMap.get(tsk.WhatId).OrderId);
                System.assert(tsk.Subject.contains('Kit on hold'));
                System.assertEquals('Error', tsk.Status);
            }
        }
    }
    
    static testmethod void testActivityAlreadyExistScenario() {
        Test_APIDataUtil.serviceCredSettings('SingleEmailService');
        Test_APIDataUtil.createKitHoldErrorFakeResponse();
        
        Test.startTest();
        List<OrderItem> oiList = [select OrderId, Order.BillToContactId from OrderItem where Type__c = 'KIT'];
        Set<Id> oiIds = new Set<Id>();
        Map<Id, OrderItem> orderIdMap = new Map<Id, OrderItem>();
        
        for(OrderItem oi :oiList) {
            oi.Accessioning_Status__c = 'HOLD';
            oiIds.add(oi.id);
            orderIdMap.put(oi.OrderId, oi);
        }
        
        update oiList;
        HelixApiUtil.updateAccessToken('SingleEmailService', '12345');
        Test.stopTest();
        
        List<Task> tskList = [select WhatId, WhoId, Subject, Status from Task where Order_Product__c in :oiIds];
        // assert task count
        System.assertEquals(tskList.size(), oiList.size());
        
        // update Accessioning status to something else other than HOLD
        for(OrderItem oi :oiList) {
            oi.Accessioning_Status__c = 'PASS';
        }
        update oiList;
        
        // again update Accessioning status to HOLD to execute trigger again
        for(OrderItem oi :oiList) {
            oi.Accessioning_Status__c = 'HOLD';
        }
        update oiList;
        
        tskList = [select WhatId, WhoId, Subject, Status from Task where Order_Product__c in :oiIds];
        // task count remain same 
        System.assertEquals(tskList.size(), oiList.size());
    }
}