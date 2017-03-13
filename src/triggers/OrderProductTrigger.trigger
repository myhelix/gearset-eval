/*
    @author: Shirish Goel (Thirdwave Analytics)
    @Date: 10/26/2016
    @Purpose: This is trigger OrderItem events
*/
trigger OrderProductTrigger on OrderItem (after update) {
    
    OrderProductTriggerHelper.onAfterUpdate(trigger.new, trigger.oldMap);
    
}