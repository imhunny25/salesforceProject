({
    init: function (component, event, helper) {
        let pRef = component.get("v.pageReference");
        let navRecordProperty = pRef.state.c__navRecordProperty;
        let isViewAll = pRef.state.c__isViewAll;
        let navObjectAPIName = pRef.state.c__isObjectApiName;
        component.set("v.navRecordProperty", navRecordProperty);
        component.set("v.isViewAll", isViewAll);
        component.set("v.navObjectAPIName", navObjectAPIName);
    }
});