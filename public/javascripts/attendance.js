// TODO move to separate file
/*
 * Natural Sort algorithm for Javascript - Version 0.6 - Released under MIT license
 * Author: Jim Palmer (based on chunking idea from Dave Koelle)
 * Contributors: Mike Grier (mgrier.com), Clint Priest, Kyle Adams, guillermo
 */



function naturalSort(a, b) {
    var re = /(^-?[0-9]+(\.?[0-9]*)[df]?e?[0-9]?$|^0x[0-9a-f]+$|[0-9]+)/gi,
            sre = /(^[ ]*|[ ]*$)/g,
            dre = /(^([\w ]+,?[\w ]+)?[\w ]+,?[\w ]+\d+:\d+(:\d+)?[\w ]?|^\d{1,4}[\/\-]\d{1,4}[\/\-]\d{1,4}|^\w+, \w+ \d+, \d{4})/,
            hre = /^0x[0-9a-f]+$/i,
            ore = /^0/,
            // convert all to strings and trim()
            x = a.toString().replace(sre, '') || '',
            y = b.toString().replace(sre, '') || '',
            // chunk/tokenize
            xN = x.replace(re, '\0$1\0').replace(/\0$/, '').replace(/^\0/, '').split('\0'),
            yN = y.replace(re, '\0$1\0').replace(/\0$/, '').replace(/^\0/, '').split('\0'),
            // numeric, hex or date detection
            xD = parseInt(x.match(hre)) || (xN.length != 1 && x.match(dre) && Date.parse(x)),
            yD = parseInt(y.match(hre)) || xD && y.match(dre) && Date.parse(y) || null;
    // first try and sort Hex codes or Dates
    if (yD)
        if (xD < yD)
            return -1;
        else if (xD > yD)
            return 1;
    // natural sorting through split numeric strings and default strings
    for (var cLoc = 0, numS = Math.max(xN.length, yN.length); cLoc < numS; cLoc++) {
// find floats not starting with '0', string or 0 if not defined (Clint Priest)
        oFxNcL = !(xN[cLoc] || '').match(ore) && parseFloat(xN[cLoc]) || xN[cLoc] || 0;
        oFyNcL = !(yN[cLoc] || '').match(ore) && parseFloat(yN[cLoc]) || yN[cLoc] || 0;
        // handle numeric vs string comparison - number < string - (Kyle Adams)
        if (isNaN(oFxNcL) !== isNaN(oFyNcL))
            return (isNaN(oFxNcL)) ? 1 : -1;
        // rely on string comparison if different types - i.e. '02' < 2 != '02' < '2'
        else if (typeof oFxNcL !== typeof oFyNcL) {
            oFxNcL += '';
            oFyNcL += '';
        }
        if (oFxNcL < oFyNcL)
            return -1;
        if (oFxNcL > oFyNcL)
            return 1;
    }
    return 0;
}

//
var students, dates, leaves, holidays, batch, today, req, translated, attendance_status, code, attendance_configuration, saved_dates, attendance_lock, absent_count, at_lock_dates, privilege, seperator, format, late_count;
var days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
var nameTdElem = new Element('td', {
    'class': 'td-name'
}).addClassName('td-name');
var rowElem = new Element('tr', {
    'class': 'tr-odd'
}).addClassName('td-odd');
var absentElem = new Element('a', {
    'class': 'absent',
    'id': ''
}).addClassName('themed_text');
var lateElem = new Element('a', {
    'class': 'late',
    'id': ''
}).addClassName('themed_text');
var presentElem = new Element('a', {
    'class': 'present',
    'id': '',
    'date': ''
}).addClassName('present');
var cellElem = new Element('td', {
    'class': 'td-mark themed_text'
}).addClassName('td-mark themed_text');
var lockTdElem = new Element('td', {
    'class': 'td-lock'
}).addClassName('td-lock');
var lockElem = new Element('a', {
    'class': 'lock-cell',
    'id': 'lock-cell-id',
    'date': ''
});
var absentees = new Element('div', {
    'class': 'absentees-details',
    'id': 'absent-count'
});
var absentCount = new Element('div', {
    'class': 'absent-students',
    'id': 'absent-stds'
});
var lateCount = new Element('div', {
    'class': 'late-students',
    'id': 'late-students'
});
var dtDiv1 = new Element('div', {
    'class': 'day'
}).addClassName('day');
var dtDiv2 = new Element('div', {
    'class': 'date themed_text'
}).addClassName('date themed_text');
var dtDiv1n = new Element('a', {
    'class': 'day'
}).addClassName('day');
var dtDiv2n = new Element('a', {
    'class': ' themed_text'
}).addClassName(' themed_text');
var dateTd = new Element('td', {
    'class': 'head-td-date themed_text',
    'date': '',
    'id': ''
}).addClassName('head-td-date themed_text');

function drawFlashBox() {
    var box = new Element('div', {
        'class': 'flash_msg'
    });
    box.textContent = translated['no_batch_found'];
    return box;
}

