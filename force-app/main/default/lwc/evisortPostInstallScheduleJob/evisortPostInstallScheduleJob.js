import { LightningElement, api, track } from 'lwc';
import editScheduler from "@salesforce/apex/PostInstallationController.editScheduler";

export default class EvisortPostInstallScheduleJob extends LightningElement {
    @api openModal;
    
    @track isDisabledWeekly = true;
    @track isDisabledTime = true;
    @track Sunday;
    @track Monday;
    @track Tuesday;
    @track Wednesday;
    @track Thursday;
    @track Friday;
    @track Saturday;
    @track Week;
    @track WeekDay;
    @track loaded = true;
    @track loadedEdit = true;
    @track deleteSchedule;
    @track jobSchedule;
    @track dayOfWeek = []
    @track weekOfMonth = [];
    @track preferTimes = [];
    @track monthDays = [];
  
    isDisable = true;
    isDisabledMonthly = true;
    isDisabledWeekDay = true;
    @track loadedEdit = true;
    freqOptions = [{ label: 'Weekly', value: 'Weekly' }, { label: 'Monthly', value: 'Monthly' }];
    tempDayOfWeek = [
      {
        "label": "Day",
        "value": ""
      },
      {
        "label": "Monday",
        "value": "Mon"
      },
      {
        "label": "Tuesday",
        "value": "Tue"
      },
      {
        "label": "Wednesday",
        "value": "Wed"
      },
      {
        "label": "Thursday",
        "value": "Thu"
      },
      {
        "label": "Friday",
        "value": "Fri"
      },
      {
        "label": "Saturday",
        "value": "Sat"
      },
      {
        "label": "Sunday",
        "value": "Sun"
      }
    ];
  
    tempWeekOfMonth = [
      {
        "label": "Week",
        "value": ""
      },
      {
        "label": "1st",
        "value": "1"
      }, {
        "label": "2st",
        "value": "2"
      }, {
        "label": "3st",
        "value": "3"
      }, {
        "label": "4st",
        "value": "4"
      }
    ];
  
    @track sendRepeatSelected = false;
    @track repeatWeeklySelected = false;
    @track repeatMonthlySelected = false;
    @track selectedRepeatValue = 'Weekly';
    @track clearCache = true;
    @track repeatMonthlyFreq1 = false;
    @track allMonths = [];
    @track repeatMonthlyFreq2 = false;
    @track recurrenceFrequency = {
      weekly: {},
      monthly: {
        "dayMonth": {
          "day": ""
        },
        "weekDayMonth": {
          "week": "",
          "day": ""
        }
      },
      time: ""
    };
    clearRecurrenceFrequency = {
      "dayMonth": {
        "day": ""
      },
      "weekDayMonth": {
        "week": "",
        "day": ""
      }
    };
  
    get isRecur1Disabled() {
      return !this.repeatMonthlyFreq1;
    }
  
    get isRecur2Disabled() {
      return !this.repeatMonthlyFreq2;
    }
  
    daysOptions() {
      var days = [];
      days.push({ label: 'Day', value: '' });
      for (let i = 1; i <= 31; i++) {
        days.push({ label: i, value: i });
      }
  
      this.monthDays = [...days];
    }
  
    preferredStartTime() {
      var allTime = [];
      allTime.push({ label: '--None--', value: '' });
      for (let i = 1; i <= 12; i++) {
        allTime.push({ label: i + ' : 00 AM', value: i + ' : 00 AM' });
      }
      for (let i = 1; i <= 12; i++) {
        allTime.push({ label: i + ' : 00 PM', value: i + ' : 00 PM' });
      }
  
      this.preferTimes = [...allTime];
    }
  
    get disableSaveButton() {
      if (Object.keys(this.recurrenceFrequency.time).length === 0 && this.recurrenceFrequency.constructor === Object) {
        this.isDisabledTime = true;
      } else {
        this.isDisabledTime = false;
      }
  
      if (Object.keys(this.recurrenceFrequency.weekly).length === 0 && this.recurrenceFrequency.weekly.constructor === Object) {
        this.isDisabledWeekly = true;
      } else {
        this.isDisabledWeekly = false;
      }
  
      if ((Object.keys(this.recurrenceFrequency.monthly.dayMonth.day).length === 0 && this.recurrenceFrequency.monthly.dayMonth.constructor === Object)) {
        this.isDisabledMonthly = true;
      } else {
        this.isDisabledMonthly = false;
      }
  
      if ((Object.keys(this.recurrenceFrequency.monthly.weekDayMonth.week).length === 0 && this.recurrenceFrequency.monthly.weekDayMonth.constructor === Object)
        || (Object.keys(this.recurrenceFrequency.monthly.weekDayMonth.day).length === 0 && this.recurrenceFrequency.monthly.weekDayMonth.constructor === Object)) {
        this.isDisabledWeekDay = true;
      } else {
        this.isDisabledWeekDay = false;
      }
  
      if (this.isDisabledTime == false && (this.isDisabledWeekly == false || this.isDisabledMonthly == false || this.isDisabledWeekDay == false)) {
        this.isDisable = false;
      } else {
        this.isDisable = true;
      }
      return this.isDisable;
    }
  
