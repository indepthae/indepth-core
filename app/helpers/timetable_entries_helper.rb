#Fedena
#Copyright 2011 Foradian Technologies Private Limited
#
#This product includes software developed at
#Project Fedena - http://www.projectfedena.org/
#
#Licensed under the Apache License, Version 2.0 (the "License");
#you may not use this file except in compliance with the License.
#You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#Unless required by applicable law or agreed to in writing, software
#distributed under the License is distributed on an "AS IS" BASIS,
#WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#See the License for the specific language governing permissions and
#limitations under the License.

module TimetableEntriesHelper
  def shorten_string(string, count,dots=true)
    if string.present? and string.length > count
      shortened = string[0, count]
      splitted = shortened.split(/\s/)
      words = shortened.length
      if dots
        splitted[0, words-1].join(" ") + ' ...'
      else
        splitted[0, words-1].join(" ")
      end
    else
      string
    end
  end

  def num_digits num
    return Math.log10(num).to_i + 1
  end

  def timetable_entry_employee_names(employees, limit=15)
    name_string = []
    employee_names = employees.map(&:first_name)
    employee_names_len = employee_names.length
    employee_names.each_with_index do |emp_name,i|
      suffix_length = (employee_names_len - i + 1) > 0 ? (num_digits(employee_names_len - i + 1) + 4) : 0
      limit -= name_string.join(', ').length
      break if i > 0 and (limit <= 0 or ((emp_name.length + suffix_length) > limit))
      name_string << "#{emp_name}" unless i == 0
      name_string << "#{(emp_name.length + suffix_length) > limit ? shorten_string(emp_name,limit - suffix_length) : emp_name}" if i == 0
    end
    name_string_len = name_string.length
    teacher_name = name_string_len < employee_names_len ? "#{name_string.join(', ')} + #{employee_names_len - name_string_len}" : "#{name_string.join(', ')}"
    is_more = name_string_len < employee_names_len ? true : false
    return teacher_name, is_more
  end

end