function getjson(val) {
    date_today = $('time_zone').value;
    Element.show('loader');
    if (val) {
        new Ajax.Request('/attendances/daily_register.json', {
            parameters: 'batch_id=' + val,
            asynchronous: true,
            evalScripts: true,
            method: 'get',
            onComplete: function (resp) {
                registerBuilder(resp.responseJSON);
                rebind();
                if (resp.responseJSON.students.length >= 1) {
                    j('#pdf_csv_section').css('display', 'block');
                }
                else {
                    j('#pdf_csv_section').css('display', 'none');
                }
                j(".delay-notify").css("display", "inline-block");
                Element.hide('loader');
            }
        });
    }
    else
    {
        j('#register').children().hide();
        j('#register').children().children().hide();
        j("#pdf_csv_section").hide();
        rebind();
        Element.hide('loader');
    }
}

function update_json(val) {
    date_today = $('time_zone').value;
    Element.show('loader');
    if (val) {
        new Ajax.Request('/attendances/daily_register.json', {
            parameters: 'batch_id=' + val + '&next=' + Date.parse(today),
            asynchronous: true,
            evalScripts: true,
            method: 'get',
            onComplete: function (resp) {
                update_json_values(resp.responseJSON);
                sort_students_array(get_sort_order());
                update_students_list();
                rebind();
                Element.hide('loader');
            }
        });
    } else
    {
        j("#register").children().hide();
        rebind();
        Element.hide('loader');
    }
}
function update_json_values(respjson) {
    dates = respjson.dates;
    students = respjson.students;
    leaves = respjson.leaves;
    translated = respjson.translated;
    roll_number_enabled = respjson.roll_number_enabled;
    attendance_configuration = respjson.attendance_config;
    types = respjson.types;
    enable = respjson.enable;
    code = respjson.code;
    attendance_lock = respjson.attendance_lock;
    absent_count = respjson.absent_count;
    at_lock_dates = respjson.at_lock_dates;
    privilege = respjson.privilege;
    seperator = respjson.seperator;
    format = respjson.format;
    late_count = respjson.late_count;
    saved_dates = respjson.saved_dates;
    attendance_status = respjson.attendance_status;
}
function changeMonth() {
    Element.show('loader');
    new Ajax.Request('/attendances/daily_register.json', {
        parameters: 'batch_id=' + this.getAttribute('batch_id') + '&next=' + this.getAttribute('next'),
        asynchronous: true,
        evalScripts: true,
        method: 'get',
        onComplete: function (resp) {
            registerBuilder(resp.responseJSON);
            rebind();
            Element.hide('loader');
        }
    });
}
function drawHeader() {
    var calendarDiv = new Element('div', {
        'class': 'calendar-div'
    });
    var calendar = new Element('input', {
        'type': 'text',
        'id': 'datepicker',
        'class': 'calendar_img'
    });
    calendarDiv.append(calendar);
    var header = new Element('div', {
        'class': 'header'
    }).addClassName('header');
    var month = new Element('div', {
        'class': 'month'
    }).addClassName('month').update(translated[Date.parse(today).toString("MMMM")] + " " + Date.parse(today).toString("yyyy"));
    month.appendChild(calendarDiv);
    var extender = new Element('div', {
        'class': 'extender'
    }).addClassName('extender');
    header.appendChild(month);
    header.appendChild(extender);
    return header;
}
function drawBox() {
    var box = new Element('div', {
        'class': 'box-1',
        'id': 'register-box'
    }).addClassName('box-1');
    var tbl = new Element('table', {
        'id': 'register-table'
    });
    var tblbody = new Element('tbody');
    var headrow = new Element('tr', {
        'class': 'tr-head'
    }).addClassName('tr-head');
    var nameTd = new Element('td', {
        'class': 'head-td-name'
    }).addClassName('head-td-name themed_text').update(translated['student']);
    var dtd, dtdiv1, dtdiv2, ndate, tdate, dtdiv2n;
    tdate = Date.parse(date_today);
    headrow.update(nameTd);
    dates.each(function (dt) {
        ndate = Date.parse(dt);
        dtd = dateTd.cloneNode(true);
        dtd.id = dt;
        dtdiv2 = dtDiv2.cloneNode(true);
        if (attendance_lock == true && dt <= date_today && working_dates.include(dt) && !at_lock_dates.include(dt)) {
            dtdiv1 = dtDiv1n.cloneNode(true);
            dtdiv2n = dtDiv2n.cloneNode(true);
            dtdiv2.appendChild(dtdiv2n);
            dtd.setAttribute('date', dt);
        }
        else {
            dtdiv1 = dtDiv1.cloneNode(true);
        }
        if (holidays.include(dt))
            dtdiv1.addClassName('holiday');
        dtdiv1.update(translated[ndate.toString("ddd")]);
        if (attendance_lock == true && dt <= date_today && working_dates.include(dt) && !at_lock_dates.include(dt)) {
            dtdiv2n.update(ndate.toString("dd"));
        }
        else {
            dtdiv2.update(ndate.toString("dd"));
        }
        if (tdate.equals(ndate) && working_dates.include(dt))
            dtd.addClassName('active');
        dtd.update(dtdiv1);
        dtd.appendChild(dtdiv2);
        if (attendance_lock == true && at_lock_dates.include(dt)) {
            dtd.addClassName('lock-row');
            dtd.addClassName('col-c');
            dtd.setAttribute('date', dt);
        }
        headrow.appendChild(dtd);
    });
    tblbody.update(headrow);
    tbl.update(tblbody);
    box.update(tbl);
    return box;
}
function drawCheckbox() {
    var newdiv = new Element('div', {
        'class': 'quick-attendance-div',
        'id': 'quick_attendance'
    }).addClassName('quick-attendance-div');
    var helperdiv = new Element('div', {
        'id': 'helper_tooltip',
        'style': 'display:none'
    }).addClassName('helper_info');
    helperdiv.update(translated['daily_quick_attendance_explanation']);
    var chkbox = new Element('input', {
        'type': 'checkbox',
        'id': 'quick-attendance-check',
        'checked': false
    });
    var attendancelabel = new Element('label', {
        'class': 'attendance-label'
    }).addClassName('attendance-label');
    attendancelabel.update(translated['rapid_attendance']);
    newdiv.update(attendancelabel);
    newdiv.appendChild(chkbox);
    newdiv.appendChild(helperdiv);
    return newdiv;
}
function drawDelayedCheckbox() {
    var newdiv1 = new Element('div', {
        'class': 'delay-quick-attendance-div',
        'id': 'delay_quick_attendance'
    }).addClassName('delay-quick-attendance-div');
    var helperdiv = new Element('div', {
        'id': 'delay_helper_tooltip',
        'style': 'display:none'
    }).addClassName('delay_helper_info');
    helperdiv.update(translated['delayed_notification_explanation']);
    var chkbox = new Element('input', {
        'type': 'checkbox',
        'id': 'delay-quick-attendance-check',
        'checked': delay_check_val
    });
    var delayattendancelabel = new Element('label', {
        'class': 'delay-attendance-label'
    }).addClassName('delay-attendance-label');
    delayattendancelabel.update(translated['delayed_notification']);
    newdiv1.update(delayattendancelabel);
    newdiv1.appendChild(chkbox);
    newdiv1.appendChild(helperdiv);
    return newdiv1;
}
function registerBuilder(respjson) {
    students = respjson.students;
    leaves = respjson.leaves;
    dates = respjson.dates;
    holidays = respjson.holidays;
    today = respjson.today;
    batch = respjson.batch.batch;
    translated = respjson.translated;
    working_dates = respjson.working_dates;
    roll_number_enabled = respjson.roll_number_enabled;
    attendance_configuration = respjson.attendance_config;
    types = respjson.types;
    enable = respjson.enable;
    code = respjson.code;
    attendance_lock = respjson.attendance_lock;
    absent_count = respjson.absent_count;
    at_lock_dates = respjson.at_lock_dates;
    privilege = respjson.privilege;
    seperator = respjson.seperator;
    format = respjson.format;
    late_count = respjson.late_count;
    saved_dates = respjson.saved_dates;
    attendance_status = respjson.attendance_status;
    //sort list
    if (roll_number_enabled == true && $("sort_selector") != null) {
        sort_students_array(get_sort_order());
    }

    var header = drawHeader();
    var date_present = dateCheck();
    var box = drawBox();
    var attChk = drawCheckbox();
    var delayChk = drawDelayedCheckbox();
    $('register').update(attChk);
    $('register').appendChild(delayChk)
    $('register').appendChild(header);
    datePickerload();
    var flash_box = drawFlashBox();
    if (!date_present) {
        j('#pdf_csv_section').css('display', 'none');
        $('register').appendChild(flash_box);
    }
    else {
        j('#pdf_csv_section').css('display', 'block');
        if (attendance_lock == true) {
            var instructions = drawInstruction();
            $('register').appendChild(instructions);
        }
        $('register').appendChild(box);
        var tbl = $('register-table').down('tbody');
        students.each(function (student) {
            tbl.appendChild(makeRow(student.student, nil));
        });
        if (attendance_lock == true) {
            tbl.appendChild(makeRow('lock', nil));
            var absentees = fetchAbsentees(today);
            $('register-box').appendChild(absentees);
            var submit = drawSubmitButton();
            $('register-box').appendChild(submit);
            var save = drawSaveButton();
            $('register-box').appendChild(save);
        }
        $$('.quick-attendance-div').invoke('observe', 'mouseover', showHelp);
        $$('.quick-attendance-div').invoke('observe', 'mouseout', hideHelp);
        $$('.attendance-label').invoke('observe', 'click', toggleMode);
        $$('.delay-quick-attendance-div').invoke('observe', 'mouseover', delayshowHelp);
        $$('.delay-quick-attendance-div').invoke('observe', 'mouseout', delayhideHelp);
        $$('.delay-attendance-label').invoke('observe', 'click', delaytoggleMode);
        if (roll_number_enabled == true && $("sort_selector") == null) {
            var sort_selector = drawSortSelector();
            $('register').insert({before: sort_selector});
        }
    }

}

