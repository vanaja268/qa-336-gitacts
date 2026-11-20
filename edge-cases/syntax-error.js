// CSN-336 TC-08: syntactically broken JS. Scanner must log a parse error for this file
// and CONTINUE (no engine crash, no "Stream closed", scan still EXECUTION SUCCESS).
function broken( {
    return 1 +;
}
