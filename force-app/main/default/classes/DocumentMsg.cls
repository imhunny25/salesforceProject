public with sharing class DocumentMsg {
    public class UploadResponse {
        public String status;
        public String evisortId;
        public String error;
    }

    public class SyncResponse {
        public Integer count;
        public String next;
        public List<Document> documents;
        public String error;
    }

    public class SendValuesRequest {
        public List<Field> fields;

        public SendValuesRequest() {
            this.fields = new List<Field>();
        }
    }

    public class Document {
        public String status;
        public String evisortId;
        public String docId;
        public String dateModified;
        public String name;
        public String path;
        public List<Field> fields;
        public List<Provision> provisions;
        public String error;
    }

    public class Field {
        public String name;
        public List<Value> values;

        public Field() {
        }

        public Field(String inName) {
            this.name = inName;
            this.values = new List<Value>();
        }
    }

    public class Value {
        public String value;

        public Value() {
        }

        public Value(String inValue) {
            this.value = inValue;
        }
    }

    public class Provision {
        public String name;
        public List<Content> content;
    }

    public class Content {
        public String text;
        public Decimal score;
    }

    public class RecordData {
        public Id id;
        public String objectName;
        public String name;
        public String recordTypeName;
        public String parentDirectory;
    }

    public class DocuemntQueueableResponse {
        public String next;
        public Datetime lastProcessed;

        public DocuemntQueueableResponse(String inUrl) {
            this.next = inUrl;
            this.lastProcessed = null;
        }
    }
}