function drawInstruction() {
    var instruction = new Element('div', {
        'class': 's-header'
    }).addClassName('s-header');
    instruction.update(translated['select_date']);
    return instruction;
}

function drawSaveButton() {
    var save = new Element('a', {
        'class': 'save-button'
    }).addClassName('save-button');
    save.update("Save");
    return save;
}

function drawSubmitButton() {
    var submit = new Element('a', {
        'class': 'submit-button'
    }).addClassName('submit-button');
    submit.update("Submit");
    return submit;
}
function fetchAbsentees(date) {
    var absent = absentees.cloneNode(true);
    if (working_dates.include(date)) {
        absent.update(formattedDate(date));
        absent.append(' ');
        var day = Date.parse(date).getDay();
        absent.append(days[day]);
        absent.appendChild(absentStudents(date));
        if (enable == "1")
            absent.appendChild(lateStudents(date));
    }
    return absent;
}
function updateAbsentees(date) {
    var absent = $('absent-count');
    absent.update(' ');
    absent.update(formattedDate(date));
    absent.append(' ');
    var day = Date.parse(date).getDay();
    absent.append(days[day]);
    absent.appendChild(absentStudents(date));
    if (enable == "1")
        absent.appendChild(lateStudents(date));
}

function absentStudents(date) {
    var absent_list = absentCount.cloneNode(true);
    absent_list.append(absent_count[date]);
    absent_list.append(' Absent ');
    return absent_list;
}

