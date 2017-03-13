({   
	getCallNoteInformation : function(component, event) {
        var action = component.get("c.getNotesForInteraction");
    	action.setParams({"TaskId" : component.get("v.recordId")});
        action.setCallback(this, function(response) {         
            if (component.isValid() && response.getState() === "SUCCESS") {
                var data = response.getReturnValue();
                component.set ("v.callNotes", data);
                if (data.length > 0) {
                    this.showNotes(component);
                }
                else {
                    this.hideNotes(component);
                }
            }
            else if (component.isValid()) {
                this.hideNotes(component);
            }
        });
    	$A.enqueueAction(action);		
	},
    
    showNotes : function (component) {
        var noteDetail = component.find ('noteDetail');
        var noNotes= component.find ('noNotes');
		$A.util.removeClass(noteDetail, 'hidden');
        $A.util.addClass(noNotes, 'hidden');
    },
    
    hideNotes : function (component) {
        var noteDetail = component.find ('noteDetail');
        var noNotes= component.find ('noNotes');
        $A.util.addClass(noteDetail, 'hidden');
		$A.util.removeClass(noNotes, 'hidden');
	} 
})