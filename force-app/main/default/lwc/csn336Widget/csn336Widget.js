// CSN-336 TC-04: LWC JavaScript - analysed by the same ESLint engine binary.
import { LightningElement, api } from 'lwc';

export default class Csn336Widget extends LightningElement {
    @api recordId;
    count = 0;

    connectedCallback() {
        var temp = 1;                            // var + unused
        if (this.recordId == null) {             // == comparison
            console.log('no record');            // console statement
        }
        this.template.querySelector('div').innerHTML = this.recordId; // innerHTML in LWC
        setTimeout(() => { this.count++; }, 0);  // async op in connectedCallback
    }
}
