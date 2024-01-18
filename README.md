# Salesforce Custom Lookup

## Description
Generic LWC component that can be used for frontend customization in Salesforce to input data for Salesforce lookup field.
Appearance of the component is fully imitated standard Lightning Lookup field and can be customized anyway it's needed.

## How to Use
- Load LWC component and its controller to your org.
- Insert the component to your page following parameters below.

## Parameters
- `object-name` - API name of the object that has required lookup field.
- `fieldname` - API name of the lookup field
- `icon-name` - name of the icon to be displayed on the lookup. ex. "standard:contact". [List of icons.](https://www.lightningdesignsystem.com/icons/)
- `display-fields` - list of api names of fields are displaying in the dropdown list while search. Should be separated by comma. Parent fields are also supported.
- `search-fields` - list of api names of fields to search the item for the lookup. Should be separated by comma.
- `onitemselected` - lwc action to be trigger when the item is selected in dropdown list.
- `allow-text-input` - true/false. True: If user typed the value in the lookup but no item found in the dropdown, then the value can be selected by user and will be saved as text value in LWC. False: standard behaviour.
- `onitemremoved` - lwc action to be trigger when the selected value is removed from the lookup.
- `default-filter` - imitation of standard lookup filter. Applies SQL conditions as the input after "WHERE" (ex. "IsActive = true and Type="Potato")
- `onloaded` - lwc action to be trigger when the component is loaded
- `system-mode` - true/false. true - system context, false - user context (according permissions)
- `place-holder-text` - text for empty lookup (ex. "Select contact..")
- `required` - if the lookup value is required.
- `label` - label of the lookup field.
- `hide-label` - true/false. Visibility of lookup's label.
- `left-abbr` - where abbr should be placed for the label (for required=true mode)





