/* CSN-336 TC-03: JS inside a ZIP static resource (folder in source format). */
var Lib = {};
Lib.sum = function (a, b) {
    if (a == b) { console.warn('same'); }       // == comparison, console
    with (Math) { return max(a, b) + a + b; }    // 'with' statement
};
window.Lib = Lib;
