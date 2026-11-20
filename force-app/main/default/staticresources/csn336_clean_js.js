/* CSN-336 TC-02: clean JavaScript Static Resource - expected 0 issues. */
'use strict';

const greet = (name) => {
    const message = `Hello, ${name}`;
    return message;
};

window.csn336Greet = greet;