    @api
    newSchedule() {
      this.getScheduleHandler();
      this.preferredStartTime();
      this.daysOptions();
      this.dayOfWeek = this.tempDayOfWeek;
      this.weekOfMonth = this.tempWeekOfMonth;
      this.repeatWeeklySelected = true;
    }
  
    renderedCallback() {
      this.clearCache = true;
    }
  
    handleClickCancel() {
      this.openModal = false;
      this.repeatMonthlySelected = false;
      this.repeatWeeklySelected = true;
      this.selectedRepeatValue = 'Weekly';
      this.sendRepeatSelected = false;
      this.isDisabledMonthly = true;
      this.clearValues();
  
      const canceljondetails = new CustomEvent("isclose", {
        detail: this.openModal
      });
      this.dispatchEvent(canceljondetails);
    }
  
    clearValues() {
      this.Sunday = false;
      this.Monday = false;
      this.Tuesday = false;
      this.Wednesday = false;
      this.Thursday = false;
      this.Friday = false;
      this.Saturday = false;
      this.day = 'Day';
    }
  
    getScheduleHandler() {
      this.loadedEdit = true;
      this.isModalOpen = true;
      this.sendRepeatSelected = true;
      this.selectedRepeatValue = 'Weekly';
      this.repeatMonthlySelected = false;
      this.repeatWeeklySelected = true;
      this.recurrenceFrequency.weekly = {};
      this.recurrenceFrequency.monthly = this.clearRecurrenceFrequency;
      this.recurrenceFrequency.time = "";
    }
  
    repeatChange(event) {
      try {
        this.clearCache = false;
        var name = event.currentTarget.value;
        if (name == 'repeatMonthlyFreq1') {
          this.repeatMonthlyFreq1 = true;
          this.repeatMonthlyFreq2 = false;
          this.recurrenceFrequency.monthly.weekDayMonth.week = '';
          this.recurrenceFrequency.monthly.weekDayMonth.day = '';
          this.dayOfWeek = this.tempDayOfWeek;
          this.weekOfMonth = this.tempWeekOfMonth;
  
        } else if (name == 'repeatMonthlyFreq2') {
          this.recurrenceFrequency.monthly.dayMonth.day = '';
          this.repeatMonthlyFreq2 = true;
          this.repeatMonthlyFreq1 = false;
          this.daysOptions();
        }
      } catch (error) {
      }
  
    }
  
    handleRepeatFreqSelect(e) {
      this.clearCache = false;
      var val = e.currentTarget.value;
      if (val == 'Weekly') {
        this.repeatWeeklySelected = true;
        this.repeatMonthlySelected = false;
        //this.dayOfMonth = 'Day';
        this.dayOfWeek = this.tempDayOfWeek;
        this.weekOfMonth = this.tempWeekOfMonth;
        this.recurrenceFrequency.monthly.dayMonth.day = '';
        this.recurrenceFrequency.monthly.weekDayMonth.week = '';
        this.recurrenceFrequency.monthly.weekDayMonth.day = '';
        this.daysOptions();
      }
  
      if (val == 'Monthly') {
        this.repeatWeeklySelected = false;
        this.repeatMonthlySelected = true;
        this.repeatMonthlyFreq1 = true;
        this.repeatMonthlyFreq2 = false;
        this.recurrenceFrequency.weekly = {};
        this.clearValues();
      }
    }
  
    handlePicklistValueChange(event) {
      var name = event.currentTarget.name;
      var day = event.currentTarget.value;
      try {
        if (name == 'monthlyWeekNumberRecurOne') {
          this.recurrenceFrequency.monthly.dayMonth.day = day;
        } else if (name == 'monthlyWeekNumberRecurTwo') {
          this.recurrenceFrequency.monthly.weekDayMonth.week = day;
        } else if (name == 'dayNameRecurTwo') {
          this.recurrenceFrequency.monthly.weekDayMonth.day = day;
        } else if (name == 'monthlyMonthNumberRecurTwo') {
          this.recurrenceFrequency.monthly.weekDayMonth.month = day;
        }
      } catch (error) {
      }
    }
  