function lateStudents(date) {
    var late_list = lateCount.cloneNode(true);
    late_list.append(late_count[date]);
    late_list.append(' Late ');
    return  late_list;
}

function toggleMode() {
    if ($('quick-attendance-check').checked == false) {
        $('quick-attendance-check').checked = true;
    }
    else {
        $('quick-attendance-check').checked = false;
    }
}
function delaytoggleMode() {
    if ($('delay-quick-attendance-check').checked == false) {
        $('delay-quick-attendance-check').checked = true;
    }
    else {
        $('delay-quick-attendance-check').checked = false;
    }
}
function showHelp() {
    $('quick_attendance').setStyle({
        height: '10px',
        width: '280px'
    });
    $('helper_tooltip').show();
}
function hideHelp() {
    $('quick_attendance').setStyle({
        height: 'auto',
        width: 'auto'
    });
    $('helper_tooltip').hide();
}
function delayshowHelp() {
    $('delay_quick_attendance').setStyle({
        height: '10px',
        width: '155px'
    });
    $('delay_helper_tooltip').show();
}
function delayhideHelp() {
    $('delay_quick_attendance').setStyle({
        height: 'auto',
        width: 'auto'
    });
    $('delay_helper_tooltip').hide();
}
function makeRow(student) {
    var rowEl = rowElem.cloneNode(true);
    if (student == 'lock') {
        var nameTd = nameTdElem.cloneNode(true);
        rowEl.addClassName('lock-row')
        rowEl.update(nameTdElem.update('Status'));
        dates.each(function (dt) {
            rowEl.appendChild(makeLockCell(dt));
        });
    }
    else {
        var nameTd = nameTdElem.cloneNode(true);
        rowEl.update(nameTd.update(student.name));
        if (attendance_lock == true) {
            dates.each(function (dt) {
                rowEl.appendChild(makeCellLock(student, dt));
            });
        }
        else {
            dates.each(function (dt) {
                rowEl.appendChild(makeCell(student, dt));
            });
        }
    }
    return rowEl;
}

function makeLockCell(dt) {
    var cellEl = cellElem.cloneNode(true);
    cellEl.id = 'date-' + d(dt)
    if (working_dates.include(dt)) {
        if (dt <= date_today) {
            if (at_lock_dates.include(dt)) {
                if (privilege == true) {
                    var lockCell = lockElem.cloneNode(true);
                    lockCell.id = 'date-' + d(dt);
                    lockCell.setAttribute('date', dt);
                    cellEl.appendChild(lockCell);
                }
                else {
                    j('<div>', {
                        "class": "lock-cell",
                        "id": "lock-cell-" + dt,
                        "date": dt
                    }).appendTo(cellEl);
                }
            }
            if (saved_dates.include(dt) && !at_lock_dates.include(dt)) {
                j('<div>', {
                    "class": "unlock-cell",
                    "date": dt,
                    "id": "lock-cell-" + dt
                }).appendTo(cellEl);
            }
            if (attendance_status['marked'].include(dt) && !saved_dates.include(dt) && !at_lock_dates.include(dt)) {
                j('<div>', {
                    "class": "marked-cell",
                    "date": dt,
                    "id": "marked-cell-" + dt
                }).appendTo(cellEl);
            }
        }
    }
    else {
        cellEl.addClassName('holiday');
    }
    return(cellEl);
}

function makeCell(student, dt) {
    var cellEl = cellElem.cloneNode(true);
    cellEl.id = 'student-' + student.id + '-date-' + d(dt);
    var ndate, tdate, adm_date;
    tdate = Date.parse(date_today);
    ndate = Date.parse(dt);
    adm_date = student.admission_date;
    if (tdate.equals(ndate))
        cellEl.addClassName('active');
    if (!holidays.include(dt)) {
        if (leaves[student.id][dt] == null) {
            if (ndate <= tdate) {
                var present = presentElem.cloneNode(true);
                present.setAttribute('date', dt);
                present.setAttribute('admsn_date', adm_date);
                present.id = student.id;
                present.update("O");
            }
            if (working_dates.include(dt)) {
                cellEl.update(present);
            }
            else
            {
                cellEl.addClassName('holiday');
            }
        }
        else {
            if (ndate <= tdate) {
                if (enable == "1") {
                    if (types[student.id][dt] == "Absent") {

                        var absent = absentElem.cloneNode(true);
                        absent.id = leaves[student.id][dt];
                        absent.update(code[student.id][dt]);
                        cellEl.update(absent);
                    }
                    else
                    {
                        var late = lateElem.cloneNode(true);
                        late.id = leaves[student.id][dt];
                        late.update(code[student.id][dt]);
                        cellEl.update(late);
                    }

                }
                else {
                    var absent = absentElem.cloneNode(true);
                    absent.id = leaves[student.id][dt];
                    absent.update("X");
                    cellEl.update(absent);
                }
            }
        }
    }
    else {
        cellEl.addClassName('holiday');
    }
    return(cellEl);
}

