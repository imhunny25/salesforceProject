/*
Date 		: 5/11/17
Author		: Sebastian Kessel
Description	: Class to handle Describe issues (Permissions, Labels, etc)
*/
public with sharing class DescribeUtils {
	private static final Map<Schema.SObjectType,DescribeUtils> CACHE 	= new Map<Schema.SObjectType,DescribeUtils>();

	private Map<String,Schema.SObjectField> objectFieldTokens			= new Map<String,Schema.SObjectField>();
	private Map<String,Schema.DescribeFieldResult> objectFieldDescribes	= new Map<String,Schema.DescribeFieldResult>();
	private Map<String,SObjectType> objectChildren						= new Map<String,Schema.SObjectType>();
	private Map<String,Schema.RecordTypeInfo> recordTypes;	

	public Schema.SObjectType objectToken 								{get; private set;}
	public Schema.DescribeSObjectResult objectDescribe 					{get; private set;}
	public String objectName											{
		get {
			if (objectName == null)
				objectName = String.valueOf(this.objectToken);
			return objectName;
		}
		private set;
	}

	private DescribeUtils(Schema.SObjectType sot) {
		this.objectToken		= sot;
		this.objectDescribe		= sot.getDescribe();
	}
	
	public Map<String, Schema.SObjectField> getFieldMap () {
		return this.objectDescribe.fields.getMap();
	}

	public Schema.SObjectField getFieldToken(String fieldName) {
		Schema.SObjectField token = this.objectFieldTokens.get(fieldName);

		if (token == null) {
			token 		= this.objectDescribe.fields.getMap().get(fieldName); // Let's not cache every field token = large heap!

			// If the token wasn't found, it could be because fieldName is a parent reference.
			// i.e. Parent__r instead of the foreign key Parent__c
			if (token == null) {
				// Remove Because we didn't want to replace. Now we are checking the exact value.
				//fieldName	= fieldName.replace('__r','__c'); // 58% faster than String.endsWithIgnorCase + String.removeEnd
				token		= this.objectDescribe.fields.getMap().get(fieldName);
			}

			this.objectFieldTokens.put(fieldName, token); // Cache the relationship name
		}
		return token;
	}

	public Schema.SObjectField getParentFieldToken(String fieldName) {
		fieldName = fieldName.tolowerCase();
		Schema.SObjectField token = this.objectFieldTokens.get(fieldName);
		if (token == null) {
			Map<String, String> setRelationshipNamesWithApi = new Map<String, String>();
			List<FieldDefinition> fieldDefs = [SELECT QualifiedApiName, Label, Description, DataType, RelationshipName FROM FieldDefinition 
				WHERE EntityDefinition.QualifiedApiName=: objectName AND RelationshipName != null];
			for (FieldDefinition fd : fieldDefs) {
					setRelationshipNamesWithApi.put(fd.RelationshipName.tolowerCase(), fd.QualifiedApiName.tolowerCase());
			}
			if (setRelationshipNamesWithApi.containsKey(fieldName)) {
				if (fieldName.endswith('__c')) {
					token = this.objectDescribe.fields.getMap().get(fieldName); // Let's not cache every field token = large heap!
				}
				else {
					token = this.objectDescribe.fields.getMap().get(setRelationshipNamesWithApi.get(fieldName)); // Let's not cache every field token = large heap!
				}
				this.objectFieldTokens.put(fieldName.tolowerCase(), token); // Cache the relationship name
			}
			if (this.objectFieldTokens.containsKey(fieldName)) {
				token = this.objectFieldTokens.get(fieldName);
			}
		}
		return token;
	}

	public Schema.DescribeFieldResult getFieldDescribe(String fieldName, Boolean isParent) {
		if (!this.objectFieldDescribes.containsKey(fieldName)) {
			Schema.SObjectField token;
			if (isParent) {
				token = getParentFieldToken(fieldName);
			}
			else {
				token = getFieldToken(fieldName);
			}
			if (token != null) {
				this.objectFieldDescribes.put(fieldName, token.getDescribe());
			}
		}
		return this.objectFieldDescribes.get(fieldName);
	}

	//This method grabs a column with hierarchy and traverses it to get the right describe
	//Expects things like: Company__r.Name or Account.Name
	public Schema.DescribeFieldResult getFieldDescribeWithHierarchy(String fieldName) {
		if (fieldName.contains('(')) { 
			//It's an aggregated field, I won't even attempt to find it
			return null;
		}

		//If I have a period, I have to traverse the hierarchy
		if (fieldName.contains('.')) {

			// If the parent isn't found, bail
			if (getCacheFromHierarchyField(fieldName) == null) {
				return null;
			}

			DescribeUtils parentObjectCache = getCacheFromHierarchyField(fieldName);
			String parentFieldName = getParentFieldNameFromHierarchyField(fieldName);

			return parentObjectCache.getFieldDescribeWithHierarchy(parentFieldName);
		} else {
			return this.getFieldDescribe(fieldName, false);
		}
	}

	public SObjectType getChildSObject(String fieldName) {
		if (!this.objectChildren.containsKey(fieldName)) {
			for (Schema.ChildRelationship cr : this.objectDescribe.getChildRelationships()) {
				if (cr.getRelationshipName() == null)
					continue;
				this.objectChildren.put(cr.getRelationshipName(), cr.getChildSObject());
			}
		}

		SObjectType sot = this.objectChildren.get(fieldName);
		
		return sot;
	}

	public SObjectType getParentSObject(String fieldName) {
		Schema.DescribeFieldResult fieldResult = this.getFieldDescribe(fieldName, true);

		// if the parent is invalid, bail
		if (fieldResult == null) {
			return null;
		}
		
		//Only return the first if there is more than one
		SObjectType sot = null;

		List<Schema.sObjectType> references = fieldResult.getReferenceTo();
		if (references.size()>0) {
			sot = references[0];
		}
		
		return sot;
	}
	
	private String getParentFieldNameFromHierarchyField(String fieldName) {
		String relationshipName = fieldName.split('\\.')[0];
		
		//Fix the field Name
		return fieldName.removeStart(relationshipName + '.');
	}

	private String getRelationshipField(String fieldName) {
		String relationshipName = fieldName.split('\\.')[0];

		//Fix the suffix so I can get the parent properly
		//Remove Because we didn't want to replace. Now we are checking the exact value.
	    //relationshipName = relationshipName.replace('__r','__c');

		return relationshipName;
	}

	private DescribeUtils getCacheFromHierarchyField(String fieldName) {
		String relationshipName = getRelationshipField(fieldName);

		//Call itself with the new object and the rest of the field
		return DescribeUtils.getCache(getParentSObject(relationshipName));
	}

	public static DescribeUtils getCache(String objectName) {
		Schema.SObjectType sot;
		try {
			sot = ((SObject)Type.forName(objectName).newInstance()).getSobjectType(); // this is 89% faster than describeSObject/globalDescribe
		} catch (Exception e) {
			throw new ObjectNotFoundException(String.format(System.Label.DAE_ObjectDoesNotExist, new List<String>{objectName}));
		}

		return getCache(sot);
	}

	public static DescribeUtils getCache(Schema.SObjectType objectType) {
		if (objectType != null && !CACHE.containsKey(objectType)) {
			CACHE.put(objectType, new DescribeUtils(objectType));
		}
		return CACHE.get(objectType);
	}

	public class RecordTypeNotFoundException extends Exception {}
	public class ObjectNotFoundException extends Exception {}
}