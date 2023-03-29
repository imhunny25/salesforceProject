@isTest
private class EvisortTest {
    @TestSetup
    static void testSetup() {
        User u = UserTest.getEvisortUser();

        System.runAs(u) {
            Account a = TestFactory.getAccount('Unit Test Account');
            insert a;

            Opportunity o = TestFactory.getOpportunity('Unit Test Opportunity', a.Id);
            insert o;

            Evisort__c e = TestFactory.getEvisortRecord(o.Id, '123');
            insert e;

            List<Evisort_Field_Definition__c> defs = new List<Evisort_Field_Definition__c>();
            defs.add(TestFactory.getFieldDefinition('Boolean Field', 'Boolean', 'Field'));
            defs.add(TestFactory.getFieldDefinition('Date Field', 'Date', 'Field'));
            defs.add(TestFactory.getFieldDefinition('Multi Picklist Field', 'Multi Picklist', 'Field'));
            defs.add(TestFactory.getFieldDefinition('Number Field', 'Number', 'Field'));
            defs.add(TestFactory.getFieldDefinition('Picklist Field', 'Picklist', 'Field'));
            defs[4].Picklist_Values__c = 'Value1$@#Value2';
            defs.add(TestFactory.getFieldDefinition('Provision', 'Text', 'Provision'));
            defs.add(TestFactory.getFieldDefinition('Text Field', 'Text', 'Field'));
            insert defs;

            List<Evisort_Field_Value__c> values = new List<Evisort_Field_Value__c>();
            values.add(TestFactory.getFieldValue(e.Id, defs[0].Id));
            values[0].Checkbox_Field__c = true;
            values.add(TestFactory.getFieldValue(e.Id, defs[1].Id));
            values[1].Date_Field__c = Date.newInstance(2020, 5, 12);
            values.add(TestFactory.getFieldValue(e.Id, defs[2].Id));
            values[2].Picklist_Value_Selected__c = 'NewValue1$@#NewValue2';
            values.add(TestFactory.getFieldValue(e.Id, defs[3].Id));
            values[3].Number_Field__c = 42;
            values.add(TestFactory.getFieldValue(e.Id, defs[4].Id));
            values[4].Picklist_Value_Selected__c = 'NewValue1';
            values.add(TestFactory.getFieldValue(e.Id, defs[5].Id));
            values[5].Text_Field__c = 'Provision Text';
            values.add(TestFactory.getFieldValue(e.Id, defs[6].Id));
            values[6].Text_Field__c = 'Field Text';
            insert values;
        }
    }

    @isTest
    static void testGetValues() {
        User u = UserTest.getEvisortUser();

        System.runAs(u) {
            List<Evisort__c> evisortRecords = [SELECT Id FROM Evisort__c WHERE External_ID__c = '123'];
            CSUtils.itShouldBe('Number of Evisort Records', 1, evisortRecords.size());
            Id evisortId = evisortRecords[0].Id;

            List<Evisort_Field_Definition__c> defs = [SELECT Id, Name FROM Evisort_Field_Definition__c ORDER BY Name];
            CSUtils.itShouldBe('Number of Field Definitions', 7, defs.size());

            Test.startTest();

            EvisortMsg.EvisortRecord msg = EvisortController.getValues(evisortId);

            Test.stopTest();

            CSUtils.itShouldBe('Number of Sections', 2, msg.sections.size());
            CSUtils.itShouldBe('Number of Values in Field Section', 6, msg.sections[0].values.size());
            CSUtils.itShouldBe('Value 1 is Checkbox', true, msg.sections[0].values[0].isCheckbox);
            CSUtils.itShouldBe('Value 1 is correct', 'Yes', msg.sections[0].values[0].picklistValueSelected);
            CSUtils.itShouldBe('Value 1: Two Picklist Options', 2, msg.sections[0].values[0].picklistValues.size());
            CSUtils.itShouldbe('Value 2 is Date', true, msg.sections[0].values[1].isDate);
            CSUtils.itShouldBe(
                'Value 2 is correct',
                Date.newInstance(2020, 5, 12),
                msg.sections[0].values[1].dateField
            );
            CSUtils.itShouldBe('Value 3 is Multi Picklist', true, msg.sections[0].values[2].isMultiPicklist);
            CSUtils.itShouldBe('Value 3: Two Picklist Options', 2, msg.sections[0].values[2].picklistValues.size());
            CSUtils.itShouldBe(
                'Value 3: Two Picklist Values',
                2,
                msg.sections[0].values[2].multiPicklistValueSelected.size()
            );
            CSUtils.itShouldBe('Value 4 is Number', true, msg.sections[0].values[3].isNumber);
            CSUtils.itShouldBe('Value 4 is correct', 42, msg.sections[0].values[3].numberField);
            CSUtils.itShouldBe('Value 5 is Picklist', true, msg.sections[0].values[4].isPicklist);
            CSUtils.itShouldBe('Value 5: Three Picklist Options', 3, msg.sections[0].values[4].picklistValues.size());
            CSUtils.itShouldbe('Value 5 is correct', 'NewValue1', msg.sections[0].values[4].picklistValueSelected);
            CSUtils.itShouldBe('Value 6 is Text', true, msg.sections[0].values[5].isText);
            CSUtils.itShouldBe('Value 6 is correct', 'Field Text', msg.sections[0].values[5].textField);

            CSUtils.itShouldBe('Number of Values in Provision Section', 1, msg.sections[1].values.size());
            CSUtils.itShouldBe('Provision Value is provision', true, msg.sections[1].values[0].isProvision);
            CSUtils.itShouldBe('Provision Value is correct', 'Provision Text', msg.sections[1].values[0].textField);
        }
    }

