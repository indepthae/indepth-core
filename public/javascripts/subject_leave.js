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
var students, dates, leaves, holidays, batch, today, req, subject_id, attendance_status, translated, datearr, attendance_configuration, code, saved_dates, same_subject, attendance_lock, absent_count, at_lock_dates, privilege, seperator, format, late_count;
var days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
var nameTdElem = new Element('td', {
    'class': 'td-name'
});
var rowElem = new Element('tr', {
    'class': 'tr-odd'
});
var absentElem = new Element('a', {
    'class': 'absent themed_text',
    'id': ''
});
var lateElem = new Element('a', {
    'class': 'late',
    'id': ''
}).addClassName('themed_text');
var presentElem = new Element('a', {
    'class': 'present',
    'id': '',
    'date': ''
});
var cellElem = new Element('td', {
    'class': 'td-mark'
});
var lockTdElem = new Element('td', {
    'class': 'td-lock'
}).addClassName('td-lock');
var lockElem = new Element('a', {
    'class': 'lock-cell',
    'id': 'lock-cell-id',
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
    'class': 'themed_text'
}).addClassName('themed_text');
var dateTd = new Element('td', {
    'class': 'head-td-date themed_text',
    'date': '',
    'id': ''
}).addClassName('head-td-date themed_text');
var dateTd = new Element('td', {
    'class': 'head-td-date',
    'id': '',
    'class_timing_id': ''
});
function getjson(val) {
    date_today = $('time_zone').value;
    Element.show('loader');
    if (val) {
        new Ajax.Request('/attendances/subject_wise_register.json', {
            parameters: 'batch_id=' + $('batch_id').value + '&subject_id=' + val,
            asynchronous: true,
            evalScripts: true,
            method: 'get',
            onComplete: function (resp) {
                $('error_messages').innerHTML = "";
                j('#pdf_csv_section').css('display', 'none');
                if (Object.keys(resp.responseJSON.dates).length > 0) {
                    j('#pdf_csv_section').css('display', 'block');
                }
                registerBuilder(resp.responseJSON);
                rebind();
                j(".delay-notify").css("display", "inline-block");
                Element.hide('loader');
            }
        });
    } else
    {
        j("#register").children().hide();
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
        new Ajax.Request('/attendances/subject_wise_register.json', {
            parameters: 'batch_id=' + $('batch_id').value + '&subject_id=' + val + '&next=' + Date.parse(today),
            asynchronous: true,
            evalScripts: true,
            method: 'get',
            onComplete: function (resp) {
                $('error_messages').innerHTML = "";
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
    new Ajax.Request('/attendances/subject_wise_register.json', {
        parameters: 'batch_id=' + this.getAttribute('batch_id') + '&next=' + this.getAttribute('next') + '&subject_id=' + $('subject_id').value,
        asynchronous: true,
        evalScripts: true,
        method: 'get',
        onComplete: function (resp) {
            $('error_messages').innerHTML = "";
            j('#pdf_csv_section').css('display', 'none');
            if (Object.keys(resp.responseJSON.dates).length > 0) {
                j('#pdf_csv_section').css('display', 'block');
            }
            registerBuilder(resp.responseJSON);
            rebind();
            Element.hide('loader');
        }
    });
}

function registerBuilder(respjson) {
    dates = respjson.dates;
    students = respjson.students;
    leaves = respjson.leaves;
    translated = respjson.translated;
    today = respjson.today;
    batch = respjson.batch.batch;
    roll_number_enabled = respjson.roll_number_enabled;
    attendance_configuration = respjson.attendance_config;
    subject_id = $('subject_id').value;
    datearr = keys(dates).sort();
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
    same_subject = false;
    saved_dates = respjson.saved_dates;
    attendance_status = respjson.attendance_status;
    //sort list
    if (roll_number_enabled == true && $("sort_selector") != null) {
        sort_students_array(get_sort_order());
    }
    var dates_present = dateCheck();
    var header = drawHeader();
    var box = drawBox();
    var attChk = drawCheckbox();
    var delayChk = drawDelayCheckbox();
    var flash_box = drawFlashBox();
    if (dates_present) {
        $('register').update(attChk);
        $('register').appendChild(delayChk)
        $('register').appendChild(header);
    } else {
        $('register').update(header);
    }
    if (attendance_lock == true) {
        var instructions = drawInstruction();
        $('register').appendChild(instructions);
    }
    if (!dates_present) {
        $('register').appendChild(flash_box);
    } else {
        $('register').appendChild(box);
        if (attendance_lock == true && $$('.active').length > 1) {
            same_subject = true;
        }
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
        $$('.quick-attendance-div').invoke('observe', 'mouseover', showHelp);
        $$('.quick-attendance-div').invoke('observe', 'mouseout', hideHelp);
        $$('.attendance-label').invoke('observe', 'click', toggleMode);
        $$('.delay-quick-attendance-div').invoke('observe', 'mouseover', delayshowHelp);
        $$('.delay-quick-attendance-div').invoke('observe', 'mouseout', delayhideHelp);
        $$('.delay-attendance-label').invoke('observe', 'click', delaytoggleMode);
    }
    if (roll_number_enabled == true && $("sort_selector") == null) {
        var sort_selector = drawSortSelector();
        $('register').insert({before: sort_selector});
    }
    if (attendance_lock && same_subject) {
        var active1 = $$('.active')[0];
        var class_timing_id = $$('.active')[0].getAttribute('class_timing_id');
        var date = $$('.active')[0].getAttribute('date');
        active1.removeClassName('active');
        inactive_subject(date, class_timing_id);
    }
    datePickerload();
}


function inactive_subject(date, class_timing_id) {
    students.each(function (student) {
        var adm_date = student.student.admission_date;
        cellEl = $('student-' + student.student.id + '-date-' + d(date) + '-timing-' + class_timing_id);
        cellEl.removeClassName('active');
        if (cellEl != null) {
            if (leaves[student.student.id][date] == null || leaves[student.student.id][date][class_timing_id] == null) {
                if (saved_dates[class_timing_id] != null && saved_dates[class_timing_id].include(date)) {
                    if (date >= adm_date)
                        cellEl.update('P');
                }
            }
            else {
                if (enable == "1")
                    cellEl.update(code[student.student.id][date][class_timing_id]);
                else
                    cellEl.update('X');
            }
        }
    });
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
    var class_timing_id;
    if ($$('.active')[0] != null) {
        class_timing_id = $$('.active')[0].getAttribute('class_timing_id');
        absent.update(formattedDate(date));
        absent.append(' ');
        var day = Date.parse(date).getDay();
        absent.append(days[day]);
        absent.appendChild(absentStudents(date, class_timing_id));
        if (enable == "1")
            absent.appendChild(lateStudents(date, class_timing_id));
    }
    return absent;
}

function absentStudents(date, class_timing_id) {
    var absent;
    var absent_list = absentCount.cloneNode(true);
    if (absent_count[date] != null && absent_count[date][class_timing_id] != null)
        absent = absent_count[date][class_timing_id]
    else
        absent = 0
    absent_list.append(absent);
    absent_list.append(' Absent ');
    return absent_list;
}

function lateStudents(date, class_timing_id) {
    var late;
    var late_list = lateCount.cloneNode(true);
    if (late_count[date] != null && late_count[date][class_timing_id] != null)
        late = late_count[date][class_timing_id]
    else
        late = 0
    late_list.append(late);
    late_list.append(' Late ');
    return  late_list;
}

function updateAbsentees(date) {
    var class_timing_id = $$('.active')[0].getAttribute('class_timing_id');
    var absent = $('absent-count');
    absent.update(' ');
    absent.update(formattedDate(date));
    absent.append(' ');
    var day = Date.parse(date).getDay();
    absent.append(days[day]);
    absent.appendChild(absentStudents(date, class_timing_id));
    if (enable == "1")
        absent.appendChild(lateStudents(date, class_timing_id));
}

function dateCheck() {
    var date_check = false;
    for (var i = 0; i < datearr.length; i++) {
        if (dates[datearr[i]] != null) {
            dates[datearr[i]].each(function (e) {
                date_check = true;
            });
        }
    }
    return date_check;
}
function toggleMode() {
    if ($('quick-attendance-check').checked == false) {
        $('quick-attendance-check').checked = true;
    } else {
        $('quick-attendance-check').checked = false;
    }
}
function delaytoggleMode() {
    if ($('delay-quick-attendance-check').checked == false) {
        $('delay-quick-attendance-check').checked = true;
    } else {
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
function drawCheckbox() {
    var newdiv = new Element('div', {
        'class': 'quick-attendance-div',
        'id': 'quick_attendance'
    }).addClassName('quick-attendance-div');
    var helperdiv = new Element('div', {
        'id': 'helper_tooltip',
        'style': 'display:none'
    }).addClassName('helper_info');
    helperdiv.update(translated['subjectwise_quick_attendance_explanation']);
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
function drawDelayCheckbox() {
    var newdiv1 = new Element('div', {
        'class': 'delay-quick-attendance-div',
        'id': 'delay_quick_attendance'
    }).addClassName('delay-quick-attendance-div');
    var helperdiv1 = new Element('div', {
        'id': 'delay_helper_tooltip',
        'style': 'display:none'
    }).addClassName('delay_helper_info');
    helperdiv1.update(translated['delayed_notification_explanation']);
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
    newdiv1.appendChild(helperdiv1);
    return newdiv1;
}
function drawFlashBox() {
    var box = new Element('div', {
        'class': 'flash_msg'
    });
    box.textContent = translated['no_timetable_entries'];
    return box;
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
    });
    var month = new Element('div', {
        'class': 'month'
    }).update(translated[Date.parse(today).toString("MMMM")] + " " + Date.parse(today).toString("yyyy"));
    month.append(calendarDiv);
    var extender = new Element('div', {
        'class': 'extender'
    });
    header.appendChild(month);
    header.appendChild(extender);
    return header;
}
function drawBox() {
    var box = new Element('div', {
        'class': 'box-1',
        'id': 'register-box'
    });
    var tbl = new Element('table', {
        'id': 'register-table'
    });
    var tblbody = new Element('tbody');
    var headrow = new Element('tr', {
        'class': 'tr-head'
    });
    var nameTd = new Element('td', {
        'class': 'head-td-name'
    }).update(translated['student']);
    var dtd, dtdiv1, dtdiv2, ndate, tdate, dtdiv2n;
    tdate = Date.parse(date_today);
    headrow.update(nameTd);
    for (var i = 0; i < datearr.length; i++) {
        if (dates[datearr[i]] != null) {
            dates[datearr[i]].each(function (e) {
                ndate = Date.parse(datearr[i]);
                dtd = dateTd.cloneNode(true);
                dtd.id = 'date-' + datearr[i] + '-timing-' + e.timetable_entry.class_timing_id;
                dtdiv2 = dtDiv2.cloneNode(true);
                dtd.setAttribute('class_timing_id', e.timetable_entry.class_timing_id);
                dtd.setAttribute('date', datearr[i]);
                dtd.setAttribute('tt_entry', e.timetable_entry.id);
                if (attendance_lock && (datearr[i] <= date_today) && (at_lock_dates[e.timetable_entry.class_timing_id] == null || (at_lock_dates[e.timetable_entry.class_timing_id] != null && !at_lock_dates[e.timetable_entry.class_timing_id].include(datearr[i])))) {
                    dtdiv1 = dtDiv1n.cloneNode(true);
                    dtdiv2n = dtDiv2n.cloneNode(true);
                    dtdiv2.appendChild(dtdiv2n);
                }
                else {
                    dtdiv1 = dtDiv1.cloneNode(true);
                }
                dtdiv1.update(translated[ndate.toString("ddd")]);
                if (attendance_lock && datearr[i] <= date_today && (at_lock_dates[e.timetable_entry.class_timing_id] == null || at_lock_dates[e.timetable_entry.class_timing_id] != null && !at_lock_dates[e.timetable_entry.class_timing_id].include(datearr[i]))) {
                    dtdiv2n.update(ndate.toString("dd"));
                }
                else {
                    dtdiv2.update(ndate.toString("dd"));
                }
                if (tdate.equals(ndate))
                    dtd.addClassName('active');
                dtd.update(dtdiv1);
                dtd.appendChild(dtdiv2);
                if (attendance_lock && at_lock_dates[e.timetable_entry.class_timing_id] != null && at_lock_dates[e.timetable_entry.class_timing_id].include(datearr[i])) {
                    dtd.addClassName('lock-row');
                    dtd.addClassName('col-c');
                }
                headrow.appendChild(dtd);
            });
        }
    }
    tblbody.update(headrow);
    tbl.update(tblbody);
    box.update(tbl)
    return box;
}
function makeRow(student) {
    var rowEl = rowElem.cloneNode(true);
    if (student == 'lock') {
        var nameTd = nameTdElem.cloneNode(true);
        rowEl.addClassName('lock-row')
        rowEl.update(nameTd.update('Status'));
        for (var i = 0; i < datearr.length; i++) {
            if (dates[datearr[i]] != null) {
                dates[datearr[i]].each(function (e) {
                    rowEl.appendChild(makeLockCell(student, datearr[i], e));
                });
            }
        }
    }
    else {
        var nameTd = nameTdElem.cloneNode(true);
        rowEl.update(nameTd.update(student.name));
        if (attendance_lock) {
            for (var i = 0; i < datearr.length; i++) {
                if (dates[datearr[i]] != null) {
                    dates[datearr[i]].each(function (e) {
                        rowEl.appendChild(makeCellLock(student, datearr[i], e));
                    });
                }
            }
        }
        else {
            for (var i = 0; i < datearr.length; i++) {
                if (dates[datearr[i]] != null) {
                    dates[datearr[i]].each(function (e) {
                        rowEl.appendChild(makeCell(student, datearr[i], e));
                    });
                }
            }
        }
    }
    return rowEl;
}
var cn = 0;
function makeCell(student, dt, el) {
    var cellEl = cellElem.cloneNode(true);
    cellEl.id = 'student-' + student.id + '-date-' + d(dt) + '-timing-' + el.timetable_entry.class_timing_id
    var ndate, tdate, adm_date;
    adm_date = student.admission_date;
    tdate = Date.parse(date_today);
    ndate = Date.parse(dt);
    if (tdate.equals(ndate))
        cellEl.addClassName('active');
    if (leaves[student.id][dt] == null || leaves[student.id][dt][el.timetable_entry.class_timing_id] == null) {
        if (ndate <= tdate) {
            var present = presentElem.cloneNode(true);
            present.setAttribute('date', dt);
            present.setAttribute('subject_id', dt);
            present.setAttribute('tt_entry', el.timetable_entry.id);
            present.id = student.id;
            present.setAttribute('admsn_date', adm_date);
            present.update("O");
        }
        cellEl.update(present);
    } else {
        if (ndate <= tdate) {
            if (enable == "1") {
                if (types[student.id][dt] == "Absent") {
                    var absent = absentElem.cloneNode(true);
                    absent.id = leaves[student.id][dt][el.timetable_entry.class_timing_id];
                    absent.update(code[student.id][dt][el.timetable_entry.class_timing_id]);
                    cellEl.update(absent);
                } else {
                    var late = lateElem.cloneNode(true);
                    late.id = leaves[student.id][dt][el.timetable_entry.class_timing_id];
                    late.update(code[student.id][dt][el.timetable_entry.class_timing_id]);
                    cellEl.update(late);
                }
            } else {
                var absent = absentElem.cloneNode(true);
                absent.id = leaves[student.id][dt][el.timetable_entry.class_timing_id];
                absent.update("X");
                cellEl.update(absent);
            }
        }

    }
    return(cellEl);
}

function makeLockCell(student, dt, el) {
    var cellEl = cellElem.cloneNode(true);
    var class_timing_id = el.timetable_entry.class_timing_id;
    cellEl.id = '-date-' + d(dt) + '-timing-' + class_timing_id;
    if (dt <= date_today) {
        if ((at_lock_dates[class_timing_id] != null && at_lock_dates[class_timing_id].include(dt))) {
            if (privilege == true) {
                var lockCell = lockElem.cloneNode(true);
                lockCell.id = 'date-' + d(dt) + '-timing-' + class_timing_id;
                lockCell.setAttribute('date', dt);
                lockCell.setAttribute('class_timing_id', class_timing_id);
                lockCell.setAttribute('tt_entry', el.timetable_entry.id);
                cellEl.appendChild(lockCell);
            }
            else {
                j('<div>', {
                    "class": "lock-cell",
                    "id": "lock-cell-" + dt + '-timing-' + class_timing_id,
                    "date": dt
                }).appendTo(cellEl);
            }
        }
        if ((saved_dates[class_timing_id] != null && saved_dates[class_timing_id].include(dt)) && !(at_lock_dates[class_timing_id] != null && at_lock_dates[class_timing_id].include(dt))) {

            j('<div>', {
                "class": "unlock-cell",
                "date": dt,
                "id": "lock-cell-" + dt + '-timing-' + class_timing_id,
            }).appendTo(cellEl);
        }
        if (attendance_status[dt].include(class_timing_id) && !(saved_dates[class_timing_id] != null && saved_dates[class_timing_id].include(dt)) && !(at_lock_dates[class_timing_id] != null && at_lock_dates[class_timing_id].include(dt))) {
            j('<div>', {
                "class": "marked-cell",
                "date": dt,
                "id": "marked-cell-" + dt + '-timing-' + class_timing_id,
            }).appendTo(cellEl);
        }
    }
    return(cellEl);
}

function makeCellLock(student, dt, el) {
    var cellEl = cellElem.cloneNode(true);
    cellEl.id = 'student-' + student.id + '-date-' + d(dt) + '-timing-' + el.timetable_entry.class_timing_id;
    var ndate, tdate, adm_date;
    adm_date = student.admission_date;
    tdate = Date.parse(date_today);
    ndate = Date.parse(dt);
    cellEl.addClassName('themed_text');
    if (tdate.equals(ndate) && (at_lock_dates[el.timetable_entry.class_timing_id] == null || (at_lock_dates[el.timetable_entry.class_timing_id] != null && !at_lock_dates[el.timetable_entry.class_timing_id].include(dt)))) {
        cellEl.addClassName('active');
        if (leaves[student.id][dt] == null || leaves[student.id][dt][el.timetable_entry.class_timing_id] == null) {
            if (ndate <= tdate) {
                var present = presentElem.cloneNode(true);
                present.setAttribute('date', dt);
                present.setAttribute('subject_id', dt);
                present.setAttribute('tt_entry', el.timetable_entry.id);
                present.id = student.id;
                present.setAttribute('admsn_date', adm_date);
                present.update("O");
            }
            cellEl.update(present);
        }
        else {
            if (ndate <= tdate) {
                if (enable == "1") {
                    if (types[student.id][dt] == "Absent") {
                        var absent = absentElem.cloneNode(true);
                        absent.id = leaves[student.id][dt][el.timetable_entry.class_timing_id];
                        absent.update(code[student.id][dt][el.timetable_entry.class_timing_id]);
                        cellEl.update(absent);
                    } else {
                        var late = lateElem.cloneNode(true);
                        late.id = leaves[student.id][dt][el.timetable_entry.class_timing_id];
                        late.update(code[student.id][dt][el.timetable_entry.class_timing_id]);
                        cellEl.update(late);
                    }
                } else {
                    var absent = absentElem.cloneNode(true);
                    absent.id = leaves[student.id][dt][el.timetable_entry.class_timing_id];
                    absent.update("X");
                    cellEl.update(absent);
                }
            }

        }

    }
    else {
        if (leaves[student.id][dt] == null || leaves[student.id][dt][el.timetable_entry.class_timing_id] == null) {
            if (ndate <= tdate && saved_dates[el.timetable_entry.class_timing_id] != null && saved_dates[el.timetable_entry.class_timing_id].include(dt)) {
                if (dt >= adm_date)
                    cellEl.update('P');
            }
        }
        else {
            if (ndate <= tdate) {
                if (enable == "1")
                    cellEl.update(code[student.id][dt][el.timetable_entry.class_timing_id]);
                else
                    cellEl.update('X');
            }
        }

    }
    if (at_lock_dates[el.timetable_entry.class_timing_id] != null && at_lock_dates[el.timetable_entry.class_timing_id].include(dt)) {
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
function cellHover() {
    var cIndex = this.cellIndex;
    var rIndex = this.up().rowIndex;
    var tbl = this.up(1);
    var dt = getDate(rIndex, cIndex, tbl);
    var name = getName(rIndex, cIndex, tbl);
    var descEl = makeHoverEl(dt, name);
    if (this.down('.date') == null)
        this.appendChild(descEl);
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
        'class': 'date'
    });
    var spanel = new Element('span', {
        'class': 'themed_text'
    });
    var secdiv = new Element('div');
    secdiv.update(name);
    spanel.update(dt.day + " " + dt.date);
    spanel.appendChild(secdiv);
    maindiv.update(spanel);
    return(maindiv);
}

function rebind() {
    $$('.absent').invoke('observe', 'click', edit);
    $$('.present').invoke('observe', 'click', add);
    $$('.late').invoke('observe', 'click', edit);
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
                    parameters: 'batch_id=' + $("batch_id").value + '&date=' + $$('.active')[0].getAttribute('date') + '&subject_id=' + subject_id + '&class_timing_id=' + $$('.active')[0].getAttribute('class_timing_id'),
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

function  update_response_values(date) {
    var subject_id = $("subject_id").value;
    var active_cell = $$('.active');
    if (subject_id && (active_cell.length > 0)) {
        var class_timing_id = $$('.active')[0].getAttribute('class_timing_id');
        new Ajax.Request('/attendances/subject_wise_register.json', {
            parameters: 'batch_id=' + $('batch_id').value + '&subject_id=' + subject_id + '&next=' + Date.parse(today),
            asynchronous: true,
            evalScripts: true,
            method: 'get',
            onComplete: function (resp) {
                $('error_messages').innerHTML = "";
                update_json_values(resp.responseJSON);
                update_status(date, class_timing_id);
                updateAbsentees(date);
            }
        });
    }
}

function update_status(date, class_timing_id) {
    var cell = $('marked-cell-' + date + '-timing-' + class_timing_id);
    if (cell == null) {
        var cell = $('-date-' + d(date) + '-timing-' + class_timing_id);
    }
    cell.update(' ');
                j('<div>', {
                    "class": "unlock-cell",
                    "date": date,
                    "id": "marked-cell-" + date + '-timing-' + class_timing_id
                }).appendTo(cell);
    
    cell.removeClassName('marked-cell');
   // cell.addClassName('unlock-cell');
    cell.id = 'lock-cell-' + date + '-timing-' + class_timing_id;
}

function lockAttendance() {
    var subject_id = $("subject_id").value;
    var active_cell = $$('.active');
    if (subject_id && (active_cell.length > 0)) {
        var date = $$('.active')[0].getAttribute('date');
        var class_timing_id = $$('.active')[0].getAttribute('class_timing_id');
        var tt_entry = $$('.active')[0].getAttribute('tt_entry');
        new Ajax.Request('/attendances/subject_wise_register.json', {
            parameters: 'batch_id=' + $('batch_id').value + '&subject_id=' + subject_id + '&next=' + Date.parse(today),
            asynchronous: true,
            evalScripts: true,
            method: 'get',
            onComplete: function (resp) {
                $('error_messages').innerHTML = "";
                update_json_values(resp.responseJSON);
                lockCells(date, class_timing_id, tt_entry);
                updateAbsentees(date);
                rebind();
            }
        });
    }
    else {
        alert(translated['select_for_lock']);
    }
}

function lockCells(date, class_timing_id, tt_entry) {
    new Ajax.Request('/attendances/lock_attendance',
            {
                parameters: 'batch_id=' + $("batch_id").value + '&date=' + date + '&subject_id=' + $("subject_id").value + '&class_timing_id=' + class_timing_id,
                asynchronous: true,
                evalScripts: true,
                method: 'get'
            }
    );
    lockColumn(date, class_timing_id, tt_entry);
}

function unlockAttendance() {
    if (privilege) {
        var date = this.getAttribute('date');
        var class_timing_id = this.getAttribute('class_timing_id');
        var tt_entry = this.getAttribute('tt_entry');
        new Ajax.Request('/attendances/unlock_attendance',
                {
                    parameters: 'batch_id=' + $("batch_id").value + '&date=' + date + '&subject_id=' + subject_id + '&class_timing_id=' + class_timing_id,
                    asynchronous: true,
                    evalScripts: true,
                    method: 'get'
                }
        );
        unlockedColumn(date, class_timing_id, tt_entry);
    }
}

function lockColumn(date, class_timing_id, tt_entry) {
    var lockedCell = $('lock-cell-' + date + '-timing-' + class_timing_id);
    if (lockedCell == null) {
        var lockedCell = $('marked-cell-' + date + '-timing-' + class_timing_id);
        if (lockedCell != null)
            lockedCell.removeClassName('marked-cell');
        if (lockedCell == null)
            var lockedCell = $('-date-' + d(date) + '-timing-' + class_timing_id);
    }
    lockedCell.update(' ');
    var ndate = Date.parse(date);
    var head = $('date-' + date + '-timing-' + class_timing_id);
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
    if (privilege == true) {
        var lockCell = lockElem.cloneNode(true);
        lockCell.id = 'date-' + d(date) + '-timing-' + class_timing_id;
        lockCell.setAttribute('date', date);
        lockCell.setAttribute('class_timing_id', class_timing_id);
        lockCell.setAttribute('tt_entry', tt_entry);
        lockedCell.appendChild(lockCell);
    }
    else {
        j('<div>', {
            "class": "lock-cell",
            "id": "lock-cell-" + date + '-timing-' + class_timing_id,
            "date": date
        }).appendTo(lockedCell);
    }
    students.each(function (student) {
        var adm_date = student.student.admission_date;
        cellEl = $('student-' + student.student.id + '-date-' + d(date) + '-timing-' + class_timing_id);
        if (cellEl != null) {
            cellEl.removeClassName('themed_text');
            cellEl.addClassName('locked');
            if (leaves[student.student.id][date] == null || leaves[student.student.id][date][class_timing_id] == null) {
                if (date >= adm_date)
                    cellEl.update('P');
            }
            else {
                if (enable == "1")
                    cellEl.update(code[student.student.id][date][class_timing_id]);
                else
                    cellEl.update('X');
            }
        }
    });
    rebind();
}

function unlockedColumn(date, class_timing_id, tt_entry) {
    var headrow = $('date-' + date + '-timing-' + class_timing_id);
    var activeCell = headrow.getAttribute('class').include('active');
    headrow.update(' ');
    var dt = Date.parse(date);
    var dtdiv2, dtdiv1, dtdiv2n;
    dtdiv2 = dtDiv2.cloneNode(true);
    dtdiv1 = dtDiv1n.cloneNode(true);
    dtdiv2n = dtDiv2n.cloneNode(true);
    dtdiv2.appendChild(dtdiv2n);
    headrow.setAttribute('date', date);
    headrow.setAttribute('class_timing_id', class_timing_id);
    headrow.setAttribute('tt_entry', tt_entry);
    dtdiv1.update(translated[dt.toString("ddd")]);
    dtdiv2n.update(dt.toString("dd"));
    headrow.update(dtdiv1);
    headrow.appendChild(dtdiv2);
    headrow.removeClassName('lock-row');
    headrow.removeClassName('col-c');
    headrow.addClassName('unlock-row');
    var unlockCell = $('date-' + d(date) + '-timing-' + class_timing_id);
    unlockCell.removeClassName('lock-cell');
    unlockCell.update(' ');
    j('<div>', {
        "class": "unlock-cell",
        "date": date,
        "id": "lock-cell-" + date + '-timing-' + class_timing_id
    }).appendTo(unlockCell);
    students.each(function (student) {
        cellEl = $('student-' + student.student.id + '-date-' + d(date) + '-timing-' + class_timing_id);
        cellEl.removeClassName('locked');
        cellEl.addClassName('themed_text');
        var adm_date = student.student.admission_date;
        if (cellEl != null) {
            if (activeCell) {
                if (leaves[student.student.id][date] == null || leaves[student.student.id][date][class_timing_id] == null) {
                    var present = presentElem.cloneNode(true);
                    present.setAttribute('date', dt);
                    present.setAttribute('student', dt);
                    present.setAttribute('tt_entry', tt_entry);
                    present.id = student.student.id;
                    present.setAttribute('admsn_date', adm_date);
                    present.update("O");
                    cellEl.update(present);
                }
                else {
                    if (enable == "1") {
                        if (types[student.student.id][date] == "Absent") {
                            var absent = absentElem.cloneNode(true);
                            absent.id = leaves[student.student.id][date][class_timing_id];
                            absent.update(code[student.student.id][date][class_timing_id]);
                            cellEl.update(absent);
                        }
                        else {
                            var late = lateElem.cloneNode(true);
                            late.id = leaves[student.student.id][date][class_timing_id];
                            late.update(code[student.student.id][date][class_timing_id]);
                            cellEl.update(late);
                        }
                    }
                    else {
                        var absent = absentElem.cloneNode(true);
                        absent.id = leaves[student.student.id][date][class_timing_id];
                        absent.update("X");
                        cellEl.update(absent);
                    }
                }
            }
            else {
                if (leaves[student.student.id][date] == null || leaves[student.student.id][date][class_timing_id] == null) {
                    if (date >= adm_date)
                        cellEl.update('P');
                }
                else {
                    if (enable == "1")
                        cellEl.update(code[student.student.id][date][class_timing_id]);
                    else
                        cellEl.update('X');
                }


            }
        }
    });
    rebind();
}

function update_leave_json() {
    if (attendance_lock) {
        var subject_id = $("subject_id").value
        var date = this.getAttribute('date');
        var lock = this.getAttribute('class').include('col-c');
        var tt_entry = this.getAttribute('tt_entry');
        var class_timing = this.getAttribute('class_timing_id');
        if (subject_id && date <= date_today) {
            new Ajax.Request('/attendances/subject_wise_register.json', {
                parameters: 'batch_id=' + $('batch_id').value + '&subject_id=' + subject_id + '&next=' + Date.parse(today),
                asynchronous: true,
                evalScripts: true,
                method: 'get',
                onComplete: function (resp) {
                    $('error_messages').innerHTML = "";
                    update_json_values(resp.responseJSON);
                    dateSelect(date, lock, class_timing, tt_entry)
                    rebind();
                }
            });
        }
    }
}

function dateSelect(date, lock, class_timing, tt_entry) {
    if (!lock && date != null) {
        var active_cell = $$('.active');
        if (active_cell.length != 0) {
            var padate = active_cell[0].getAttribute('date');
            var class_timing_id = active_cell[0].getAttribute('class_timing_id');
            active_cell[0].removeClassName('active');
            students.each(function (student) {
                var adm_date = student.student.admission_date;
                cellEl = $('student-' + student.student.id + '-date-' + d(padate) + '-timing-' + class_timing_id);
                cellEl.update('');
                if (cellEl != null) {
                    cellEl.removeClassName('active');
                    cellEl.addClassName('themed_text');
                    if (leaves[student.student.id][padate] == null || leaves[student.student.id][padate][class_timing_id] == null) {
                        if (saved_dates[class_timing_id] != null && saved_dates[class_timing_id].include(padate)) {
                            if (padate >= adm_date)
                                cellEl.update('P');
                        }
                    }
                    else {
                        if (enable == "1")
                            cellEl.update(code[student.student.id][padate][class_timing_id]);
                        else
                            cellEl.update('X');
                    }
                }
            });
            if (attendance_status[padate].include(class_timing_id) && !(saved_dates[class_timing_id] != null && saved_dates[class_timing_id].include(padate)) && !(at_lock_dates[class_timing_id] != null && at_lock_dates[class_timing_id].include(padate))) {
                var unmarked = $('-date-' + d(padate) + '-timing-' + class_timing_id);
                unmarked.update(' ');
                j('<div>', {
                    "class": "marked-cell",
                    "date": padate,
                    "id": "marked-cell-" + padate + '-timing-' + class_timing_id
                }).appendTo(unmarked);

            }
        }
        if (!lock) {
            $('date-' + date + '-timing-' + class_timing).addClassName('active');
            selectColumn(date, class_timing, tt_entry);
            updateAbsentees(date);
        }
    }

}

function selectColumn(dt, class_timing, tt_entry) {
    students.each(function (student) {
        cellEl = $('student-' + student.student.id + '-date-' + d(dt) + '-timing-' + class_timing);
        var adm_date;
        adm_date = student.student.admission_date;
        cellEl.addClassName('active');
        cellEl.addClassName('themed_text');
        if (leaves[student.student.id][dt] == null || leaves[student.student.id][dt][class_timing] == null) {
            var present = presentElem.cloneNode(true);
            present.setAttribute('date', dt);
            present.setAttribute('admsn_date', adm_date);
            present.setAttribute('subject_id', dt);
            present.setAttribute('tt_entry', tt_entry);
            present.id = student.student.id;
            present.update("O");
            cellEl.update(present);
        }
        else {
            if (enable == "1") {
                if (types[student.student.id][dt] == "Absent") {
                    var absent = absentElem.cloneNode(true);
                    absent.id = leaves[student.student.id][dt][class_timing];
                    absent.update(code[student.student.id][dt][class_timing]);
                    cellEl.update(absent);
                }
                else {
                    var late = lateElem.cloneNode(true);
                    late.id = leaves[student.student.id][dt][class_timing];
                    late.update(code[student.student.id][dt][class_timing]);
                    cellEl.update(late);
                }
            }
            else {
                var absent = absentElem.cloneNode(true);
                absent.id = leaves[student.student.id][dt][class_timing];
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
                    parameters: 'id=' + this.id + '&date=' + this.getAttribute('date') + '&timetable_entry=' + this.getAttribute('tt_entry') + '&subject_id=' + subject_id + '&delay_notif=' + $('delay-quick-attendance-check').checked,
                    asynchronous: true,
                    evalScripts: true,
                    method: 'get'
                }
        );
    } else {
        if (this.getAttribute('admsn_date') <= this.getAttribute('date') || (attendance_configuration === true))
        {
            new Ajax.Request('/attendances/quick_attendance',
                    {
                        parameters: 'id=' + this.id + '&date=' + this.getAttribute('date') + '&timetable_entry=' + this.getAttribute('tt_entry') + '&subject_id=' + subject_id + '&delay_notif=' + $('delay-quick-attendance-check').checked,
                        asynchronous: true,
                        evalScripts: true,
                        method: 'get'
                    }
            );
        } else
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
    update_json($("subject_id").value);
}
function get_sort_order() {
    value = $$('input:checked[type=radio][name=sort_order_selector]')[0].value;
    return parseInt(value);
}
function sort_students_array(order) {
// 0 -> by_first_name
// 1 -> by roll_number
    if (order == 0) {
// alert("sorting by name");
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
keys = function (obj) {
    var arr = [];
    for (var dt in obj) {
        arr.push(dt);
    }
    return(arr);
}
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
        new Ajax.Request('/attendances/subject_wise_register.json', {
            parameters: 'batch_id=' + val + '&next=' + Date.parse(date) + '&subject_id=' + $('subject_id').value,
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
