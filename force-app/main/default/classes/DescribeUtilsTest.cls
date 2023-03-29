@isTest
public class DescribeUtilsTest {
	@isTest
	static void getChildSObject() {
        DescribeUtils dc = DescribeUtils.getCache('Account');

        Schema.SObjectType obj = dc.getChildSObject('Contacts');
        System.assert(obj != null);
	}

	@isTest
	static void getFieldDescribeWithHierarchy() {
        DescribeUtils dc = DescribeUtils.getCache('Contact');

        Schema.DescribeFieldResult fld = dc.getFieldDescribeWithHierarchy('Account.Name');
        System.assertEquals('Name', fld.getName(), 'Field was not retrieved properly');
	}

	@isTest
	static void getFieldTokenNamespace() {
        DescribeUtils dc = DescribeUtils.getCache('Lead');
        Schema.SObjectField token = dc.getFieldToken('NS__Xayz');
        system.assert(token == null);

        Map<String, Schema.SObjectField> mapField = dc.getFieldMap();
        system.assert(mapField != null);
	}

}