function makeCellLock(student, dt) {
    var cellEl = cellElem.cloneNode(true);
    cellEl.id = 'student-' + student.id + '-date-' + d(dt);
    var ndate, tdate, adm_date;
    tdate = Date.parse(date_today);
    ndate = Date.parse(dt);
    adm_date = student.admission_date;
    if (tdate.equals(ndate) && !at_lock_dates.include(dt) && working_dates.include(dt)) {
        cellEl.addClassName('active');
        if (!holidays.include(dt)) {
            if (leaves[student.id][dt] == null) {
                if (ndate <= tdate) {
                    var present = presentElem.cloneNode(true);
                    present.setAttribute('date', dt);
                    present.setAttribute('admsn_date', adm_date);
                    present.id = student.id;
                    present.update("O");
                }
                if (working_dates.include(dt))
                    cellEl.update(present);
                else
                    cellEl.addClassName('holiday');
            }
            else {
                if (ndate <= tdate) {
                    if (enable == "1") {
                        if (types[student.id][dt] == "Absent") {
                            var absent = absentElem.cloneNode(true);
                            absent.id = leaves[student.id][dt];
                            absent.update(code[student.id][dt]);
                            cellEl.update(absent);
                        }
                        else {
                            var late = lateElem.cloneNode(true);
                            late.id = leaves[student.id][dt];
                            late.update(code[student.id][dt]);
                            cellEl.update(late);
                        }
                    }
                    else {
                        var absent = absentElem.cloneNode(true);
                        absent.id = leaves[student.id][dt];
                        absent.update("X");
                        cellEl.update(absent);
                    }
                }
            }
        }
        else
            cellEl.addClassName('holiday');
    }
    else {
        if (!holidays.include(dt)) {
            if (leaves[student.id][dt] == null) {
                if (working_dates.include(dt)) {
                    if (ndate <= tdate && saved_dates.include(dt)) {
                        if (dt >= adm_date)
                            cellEl.update('P');
                    }
                }
                else
                    cellEl.addClassName('holiday');
            }
            else {
                if (ndate <= tdate) {
                    if (enable == "1")
                        cellEl.update(code[student.id][dt]);
                    else
                        cellEl.update('X');
                }
            }
        }
    }
    if (at_lock_dates.include(dt)) {
        cellEl.removeClassName('themed_text');
        cellEl.addClassName('locked');
        if (tdate.equals(ndate))
            cellEl.addClassName('active');
    }
    return(cellEl);
}

function d(dt) {
    var dtar = dt.split("-");
    dt = dtar[2] + '-' + dtar[1] + '-' + dtar[0];
    return dt;
}

function handleData(request) {
    req = request;
}

function cellHover() {
    if (!this.className.split(" ").include('holiday')) {
        var cIndex = this.cellIndex;
        var rIndex = this.up().rowIndex;
        var tbl = this.up(1);
        var dt = getDate(rIndex, cIndex, tbl);
        var name = getName(rIndex, cIndex, tbl);
        var descEl = makeHoverEl(dt, name);
        if (this.down('.date') == null)
            this.appendChild(descEl);
    }
    else
    {
        this.addClassName('nohover');
    }
}
function getDate(row, col, tbl) {
    var el = tbl.children[0].children[col];
    return({
        'day': el.down('.day').innerHTML,
        'date': el.down('.date').innerHTML
    });
}
function getName(row, col, tbl) {
    var el = tbl.children[row].children[0];
    return(el.innerHTML);
}
function makeHoverEl(dt, name) {
    var maindiv = new Element('div', {
        'class': 'date themed_text'
    }).addClassName('date');
    var spanel = new Element('span');
    var secdiv = new Element('div');
    secdiv.update(name);
    spanel.update(dt.day + " " + dt.date);
    spanel.appendChild(secdiv);
    maindiv.update(spanel);
    return(maindiv);
}

function rebind() {
    $$('.absent').invoke('observe', 'click', edit);
    $$('.late').invoke('observe', 'click', edit);
    $$('.present').invoke('observe', 'click', add);
    $$('.td-mark').invoke('observe', 'mouseover', cellHover);
    $$('.goto').invoke('observe', 'click', changeMonth);
    $$('.head-td-date').invoke('observe', 'click', update_leave_json);
    $$('.save-button').invoke('observe', 'click', saveAttendance);
    $$('.submit-button').invoke('observe', 'click', lockAttendance);
    $$('.lock-cell').invoke('observe', 'click', unlockAttendance);
    $$('.calendar_img').invoke('observe', 'click', datePicker);
}

