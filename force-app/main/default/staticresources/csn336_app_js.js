/* CSN-336 TC-01: JavaScript Static Resource referenced from CSN336_ResourcePage via $Resource.
   Contains deliberate ESLint-style issues. */
var appConfig = { debug: true };                 // var instead of let/const

function loadData(id) {
    var unused = 'not used';                     // unused variable
    if (id == undefined) {                       // == comparison
        console.log('no id');                    // console statement
        return;
    }
    debugger;                                    // debugger statement
    var fn = new Function('return ' + id);       // implied eval
    return eval(fn());                           // eval usage
}

function duplicateKeys() {
    return { a: 1, a: 2 };                       // duplicate object key
}

function unreachable() {
    return 1;
    console.log('never');                        // unreachable code
}

loadData(appConfig.debug);
duplicateKeys();
unreachable();