    handleWeeklySelect(event) {
      let name = event.target.label;
      if (name == 'Sunday') {
        this.Sunday = event.target.checked;
        if (this.Sunday == true) {
          this.recurrenceFrequency.weekly.Sun = this.Sunday;
        } else if (this.Sunday == false) {
          delete this.recurrenceFrequency.weekly['Sun'];
        }
      } else if (name == 'Monday') {
        this.Monday = event.target.checked;
        if (this.Monday == true) {
          this.recurrenceFrequency.weekly.Mon = this.Monday;
        } else if (this.Monday == false) {
          delete this.recurrenceFrequency.weekly['Mon'];
        }
      } else if (name == 'Tuesday') {
        this.Tuesday = event.target.checked;
        if (this.Tuesday == true) {
          this.recurrenceFrequency.weekly.Tue = this.Tuesday;
        } else if (this.Tuesday == false) {
          delete this.recurrenceFrequency.weekly['Tue'];
        }
      } else if (name == 'Wednesday') {
        this.Wednesday = event.target.checked;
        if (this.Wednesday == true) {
          this.recurrenceFrequency.weekly.Wed = this.Wednesday;
        } else if (this.Wednesday == false) {
          delete this.recurrenceFrequency.weekly['Wed'];
        }
      } else if (name == 'Thursday') {
        this.Thursday = event.target.checked;
        if (this.Thursday == true) {
          this.recurrenceFrequency.weekly.Thu = this.Thursday;
        } else if (this.Thursday == false) {
          delete this.recurrenceFrequency.weekly['Thu'];
        }
      } else if (name == 'Friday') {
        this.Friday = event.target.checked;
        if (this.Friday == true) {
          this.recurrenceFrequency.weekly.Fri = this.Friday;
        } else if (this.Friday == false) {
          delete this.recurrenceFrequency.weekly['Fri'];
        }
      } else if (name == 'Saturday') {
        this.Saturday = event.target.checked;
        if (this.Saturday == true) {
          this.recurrenceFrequency.weekly.Sat = this.Saturday;
        } else if (this.Saturday == false) {
          delete this.recurrenceFrequency.weekly['Sat'];
        }
      }
    }
  
    handleChangePreferredStartTime(event) {
      this.recurrenceFrequency.time = event.target.value;
    }
  
    handleClick() {
      console.log('this.recurrenceFrequency.......' + JSON.stringify(this.recurrenceFrequency));
      const jobDetails = new CustomEvent("jobdetails", {
        detail: this.recurrenceFrequency
      });
      this.dispatchEvent(jobDetails);
    }
  
    @api
    editSchedule(editshedularRef) {
      this.loadedEdit = false;
      editScheduler({ editScheduleJob: editshedularRef })
        .then(result => {
          this.loadedEdit = true;
          var value = JSON.parse(result);
          this.recurrenceFrequency = value;
          var tempTime = [];
          this.preferTimes.forEach(ele => {
            if (ele.value == value.time) {
              tempTime.push({ label: ele.label, value: ele.value, isSelected: true });
            } else {
              tempTime.push({ label: ele.label, value: ele.value, isSelected: false });
            }
          })
  
          this.preferTimes = [...tempTime];
  
          if (Object.keys(value.weekly).length > 0) {
            this.repeatWeeklySelected = true;
            this.repeatMonthlySelected = false;
            this.selectedRepeatValue = 'Weekly';
            this.Sunday = value.weekly.Sun;
            this.Monday = value.weekly.Mon;
            this.Tuesday = value.weekly.Tue;
            this.Wednesday = value.weekly.Wed;
            this.Thursday = value.weekly.Thu;
            this.Friday = value.weekly.Fri;
            this.Saturday = value.weekly.Sat;
          }
  
          if ((Object.keys(value.monthly.dayMonth.day).length > 0 || Object.keys(value.monthly.weekDayMonth.week).length > 0) && Object.keys(value.weekly).length <= 0) {
            this.recurrenceFrequency = value;
            this.selectedRepeatValue = 'Monthly';
            this.repeatWeeklySelected = false;
            this.repeatMonthlySelected = true;
  
            if (value.monthly.hasOwnProperty('dayMonth') == true && Object.keys(value.monthly.dayMonth.day).length > 0) {
              this.repeatMonthlyFreq2 = false;
              this.repeatMonthlyFreq1 = true;
  
              var tempDays = [];
              this.monthDays.forEach(ele => {
                if (ele.value == value.monthly.dayMonth.day) {
                  tempDays.push({ label: ele.label, value: ele.value, isSelected: true });
                } else {
                  tempDays.push({ label: ele.label, value: ele.value, isSelected: false });
                }
  
              })
              this.monthDays = [...tempDays];
            }
            if (value.monthly.hasOwnProperty('weekDayMonth') == true && Object.keys(value.monthly.weekDayMonth.week).length > 0) {
              this.repeatMonthlyFreq2 = true;
              this.repeatMonthlyFreq1 = false;
              var temp = [];
              this.tempDayOfWeek.forEach(ele => {
                if (ele.value == value.monthly.weekDayMonth.day) {
                  temp.push({ label: ele.label, value: ele.value, isSelected: true });
  
                } else {
                  temp.push({ label: ele.label, value: ele.value, isSelected: false });
                }
              })
              this.dayOfWeek = [...temp];
  
              var weekTemp = []
              this.tempWeekOfMonth.forEach(ele => {
                if (ele.value == value.monthly.weekDayMonth.week) {
                  weekTemp.push({ label: ele.label, value: ele.value, isSelected: true });
  
                } else {
                  weekTemp.push({ label: ele.label, value: ele.value, isSelected: false });
                }
              })
  
              this.weekOfMonth = [...weekTemp];
            }
          }
        }).catch((error) => {
          showToast(this, this.label.adminError, getFilteredErrorMessage(error), "ERROR");
        });
    }
}