function saveAttendance() {
    var active_cell = $$('.active');
    if (active_cell.length > 0) {
        var date = $$('.active')[0].getAttribute('date');
        new Ajax.Request('/attendances/save_attendance',
                {
                    parameters: 'batch_id=' + $("batch_id").value + '&date=' + $$('.active')[0].getAttribute('date'),
                    asynchronous: true,
                    evalScripts: true,
                    method: 'get'
                }
        );
        update_response_values(date);
    }
    else {
        alert(translated['select_for_save']);
    }
}

function update_response_values(date) {
    var batch = $("batch_id").value;
    if (batch) {
        new Ajax.Request('/attendances/daily_register.json', {
            parameters: 'batch_id=' + batch + '&next=' + Date.parse(today),
            asynchronous: true,
            evalScripts: true,
            method: 'get',
            onComplete: function (resp) {
                update_json_values(resp.responseJSON);
                update_status(date);
                updateAbsentees(date);
            }
        });
    }
}

function update_status(date) {
    var cell = $('marked-cell-' + date);
    if (cell == null) {
      var cell = $('date-' + d(date)); 
    }
    cell.removeClassName('marked-cell');
    cell.addClassName('unlock-cell');
    cell.id = 'lock-cell-' + date;
}


function lockCells(date) {
    new Ajax.Request('/attendances/lock_attendance',
            {
                parameters: 'batch_id=' + $("batch_id").value + '&date=' + date,
                asynchronous: true,
                evalScripts: true,
                method: 'get'
            }
    );
    lockColumn(date);
}

function lockAttendance() {
    var batch = $("batch_id").value;
    var active_cell = $$('.active');
    if (batch && (active_cell.length > 0)) {
        var date = $$('.active')[0].getAttribute('date');
        new Ajax.Request('/attendances/daily_register.json', {
            parameters: 'batch_id=' + batch + '&next=' + Date.parse(today),
            asynchronous: true,
            evalScripts: true,
            method: 'get',
            onComplete: function (resp) {
                update_json_values(resp.responseJSON);
                lockCells(date);
                rebind();
            }
        });
    }
    else {
        alert(translated['select_for_lock']);
    }
}

function unlockAttendance() {
    if (privilege) {
        var date = this.getAttribute('date');
        new Ajax.Request('/attendances/unlock_attendance',
                {
                    parameters: 'batch_id=' + $("batch_id").value + '&date=' + date,
                    asynchronous: true,
                    evalScripts: true,
                    method: 'get'
                }
        );
        unlockedColumn(date);
    }
}

function lockColumn(date) {
    var lockedCell = $('lock-cell-' + date);
    if (lockedCell == null) {
        var lockedCell = $('marked-cell-' + date);
        lockedCell.removeClassName('marked-cell');
    }
    lockedCell.update(' ');
    var ndate = Date.parse(date);
    var head = $(date);
    var dtdiv1 = dtDiv1.cloneNode(true);
    var dtdiv2 = dtDiv2.cloneNode(true);
    head.update(dtdiv1);
    head.appendChild(dtdiv2);
    dtdiv1.update(translated[ndate.toString("ddd")]);
    dtdiv2.update(ndate.toString("dd"));
    head.addClassName('lock-row');
    head.addClassName('col-c');
    head.removeClassName('unlock-row');
    lockedCell.removeClassName('unlock-cell');
    if (privilege) {
        var lockCell = lockElem.cloneNode(true);
        lockCell.id = 'date-' + d(date);
        lockCell.setAttribute('date', date);
        lockedCell.appendChild(lockCell);
    }
    else {
        j('<div>', {
            "class": "lock-cell",
            "id": "lock-cell-" + date,
            "date": date
        }).appendTo(lockedCell);
    }
    students.each(function (student) {
        var adm_date = student.student.admission_date;
        cellEl = $('student-' + student.student.id + '-date-' + d(date));
        if (cellEl != null) {
            cellEl.removeClassName('themed_text');
            cellEl.addClassName('locked');
            if (leaves[student.student.id][date] == null) {
                if (date >= adm_date)
                    cellEl.update('P');
            }
            else {
                if (enable == "1")
                    cellEl.update(code[student.student.id][date]);
                else
                    cellEl.update('X');
            }
        }
    });
    rebind();
}

