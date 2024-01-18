import { api, LightningElement, track } from 'lwc';
import getSearchItems from '@salesforce/apex/CustomLookupFieldController.getItemsList';
export default class CustomLookupField extends LightningElement {
    @api
    label;
    @api
    objectName;
    @api
    leftAbbr;
    @api
    filter;
    @api
    iconName;
    @api
    searchFields;
    @api
    displayFields;
    @api
    required;
    @api
    isDisabled;
    @api
    fieldname;
    @api
    placeHolderText;

    @api
    hideLabel;
    

    @api
    systemMode;

    @track
    inputValue = '';

    @track
    searchHint;

    @track
    searchInProgress = false;

    @track
    items;

    @track
    createString;

    @track
    selectedItem;

    @api
    defaultFilter;
    @api
    allowTextInput;

    @api
    textInput;

    @api
    immediateCreation;

    @track
    comboboxDropDownClass = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
    @track
    iconControlClass = 'slds-combobox__form-element slds-input-has-icon slds-input-has-icon_right'
    @track
    inputClass = '';
    @track
    comboboxClass = "slds-combobox_container";
    @track
    hasError = false;
    @track
    errorMessage;

    rendered = false;
    connectedCallback(){
        const loadedEvent = new CustomEvent('loaded');
        this.dispatchEvent(loadedEvent);
    }
    onFocused(event) {
        this.comboboxDropDownClass += ' slds-is-open';
        this.performSearch();
    }
    @api
    onFocusOut(ignoreValidation) {

        this.comboboxDropDownClass = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click'; // slds-is-open';
        if (this.selectedItem || this.textInput) {
            this.iconControlClass = 'slds-combobox__form-element slds-input-has-icon slds-input-has-icon_left-right'
            this.removeErrors();
        } else if (ignoreValidation !== true) {
            this.setErrors();
        }

    }
    renderedCallback() {
        if (!this.rendered) {
            const styleOverwrite = document.createElement('style');
            styleOverwrite.innerText = '.disabled-link a {color: rgb(148,148,148);} .info_table td {padding: 0}';
            this.template.querySelector('.css-overwriter').appendChild(styleOverwrite);
            this.rendered = true;
        }
    }
    performSearch(event) {
        if (this.inputValue && this.inputValue.length > 0 && this.inputValue.length < 3) {
            this.searchHint = 'At least 3 symbols required to search.';
        }
        this.searchInProgress = true;
        var searchFieldsArray = this.searchFields ? this.searchFields.replace(/\s/g, "").split(',') : [];
        var displayFieldsArray = this.displayFields ? this.displayFields.replace(/\s/g, "").split(',') : [];
        getSearchItems({
            objectName: this.objectName,
            searchFields: searchFieldsArray,
            displayFields: displayFieldsArray,
            inputValue: this.inputValue,
            defaultFilter: this.defaultFilter,
            systemMode: this.systemMode
        }).then(response => {
            this.items = response;
            if (this.items.length === 0 && this.inputValue && this.inputValue.length >= 3) {
                this.searchHint = '<div class="slds-text-body_regular"><div style="font-size: 1.2rem; float: left;">🧐</div><div style="padding-top: 0.5em;font-size: 0.8rem;">&nbsp;We didn’t find such ' + this.objectName + ' in our database.</div></div>';
            }

            if (this.items.length > 0 && this.inputValue && this.inputValue.length >= 3) {
                this.searchHint = '';
            }

            if (this.inputValue) {
                this.createString = 'Create <b>' + this.inputValue + '</b>';
            }
            if (!this.inputValue) {
                this.createString = this.immediateCreation ? 'Create new ' + this.objectName : '';
            }

            if (!this.inputValue || (this.inputValue && this.inputValue.length < 3)) {
                this.searchHint = 'At least 3 symbols required to search.';
                if (this.items.length > 0) {
                    this.searchHint += '<br/>Recent Items:';
                }
            }


        }).catch(error => {
            this.info = error.body.message;
            console.log('error', error);
        }).finally(() => {
            this.searchInProgress = false;
        });
    }

    selectItem(event) {
        var selectedId = event.currentTarget.dataset.id;
        this.selectedItem = this.items.find(item => {
            return item.itemId === selectedId;
        });
        this.inputClass += this.selectedItem || this.inputValue ? ' slds-hide' : '';
        this.comboboxClass += ' slds-has-selection';
        this.removeErrors();
        this.onFocusOut();
        if (this.selectedItem) {
            this.textInput = false;
        } else if (this.inputValue) {
            this.selectedItem = {
                itemName: this.inputValue
            };
            this.textInput = true;
        }

        const itemSelectedEvent = new CustomEvent('itemselected', {
            detail: this.selectedItem
        });
        this.dispatchEvent(itemSelectedEvent);
    }

    @api
    forceSetItem(itemId, itemName) {
        this.selectedItem = {
            itemId: itemId,
            itemName: itemName
        };
        this.inputClass += ' slds-hide';
        this.textInput = '';
        if(this.comboboxClass.indexOf('slds-has-selection') === -1){
            this.comboboxClass += ' slds-has-selection';
        }
        this.removeErrors();
        this.onFocusOut();
    }

    @api
    removeErrors() {
        this.hasError = false;
        this.errorClass = '';
    }
    @api
    setErrors() {
        if (!this.required) {
            return;
        }
        this.hasError = true;
        this.errorClass = 'slds-has-error';
        this.errorMessage = this.inputValue ? 'Select an option from the picklist.' : 'Complete this field';
    }
    @api
    removeSelected(clearInput) {
        this.selectedItem = null;
        this.textInput = false;
        this.inputClass = this.inputClass.replace(/ slds-hide/g, '');
        this.comboboxClass = this.comboboxClass.replace(/  slds-has-selection/g, '');
        this.iconControlClass = 'slds-combobox__form-element slds-input-has-icon slds-input-has-icon_right';
        const itemRemovedEvent = new CustomEvent('itemremoved');
        if (clearInput) {
            this.inputValue = '';
            //this.template.querySelector('.lookup_input').value = '';
        }
        this.dispatchEvent(itemRemovedEvent);
        this.onFocusOut();
    }
    @api
    removeSelectedLite(clearInput) {
        this.selectedItem = null;
        this.textInput = false;
        this.inputClass = this.inputClass.replace(/ slds-hide/g, '');
        this.comboboxClass = this.comboboxClass.replace(/  slds-has-selection/g, '');
        this.iconControlClass = 'slds-combobox__form-element slds-input-has-icon slds-input-has-icon_right';
        if (clearInput) {
            this.inputValue = '';
            //this.template.querySelector('.lookup_input').value = '';
        }
        this.onFocusOut();
    }
    onSearchChange(event) {
        this.inputValue = event.target.value;
        this.performSearch();

        const userInputEvent = new CustomEvent('searchinput', {
            detail: this.inputValue
        });
        this.dispatchEvent(userInputEvent);
    }

    preventChange(event) {
        event.preventDefault();
    }
    @api
    getSelectedContact() {
        return this.selectedItem;
    }
    get placeHolderInput(){
        return this.placeHolderText ? this.placeHolderText : 'Search...';
    }
}