    @isTest
    static void testSaveValues() {
        User u = UserTest.getEvisortUser();

        System.runAs(u) {
            List<Evisort__c> evisortRecords = [SELECT Id FROM Evisort__c WHERE External_ID__c = '123'];
            CSUtils.itShouldBe('Number of Evisort Records', 1, evisortRecords.size());
            Id evisortId = evisortRecords[0].Id;

            List<Evisort_Field_Value__c> values = [
                SELECT Id, Evisort_Field_Definition__r.Data_Type__c
                FROM Evisort_Field_Value__c
                WHERE Evisort__c = :evisortId
            ];
            CSUtils.itShouldBe('Number of Values', 7, values.size());

            List<EvisortMsg.Value> valueMsg = new List<EvisortMsg.Value>();
            for (Evisort_Field_Value__c efv : values) {
                EvisortMsg.Value v = new EvisortMsg.Value();
                v.evisortFieldValueId = efv.Id;
                switch on (efv.Evisort_Field_Definition__r.Data_Type__c) {
                    when 'Boolean' {
                        v.checkboxField = false;
                    }
                    when 'Date' {
                        v.dateField = Date.newInstance(2019, 5, 12);
                    }
                    when 'Number' {
                        v.numberField = 2020;
                    }
                    when 'Picklist' {
                        v.picklistValueSelected = 'NewValue2';
                    }
                    when 'Multi Picklist' {
                        v.picklistValueSelected = 'NewValue1,NewValue3';
                    }
                    when 'Text' {
                        v.textField = 'New Text';
                    }
                }
                valueMsg.add(v);
            }

            Test.startTest();

            EvisortMsg.EvisortRecord msg = EvisortController.saveValues(evisortId, JSON.serialize(valueMsg));

            Test.stopTest();

            List<Evisort_Field_Value__c> newValues = [
                SELECT Id, Checkbox_Field__c, Date_Field__c, Number_Field__c, Picklist_Value_Selected__c, Text_Field__c
                FROM Evisort_Field_Value__c
                WHERE Evisort__c = :evisortId
                ORDER BY Evisort_Field_Definition__r.Name
            ];
            CSUtils.itShouldBe('Number of Values', 7, newValues.size());
            CSUtils.itShouldBe('Checkbox is now false', false, newValues[0].Checkbox_Field__c);
            CSUtils.itShouldBe('Date is now correct', Date.newInstance(2019, 5, 12), newValues[1].Date_Field__c);
            CSUtils.itShouldBe(
                'Multi Picklist is now correct',
                'NewValue1,NewValue3',
                newValues[2].Picklist_Value_Selected__c
            );
            CSUtils.itShouldBe('Number is now correct', 2020, newValues[3].Number_Field__c);
            CSUtils.itShouldBe('Picklist is now correct', 'NewValue2', newValues[4].Picklist_Value_Selected__c);
            CSUtils.itShouldBe('Provision is now correct', 'New Text', newValues[5].Text_Field__c);
            CSUtils.itShouldBe('Text is now correct', 'New Text', newValues[6].Text_Field__c);
        }
    }

    @isTest
    static void testGetEvisortRecords() {
        User u = UserTest.getEvisortUser();

        System.runAs(u) {
            List<Opportunity> opps = [SELECT Id FROM Opportunity];
            CSUtils.itShouldBe('Number of Opportunities', 1, opps.size());

            Evisort__c e = TestFactory.getEvisortRecord(opps[0].Id, '456');
            e.Original_File_Name__c = 'NewUnitTest';
            insert e;

            Test.startTest();

            List<EvisortMsg.EvisortRecord> msg = EvisortController.getEvisortRecords(opps[0].Id);

            Test.stopTest();

            CSUtils.itShouldBe('Number of Evisort records', 2, msg.size());
            CSUtils.itShouldBe('Id of First Record', e.Id, msg[0].evisortRecordId);
            CSUtils.itShouldBe('Filename of First Record', 'NewUnitTest', msg[0].originalFileName);
            CSUtils.itShouldBe('Filename of Second Record', 'UnitTest', msg[1].originalFileName);
        }
    }
}