function unlockedColumn(date) {
    var headrow = $(date);
    var activeCell = headrow.getAttribute('class').include('active');
    headrow.update(' ');
    var dt = Date.parse(date);
    var dtdiv2, dtdiv1, dtdiv2n;
    dtdiv2 = dtDiv2.cloneNode(true);
    dtdiv1 = dtDiv1n.cloneNode(true);
    dtdiv2n = dtDiv2n.cloneNode(true);
    dtdiv2.appendChild(dtdiv2n);
    headrow.setAttribute('date', date);
    dtdiv1.update(translated[dt.toString("ddd")]);
    dtdiv2n.update(dt.toString("dd"));
    headrow.update(dtdiv1);
    headrow.appendChild(dtdiv2);
    headrow.removeClassName('lock-row');
    headrow.removeClassName('col-c');
    headrow.addClassName('unlock-row');
    var unlockCell = $('date-' + d(date));
    unlockCell.update(' ');
    j('<div>', {
        "class": "unlock-cell",
        "date": date,
        "id": "lock-cell-" + date
    }).appendTo(unlockCell);
    students.each(function (student) {
        cellEl = $('student-' + student.student.id + '-date-' + d(date));
        cellEl.removeClassName('locked');
        cellEl.addClassName('themed_text');
        var adm_date = student.student.admission_date;
        if (cellEl != null) {
            if (activeCell) {
                if (leaves[student.student.id][date] == null) {
                    var present = presentElem.cloneNode(true);
                    present.setAttribute('date', dt);
                    present.setAttribute('admsn_date', adm_date);
                    present.id = student.student.id;
                    present.update("O");
                    cellEl.update(present);
                }
                else {
                    if (enable == "1") {
                        if (types[student.student.id][date] == "Absent") {
                            var absent = absentElem.cloneNode(true);
                            absent.id = leaves[student.student.id][date];
                            absent.update(code[student.student.id][date]);
                            cellEl.update(absent);
                        }
                        else {
                            var late = lateElem.cloneNode(true);
                            late.id = leaves[student.student.id][date];
                            late.update(code[student.student.id][date]);
                            cellEl.update(late);
                        }
                    }
                    else {
                        var absent = absentElem.cloneNode(true);
                        absent.id = leaves[student.student.id][date];
                        absent.update("X");
                        cellEl.update(absent);
                    }
                }
            }
            else {
                if (leaves[student.student.id][date] == null) {
                    if (date >= adm_date)
                        cellEl.update('P');
                }
                else {
                    if (enable == "1")
                        cellEl.update(code[student.student.id][date]);
                    else
                        cellEl.update('X');
                }


            }
        }
    });
    rebind();
}

function update_leave_json() {
    var date = this.getAttribute('date');
    var lock = this.getAttribute('class').include('col-c');
    var batch = $("batch_id").value
    if (batch) {
        new Ajax.Request('/attendances/daily_register.json', {
            parameters: 'batch_id=' + batch + '&next=' + Date.parse(today),
            asynchronous: true,
            evalScripts: true,
            method: 'get',
            onComplete: function (resp) {
                update_json_values(resp.responseJSON);
                dateSelect(date, lock);
                rebind();
            }
        });
    }

}

function dateSelect(date, lock) {
    if (working_dates.include(date) && !lock && date != null) {
        var active_cell = $$('.active');
        if (active_cell.length != 0) {
            var padate = active_cell[0].getAttribute('date');
            active_cell[0].removeClassName('active');
            students.each(function (student) {
                var adm_date = student.student.admission_date;
                cellEl = $('student-' + student.student.id + '-date-' + d(padate));
                if (cellEl != null) {
                    cellEl.update('');
                    cellEl.removeClassName('active');
                    if (leaves[student.student.id][padate] == null) {
                        if (saved_dates.include(padate)) {
                            if (date >= adm_date)
                                cellEl.update('P');
                        }
                    }
                    else {
                        if (enable == "1")
                            cellEl.update(code[student.student.id][padate]);
                        else
                            cellEl.update('X');
                    }
                }
            });
            if (attendance_status['marked'].include(padate) && !saved_dates.include(padate) && !at_lock_dates.include(padate)) {
                var unmarked = $('date-' + d(padate));
                unmarked.update(' ');
                j('<div>', {
                    "class": "marked-cell",
                    "date": padate,
                    "id": "marked-cell-" + padate
                }).appendTo(unmarked);

            }
        }
        if (!lock) {
            $(date).addClassName('active');
            selectColumn(date);
            updateAbsentees(date);
        }
    }
}


function selectColumn(dt) {
    students.each(function (student) {
        cellEl = $('student-' + student.student.id + '-date-' + d(dt));
        var adm_date = student.student.admission_date;
        cellEl.addClassName('active');
        if (leaves[student.student.id][dt] == null) {
            var present = presentElem.cloneNode(true);
            present.setAttribute('date', dt);
            present.setAttribute('admsn_date', adm_date);
            present.id = student.student.id;
            present.update("O");
            cellEl.update(present);
        }
        else {
            if (enable == "1") {
                if (types[student.student.id][dt] == "Absent") {
                    var absent = absentElem.cloneNode(true);
                    absent.id = leaves[student.student.id][dt];
                    absent.update(code[student.student.id][dt]);
                    cellEl.update(absent);
                }
                else {
                    var late = lateElem.cloneNode(true);
                    late.id = leaves[student.student.id][dt];
                    late.update(code[student.student.id][dt]);
                    cellEl.update(late);
                }
            }
            else {
                var absent = absentElem.cloneNode(true);
                absent.id = leaves[student.student.id][dt];
                absent.update("X");
                cellEl.update(absent);
            }
        }
    });
}

