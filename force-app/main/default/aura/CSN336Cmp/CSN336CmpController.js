({
    // CSN-336 TC-05: Aura controller JS
    handleClick: function (component, event, helper) {
        var unusedVar = 'x';                     // unused
        if (component.get('v.msg') == '') {      // == comparison
            console.log('empty');                // console statement
        }
        helper.render(component);
    }
})
