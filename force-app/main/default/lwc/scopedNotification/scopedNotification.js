/**
 * Dynamic Scope Notification component
 *
 * @prop {string} state REQUIRED; Accepts success, warning, info or error as an option. Defaults to info
 * @prop {boolean} lightTheme Uses light theme for Info state if true; Defaults to dark
 * @slot {component/html/string} Named "body"
 */

import { LightningElement, api } from "lwc";

const SUCCESS = "success",
    WARNING = "warning",
    INFO = "info",
    ERROR = "error";

export default class ScopedNotification extends LightningElement {
    @api lightTheme;
    normalizedState;

    @api
    get state() {
        return this.normalizedState;
    }

    set state(value = INFO) {
        const stateVal = value.toLowerCase();
        this.normalizedState = [SUCCESS, WARNING, ERROR, INFO].includes(stateVal) ? stateVal : INFO;
    }

    get computedClasses() {
        const base = "slds-scoped-notification slds-media slds-media_center";
        const theme = this.lightTheme ? "slds-scoped-notification_light" : "slds-scoped-notification_dark";

        // If state is INFO using the light or dark theme class suffices.
        return [SUCCESS, WARNING, ERROR].includes(this.normalizedState)
            ? `${base} slds-theme_${this.normalizedState}`
            : `${base} ${theme}`;
    }

    get computedIconClasses() {
        return `slds-icon_container slds-icon-utility-${this.normalizedState}`;
    }

    get iconName() {
        return `utility:${this.normalizedState}`;
    }
}