function edit() {
    new Ajax.Request('/attendances/' + this.id + '/edit',
            {
                asynchronous: true,
                evalScripts: true,
                method: 'get'
            }
    );
}
function add() {
    if ($('quick-attendance-check').checked == false) {
        new Ajax.Request('/attendances/new',
                {
                    parameters: 'id=' + this.id + '&date=' + this.getAttribute('date') + '&delay_notif=' + $('delay-quick-attendance-check').checked,
                    asynchronous: true,
                    evalScripts: true,
                    method: 'get'
                }
        );
    }
    else {
        if (this.getAttribute('admsn_date') <= this.getAttribute('date') || (attendance_configuration === true))
        {
            new Ajax.Request('/attendances/quick_attendance',
                    {
                        parameters: 'id=' + this.id + '&date=' + this.getAttribute('date') + '&delay_notif=' + $('delay-quick-attendance-check').checked,
                        asynchronous: true,
                        evalScripts: true,
                        method: 'get'
                    }
            );
        }
        else
        {
            alert(translated['attendance_before_the_date_of_admission_is_invalid']);
        }
    }
}
function drawSortSelector() {
    var newdiv = new Element('div', {
        'class': 'sort_selector',
        'id': 'sort_selector'
    });
    var form = new Element('form', {'id': 'sort_form'});
    var form_label = new Element('label', {'id': 'form_label'}).update(translated.sort_by);
    var sort_by_name_input = new Element('input', {'id': 'sort_by_name', 'value': 0, 'name': 'sort_order_selector', 'type': 'radio', 'checked': 'checked', 'class': 'sort_by_input'});
    var sort_by_roll_number_input = new Element('input', {'id': 'sort_by_roll_number', 'value': 1, 'name': 'sort_order_selector', 'type': 'radio', 'class': 'sort_by_input'});
    var sort_by_name_label = new Element('label', {'for': 'sort_by_name', 'class': 'sort_by_label', 'id': 'sort_by_name_label'}).update(translated.name);
    var sort_by_roll_number_label = new Element('label', {'for': 'sort_by_roll_number', 'class': 'sort_by_label', 'id': 'sort_by_roll_number_label'}).update(translated.student_roll_number);
    form.appendChild(form_label);
    form.appendChild(sort_by_name_input);
    form.appendChild(sort_by_name_label);
    form.appendChild(sort_by_roll_number_input);
    form.appendChild(sort_by_roll_number_label);
    form.observe('change', sort_students);
    newdiv.appendChild(form);
    return newdiv;
}
function sort_students(event) {
    sort_order = get_sort_order();
    update_json($("batch_id").value);
}
function get_sort_order() {
    value = $$('input:checked[type=radio][name=sort_order_selector]')[0].value;
    return parseInt(value);
}
function sort_students_array(order) {
    if (order == 0) {

        students = students.sortBy(function (s) {
            return s.student.first_name;
        });
    } else if (order == 1) {
        students = students.sort(function (a, b) {
            if (!a.student.roll_number && !b.student.roll_number) {
                return false;
            } else if (!a.student.roll_number) {
                return 1;
            } else if (!b.student.roll_number) {
                return 0;
            } else {
                return naturalSort(a.student.roll_number, b.student.roll_number);
            }
        });
    }
}


function update_students_list() {
    Element.remove($$(".box-1")[0]);
    box = drawBox();
    $('register').appendChild(box);
    var tbl = $('register-table').down('tbody');
    students.each(function (student) {
        tbl.appendChild(makeRow(student.student));
    });
    if (attendance_lock == true) {
        tbl.appendChild(makeRow('lock', nil));
        var absentees = fetchAbsentees(today);
        $('register-box').appendChild(absentees);
        var submit = drawSubmitButton();
        $('register-box').appendChild(submit);
        var save = drawSaveButton();
        $('register-box').appendChild(save);
    }
    rebind();
}
document.observe("dom:loaded", function () {
    rebind();
});
function formattedDate(date) {
    var d = new Date(date || Date.now()),
            month = '' + (d.getMonth() + 1),
            day = '' + d.getDate(),
            year = d.getFullYear();
    if (month.length < 2) {
        month = '0' + month
    }
    ;
    if (day.length < 2) {
        day = '0' + day
    }
    ;
    var date_format = format;
    if (date_format == 1) {
        return [day, month, year].join(seperator);
    }

    if (date_format == 2) {
        return [month, day, year].join(seperator);
    }

    if (date_format == 3) {
        return [year, month, day].join(seperator);
    }

}

function datePicker() {
    j('#datepicker').MonthPicker();
}


function datePickerload() {
    j("#datepicker").MonthPicker({
        MaxMonth: 0,
        showOn: "button",
        buttonImage: "images/calendar_date_select/calendar.gif",
        buttonImageOnly: true,
        SelectedMonth: Date.parse(today),
        OnAfterChooseMonth: function (selectedDate) {
            updateRegister();
        }
    });
}
function updateRegister() {
    var date = j('#datepicker').val();
    var val = $("batch_id").value;
    Element.show('loader');
    if (val) {
        new Ajax.Request('/attendances/daily_register.json', {
            parameters: 'batch_id=' + val + '&next=' + Date.parse(date),
            asynchronous: true,
            evalScripts: true,
            method: 'get',
            onComplete: function (resp) {
                registerBuilder(resp.responseJSON);
                rebind();
                Element.hide('loader');
            }
        });
    } else
    {
        j("#register").children().hide();
        rebind();
        Element.hide('loader');
    }

}

function dateCheck() {
    var date_check = false;
    if (dates.length > 0)
        date_check = true;
    return date_check;
}
