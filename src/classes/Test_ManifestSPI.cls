@isTest
private class Test_ManifestSPI {
    
    // test login method to generate authentication token
    static testMethod void manifestLoginTestMethod() {
        SingleRequestMock fakeResponse = new SingleRequestMock(200,
                                                 'OK',
                                                 '{"access_token":"test_auth_token"}',
                                                 null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        
        Sample_Service_Credentials__c sampleServCred = Test_ManifestDataUtil.uploadManifestSettings();
        
        Test.startTest();
        String authToken = ManifestLogin.getAuthToken(sampleServCred.Name, sampleServCred.UserName__c, sampleServCred.Password__c, 
                                                                    sampleServCred.Login_Service__c);
        Test.stopTest();
        System.assertEquals('test_auth_token', authToken);
    }
    
    // to test the positive scenario when manifest are uploaded successfully
    static testMethod void uploadManifestTestMethod() {
        
        Test_ManifestDataUtil.createProductTestData();
        Test_ManifestDataUtil.uploadManifestSettings();
        Test_ManifestDataUtil.createFakeResponse();
        
        ManifestSPI mspi = new ManifestSPI();
        Test.startTest();
        mspi.sendManifestData(true);
        Test.stopTest();
        
        for(OrderItem oi :[select Sample_Status__c, Sample_Status_Updated__c from OrderItem]) {
            System.assertEquals('Manifest Uploaded', oi.Sample_Status__c);
            System.assertEquals(DateTime.newInstance(2016, 9, 9, 1, 1, 1), oi.Sample_Status_Updated__c);
        }
    }
    
    // to test the positive scenario when manifest are uploaded successfully
    static testMethod void setProductIdTestMethod() {
        ManifestSPI mspi = new ManifestSPI();
        Test_ManifestDataUtil.createProductTestData();
        BioSamples bSamples = mspi.getBioSamples(1);
        
        String prodId = bSamples.BioSamples[0].properties.productId;
        
        System.assertEquals('20010958_20010959', prodId);
        
    }
    
    // to test the scenario when manifest are not uploaded successfully and error is returned
    static testMethod void uploadManifestErroResponseTest() {
        
        Test_ManifestDataUtil.createProductTestData();
        Test_ManifestDataUtil.uploadManifestSettings();
        SampleStatusResponse response = new SampleStatusResponse();
        List<SampleStatus> ssList = new List<SampleStatus>();
        for(Integer i = 100; i < 700; i++) {
            SampleStatus s = new SampleStatus();
            s.kitId = 'AAAAAAA' + String.valueOf(i);
            s.sampleStatus = 'Error';
            s.errorMessage = 'Error description';
            ssList.add(s);
        }
        response.sampleStatuses = ssList;
        
        SingleRequestMock fakeResponse = new SingleRequestMock(200,
                                                 'OK',
                                                 JSON.serializePretty(response),
                                                 null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        
        ManifestSPI mspi = new ManifestSPI();
        Test.startTest();
        mspi.sendManifestData(true);
        Test.stopTest();
        
        for(OrderItem oi :[select Sample_Status__c, Sample_Error_Detail__c from OrderItem]) {
            System.assertEquals('Error', oi.Sample_Status__c);
            System.assertEquals('Error description', oi.Sample_Error_Detail__c);
        }
    }
    
    // to test in case of manual upload
    static testMethod void manifestUploadManualCtrlTest() {
        
        Test_ManifestDataUtil.createProductTestData();
        Test_ManifestDataUtil.uploadManifestSettings();
        Test_ManifestDataUtil.createFakeResponse();
        
        ManifestUploadManualCtrl ctrl = new ManifestUploadManualCtrl();
        Test.startTest();
        ctrl.uploadManifest();
        Test.stopTest();
        
        for(OrderItem oi :[select Sample_Status__c, Sample_Status_Updated__c from OrderItem]) {
            System.assertEquals('Manifest Uploaded', oi.Sample_Status__c);
            System.assertEquals(DateTime.newInstance(2016, 9, 9, 1, 1, 1), oi.Sample_Status_Updated__c);
        }
    }
    
    // to test when class is scheduled for uploading
    static testMethod void manifestUploadScheduleTest() {
        
        Test_ManifestDataUtil.createProductTestData();
        Test_ManifestDataUtil.uploadManifestSettings();
        Test_ManifestDataUtil.createFakeResponse();
        
        ManifestUploadSchedule sch = new ManifestUploadSchedule();
        SchedulableContext sc;
        
        Test.startTest();
        sch.execute(sc);
        Test.stopTest();
        
        for(OrderItem oi :[select Sample_Status__c, Sample_Status_Updated__c from OrderItem]) {
            System.assertEquals('Manifest Uploaded', oi.Sample_Status__c);
            System.assertEquals(DateTime.newInstance(2016, 9, 9, 1, 1, 1), oi.Sample_Status_Updated__c);
        }
    }
}