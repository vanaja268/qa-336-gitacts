({
    // CSN-336 TC-05: Aura helper JS
    render: function (component) {
        var el = component.find('out').getElement();
        el.innerHTML = component.get('v.msg');   // innerHTML (XSS)
        eval('void 0');                          // eval
    }
})
