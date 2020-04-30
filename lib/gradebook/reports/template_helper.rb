module Gradebook
  module Reports
    module TemplateHelper

      def report
        @report
      end

      def settings
        @settings
      end
      
      def report_template
        @report_template
      end
      
      def report_model_obj
        @report_model_obj
      end
      
      def planner_report?
        report.type == 'AssessmentPlan'
      end
      
      def term_report?
        report.type == 'AssessmentTerm'
      end
      
      def group_report?
        report.type == 'AssessmentGroup'
      end
      
      def render_partial(partial)
        render :file=> "#{report_template.template_view_folder_path}/_#{partial}.erb"
      end

      def secondary_logo_url (logo_value)
        case logo_value
          when 'student_photo'
            student_photo_url || ""
          when 'none', nil
            ''
          else
            load_asset_path(logo_value)
        end
      end
      
      def report_header(values,options={})
          font_family = options[:font_family] if options.present?
          html="<div class='header'>
            <div class='two columns left_text'>
              <div class='logo' style=\"background-image:url(\'#{values[:logo1_url].to_s}\')\"></div>
            </div>
            <div class='eight columns center_text'>"
          html += (font_family.present?) ? "<div class='school_name' style='font-family: #{font_family};'>" :"<div class='school_name'>"
          html += "#{values[:school_name].to_s}
              </div>
              <div class='school_address'>
                #{values[:school_address].to_s}
                #{values[:school_email_with_website]}
              </div>
            </div>
            <div class='two columns right_text'>
              <div class='logo' style=\"background-image:url(\'#{values[:logo2_url].to_s}\')\"></div>
            </div>
          </div>"
          
          return html
      end
      
      
      def box(values)
        html = "<div class='box'>
              <div class='box_head'>
                #{values[:box_head].to_s}
              </div>
              <div class='box_content'>
                #{values[:box_content].to_s}
              </div>
            </div>"
        return html
      end
      
      
      def cover_page_student_details(values)
        #values => {:student_details_text=>"", :profile_photo_url=>"", :student_details_pair=>[{:field_name=>"", :field_value=>""}]}
        html1 = "    <div class='student_details'>
          <div class='student_details_head'>
            #{values[:student_details_text]}
          </div>
          <div class='line'></div>
          <div class='section'>
            <div class='nine columns'>
              <table class='frameless'>
        "
              
        html2 = ""
        values[:student_details_pair].to_a.each {|v| html2 = html2 + "<tr> <td>#{v[:field_name]} </td> <td>#{v[:field_value]}</td> </tr>" }
              
        html3 = " 
              </table>
            </div>
            <div class='three columns center_text'>
              <div class='profile_photo' style=\"background-image:url('#{values[:profile_photo_url].to_s}')\">
              </div>
            </div>
          </div>
          <div class='section'>
            <div class='line'></div>
          </div>
        </div>"
        
        return html1 + html2 + html3
      end
      
      
      
      
      def cover_page_head(values, scaled_down = false)
        #values =>{:school_name=>"", :school_address=>"", :school_logo_url=>""}
        html = "<div class='cover_page_head #{scaled_down == true ? "scaled_down" : ""}'>
            <div class='round_logo cover_head_logo' style=\"background-image:url('#{values[:school_logo_url].to_s}')\">
            </div>
            <div class='cover_head_school'>
              #{values[:school_name].to_s}
            </div>
            <div class='cover_head_school_address'>
              #{values[:school_address].to_s}
            </div>
          </div>"
        return html  
      end

      def student_photo_url
        @student_photo_url ||= (
          if report_model_obj.student.photo.present?
            if report_model_obj.student.photo.options[:url] =~ /jwt_signed_url|s3_alias_url/
              report_model_obj.student.photo.url(:original, false)
            else
              "file://#{Rails.root.join report_model_obj.student.photo.path(:original)}"
            end
          else
            false
          end
        )
      end

      def param_set(values, show_photo=false)
        #values = [['head name','value'],["",""]]
        if show_photo
          html = "<div class='ten columns justified-list'>"
        else
          html = "<div class='justified-list'>"
        end
        values.to_a.each_with_index do |v, index|
          html = html +  "
          <div class='param_set'>
          <div class='param_head'>
          #{v[0]}
          </div>
          <div class='param_value #{"bold" if index==0}'>
          #{v[1]}
          </div>
          </div>
          "
        end
        html = html + "</div>"

        if show_photo
          html = html + <<-HTML
            <div class='two columns center-aligned'>
              #{image_tag(student_photo_url, :class=> 'student_photo', :height => '80px') if student_photo_url}
            </div>
            HTML
        end

        return html
      end

      def box_lite(values)
        #values = {:head=>"", :content=>"" }
        html = "<div class='box_lite'>
          <div class='box_content'>
            <span class='theme_text bold'> #{values[:head]} : </span> 
            #{values[:content]}
          </div>
        </div>"
      end
      
      
      #component based helpers --------------------------------------.
      
      def gradebook_records(report)
        html = ""
        report_hash = report.student.records.group_by(&:record_group)
        report_hash.each_pair do |key,value|
          html += "<table class='primary condensed'>"
          record_hash = value.group_by(&:parent) if value.present?
          html += "<tr class='shaded_bg'><th colspan=#{record_hash.keys.count}> #{key} </th></tr>"
          if (report.type == "AssessmentPlan" and settings[:frequency]!="2") or (report.type == "AssessmentTerm" and settings[:frequency]=="0")
            html += "<tr>"
            record_hash.keys.each{|key| html += "<th>#{key}</th>"}
            html += "</tr>"
          end
          table_set = record_preprocess(record_hash)
          table_set.each do |row_set|
            html += "<tr>"
            row_set.each do |row|
              row_key = (row.present? and row.key.present?) ? row.key+": " : "" 
              row_val = (row.present? and row.value.present?) ? " #{row.value} #{row.suffix}" : "" 
              row_val = "-" if row.present? and row.key.present? and (row.value.nil? or row.value == "")
              html += "<td class='left_text'> #{row_key} #{row_val} </td>"
            end
            html += "</tr>"
          end
          html += "</table>"
        end
        html
      end
      
      def record_preprocess(record_hash)
        term_names = record_hash.keys
        max_rows = record_hash.values.max_by(&:count).count
        table_set = []
        max_rows.times do |i|
          row_set = []
          term_names.each do |key|
            row_set << record_hash[key][i]
          end
          table_set << row_set
        end
        table_set
      end
      
      def report_remarks(remarks)
        html = "" 
        groupable_remarks = remarks.select{|r| r.is_inherited == true}
        non_groupable_remarks = remarks.select{|r| r.is_inherited == false}
        grouped_remarks = groupable_remarks.group_by{|r| r.type_id }
        #display groupable remarks 
        grouped_remarks.each do |key, remark_set|
          html = html + "<table class='primary condensed'> 
          <thead>
            <th> #{remark_set.first.name} </th>
          </thead>"
          remark_set.each do |remark|
            html = html + "<tr><td><span class='theme_text bold'> #{remark.parent_name} : </span>  #{remark.remark}</td></tr>"
          end  
          html = html + "</table>"
        end
        
        #display non groupable remarks
        non_groupable_remarks.each do |remark| 
          html = html + box_lite({:head=>remark.name, :content=> remark.remark })
        end
        
        return html
      end
      
      def load_asset_path(asset_file_name)
        File.join(report_template.template_folder_path,"assets",asset_file_name)
      end
      
      def default_cbse_logo
        if settings[:use_cbse_logo] == "1"
          Rails.root.join('public','images','cbse-logo.png')
        end
      end
      
      def default_school_logo(options={:type=>:original})
        if current_school_detail.logo.present?
          FedenaSetting.s3_enabled? ? current_school_detail.logo.url(options[:type],false) : File.join(RAILS_ROOT,current_school_detail.logo.path(options[:type]))
        else
          Rails.root.join('public','images','application','dummy_logo.png')
        end
      end
      
      def report_name(header_name = report.header_name)
        header_name = report.header_name if group_report?
        content_tag :div, header_name, :class => 'shaded_head_container'
      end
      
      def sub_headers(report, options={})
        round =  options[:round] if options[:round].present? 
        round_marks =  options[:round_marks] if options[:round_marks].present? 
        content = [content_tag(:td, I18n.t('multiple_subjects'))]
        report.term_names.each do |term_name|
          exam_sets = fetch_exam_sets(term_name, options)
          exam_sets.each do |exam_set|
            additional_final_column = exam_set.additional_final_column({:final_grade => options[:final_grade]})
            content << content_tag(:td, exam_set.name_with_max_mark(round,round_marks))
            if additional_final_column.present?
              content << content_tag(:td, additional_final_column)
            end
          end               
          content << content_tag(:td, I18n.t('remarks')) if report.subject_wise_remark_enabled? and subject_remarks_present(report,term_name)
        end
        final_sets = report.final_exam_sets(options)
        final_sets.each do |exam_set|
          additional_final_column = exam_set.additional_final_column
          content << content_tag(:td, exam_set.name_with_max_mark(round,round_marks))
          if additional_final_column.present?
            content << content_tag(:td, additional_final_column)
          end
        end
        content << content_tag(:td, I18n.t('remarks')) if report.subject_wise_remark_enabled? and !term_report? and subject_remarks_present(report)
        if options[:get_column_count].present?
          return content.count
        else
          content.flatten.join('')
        end
      end
      
      def maximum_and_pass_marks_custom_e 
        if planner_report?
          max_mark =  settings[:template_e_planner_maximum_marks].present?? settings[:template_e_planner_maximum_marks] : 100.0
          pass_mark = settings[:template_e_planner_pass_marks].present?? settings[:template_e_planner_pass_marks] : 40.0
        elsif term_report?
          max_mark =  settings[:template_e_term_maximum_marks].present?? settings[:template_e_term_maximum_marks] : 100.0
          pass_mark = settings[:template_e_term_pass_marks].present?? settings[:template_e_term_pass_marks] : 40.0
        else
          max_mark =  10.0
          pass_mark = 4.0
        end
        return max_mark,pass_mark
      end
      
      def maximum_and_pass_marks_custom_j 
        if planner_report?
          max_mark =  0.0
          pass_mark = 0.0
        elsif term_report?
          max_mark =  0.0
          pass_mark = 0.0
#        else
#          max_mark =  10.0
#          pass_mark = 0.0
        end
        return max_mark,pass_mark
      end
      
      def sub_headers_custom_e(report)
        max_and_pass_marks = maximum_and_pass_marks_custom_e
        max_mark = max_and_pass_marks[0].to_f
        pass_mark = max_and_pass_marks[1].to_f
        content = [content_tag(:td, I18n.t('multiple_subjects'))]
        if planner_report? or term_report? 
          content << content_tag(:td, I18n.t('max_mark_caps')+"<br>(#{max_mark})")
          content << content_tag(:td, I18n.t('pass_mark_caps')+"<br>(#{pass_mark})")
        end
        report.term_names.each do |term_name|
          report.exam_sets[term_name].each do |exam_set|
            additional_final_column = exam_set.additional_final_column
            content << content_tag(:td, exam_set.name_with_max_mark)
            if additional_final_column.present?
              content << content_tag(:td, additional_final_column)
            end
          end
          content << content_tag(:td, I18n.t('remarks')) if report.subject_wise_remark_enabled? and subject_remarks_present(report,term_name)
        end
        unless planner_report?
          final_sets = report.final_exam_sets
          final_sets.each do |exam_set|
            additional_final_column = exam_set.additional_final_column
            content << content_tag(:td, exam_set.name_with_max_mark)
            if additional_final_column.present?
              content << content_tag(:td, additional_final_column)
            end
          end
          content << content_tag(:td, I18n.t('remarks')) if report.subject_wise_remark_enabled? and !term_report? and subject_remarks_present(report)
        end
        content.flatten.join('')
      end
      
      def nested_subject_rows(values)
        round =  values[:round] if values[:round].present? 
        round_marks =  values[:round_marks] if values[:round_marks].present?
        final = ""
        values[:subjects].each do |subject|
          parent_subject_id =
            if subject.type == 'Subject'
              subject.obj_id
            elsif values[:parent_subject_id].present?
              values[:parent_subject_id]
            end
          sub_subjects = subject.children(report, parent_subject_id)

          next if subject.type == 'BatchSubjectGroup' && sub_subjects.empty?

          final += subject_row(
              values.merge(
                  {:subject => subject, :level => values[:level],:round=>round,
                   :combine_final_grade => values[:combine_final_grade],:round_marks=>round_marks}))

          if sub_subjects.present?
            final += nested_subject_rows(values.merge(
              {:subjects => sub_subjects,
                :report => values[:report],
                :level => values[:level] + 1, :parent_subject_id => parent_subject_id, :combine_final_grade => values[:combine_final_grade] }
            ))
          end
        end
        return final
      end
      
      def nested_subject_rows_custom_e(values)
        final = ""
        values[:subjects].each do |subject|
          final += subject_row_custom_e(values.merge({:subject => subject, :level => values[:level]}))
          parent_subject_id = if subject.type == 'Subject'
            subject.obj_id
          elsif values[:parent_subject_id].present?
            values[:parent_subject_id]
          end
          sub_subjects = subject.children(report, parent_subject_id)
          if sub_subjects.present?
            final += nested_subject_rows_custom_e(values.merge(
                {:subjects => sub_subjects,
                  :report => values[:report],
                  :level => values[:level] + 1, :parent_subject_id => parent_subject_id }
              ))
          end
        end
        return final
      end
      
      def nested_subject_rows_custom_j(values)
        round =  values[:round] if values[:round].present? 
        final = ""
        values[:subjects].each do |subject |
          final += subject_row_custom_j(values.merge({:subject => subject, :level => values[:level],:round=>round, :combine_final_grade => values[:combine_final_grade]}))
          parent_subject_id = if subject.type == 'Subject'
            subject.obj_id
          elsif values[:parent_subject_id].present?
            values[:parent_subject_id]
          end
          sub_subjects = subject.children(report, parent_subject_id)
          if sub_subjects.present?
            final += nested_subject_rows_custom_j(values.merge(
              {:subjects => sub_subjects,
                :report => values[:report],
                :level => values[:level] + 1, :parent_subject_id => parent_subject_id, :combine_final_grade => values[:combine_final_grade] }
            ))
          end
        end
        return final
      end
      
      def display_skills(values)
        final = ""
        col_span = 0
        exam_set_names = []
        if  group_report?
          exam_set_names = [report.name]
          col_span = 1
        else
          report.term_names.each do |term_name|
            exam_set_names +=  (report.exam_sets[term_name].select{|es| es.consider_skills == true }.collect(&:name))
            col_span += report.exam_sets[term_name].select{|es| es.consider_skills == true }.count
          end
        end
        values[:subjects].each do |subject|
          parent_subject_id = if subject.type == 'Subject'
              subject.obj_id
            elsif values[:parent_subject_id].present?
              values[:parent_subject_id]
            end
          if subject.type == "BatchSubjectGroup"
            final += "<tr><th class='level_0 bold' colspan='#{col_span+1}'>#{subject.name}</th> </tr>"
          elsif subject.type == "Subject"
            final += "<tr class='theme_bgcolor1 text_white' ><td class='level_0 bold'>#{subject.name}</td>"
            exam_set_names.each do |es_name|
              final += "<td class='bold'>#{es_name}</td>"
            end
            final += "</tr>"
            values[:level] = 0
            #              final += subject_row(subject, values[:level], values[:report], {:sub_skills => false})
          elsif subject.type == 'SubjectSkill'
            final += sub_skill_subject_row({:subject => subject, :level => values[:level], :report => values[:report], :parent_subject_id => values[:parent_subject_id]})
          end
          sub_subjects = subject.children(report, parent_subject_id)
          if sub_subjects.present?
            final += display_skills(
              {:subjects => sub_subjects,
                :report => values[:report],
                :level => values[:level] + 1,  :parent_subject_id => parent_subject_id}
            )
          end
        end
        return final
      end
     
      def aggregate_rows(options = {})
        round = options[:round] if options[:round].present? 
        round_marks = options[:round_marks] if options[:round_marks].present? 
        final = ""
        custom_padding = ""
        if options[:custom_padding].present?
          custom_padding = find_padding_for_rows
        end
        return final unless aggregate_enabled?(options)
        if settings[:enable_aggregate] == '1'
          report_exam_sets = without_skills_check(options) ? report.exam_sets_without_skills : report.exam_sets
          available_agg_types = report_exam_sets.collect(&:aggregates).flatten.collect(&:type).uniq
          aggregate_types = []
          aggregate_types << 'score' if settings[:show_total_score] == '1'
          aggregate_types << 'grade' if settings[:show_final_grade] == '1'
          aggregate_types << 'percentage' if settings[:show_final_percentage] == '1'
          aggregate_types << 'batch_position' if settings[:show_final_rank] == '1'
          aggregate_types << 'batch_average' if settings[:show_final_average] == '1'
          aggregate_types << 'batch_highest' if settings[:show_final_highest] == '1'
          aggregate_types << 'batch_lowest' if settings[:show_final_lowest] == '1'
          aggregate_types.each do |type|
            next unless available_agg_types.include? type
            aggregates = []
            if final_score_for_final_exam_enabled?(options)
              total_span = 0
              report.term_names.each do |term_name|
                if term_report?
                  total_span += report.term_section_col_count_without_addl_col(term_name,options)
                else
                  total_span += report.term_section_col_count(term_name,options)
                end
              end
              total_span -= final_report_exam(options).count if term_report?
              aggregates << content_tag(:td, I18n.t("total_#{type}"), :colspan => total_span + 1, :class => "bold #{custom_padding}" )
            elsif final_score_for_all_exams_enabled?
              aggregates << content_tag(:td, I18n.t("total_#{type}"), :class => "bold #{custom_padding}")
              report.term_names.each do |term_name|
                report_exam_sets = without_skills_check(options) ? exam_sets_without_skills(term_name) : report.exam_sets[term_name]
                report_exam_sets.each do |set|
                  if ((round.present? and round == true) or (round_marks.present? and round_marks == true))
                    aggregates << content_tag(:td,round(set.aggregates.find_by(:type => type).try(:value) || "-"),:class => "bold #{custom_padding}")
                  else
                    aggregates << content_tag(:td,(set.aggregates.find_by(:type => type).try(:value) || "-"),:class => "bold #{custom_padding}")
                  end
                  aggregates << content_tag(:td,"",:class => "#{custom_padding}") if set.additional_final_column.present?
                end
                if report.subject_wise_remark_enabled? and !term_report? and subject_remarks_present(report,term_name)
                  aggregates << content_tag(:td,"",:class => "#{custom_padding}")
                end
              end
            end
            final_sets =  final_report_exam(options)
            if final_score_for_final_exam_enabled?(options) or (final_score_for_all_exams_enabled? and !term_report?)
              final_sets.each do |set|
                if ((round.present? and round ==true) or (round_marks.present? and round_marks ==true))
                  aggregates << content_tag(:td,round(set.aggregates.find_by(:type => type).try(:value) || "-"),:class => "bold #{custom_padding}")
                else
                  aggregates << content_tag(:td,(set.aggregates.find_by(:type => type).try(:value) || "-"),:class => "bold #{custom_padding}")
                end
                if set.additional_final_column.present?
                  aggregates << content_tag(:td,"",:class => "#{custom_padding}")
                end
              end
            end
            if report.subject_wise_remark_enabled? and subject_remarks_present(report)
              aggregates << content_tag(:td,"",:class => "#{custom_padding}")
            end
            
            final += content_tag(:tr, aggregates)
          end
        end
        
        return final
      end
      
      def aggregate_rows_custom_e
        final = ""
        custom_padding = find_padding_for_rows
        return final unless aggregate_enabled?
        if settings[:enable_aggregate] == '1'
          available_agg_types = report.exam_sets.collect(&:aggregates).flatten.collect(&:type).uniq
          aggregate_types = []
          aggregate_types << 'score' if settings[:show_total_score] == '1'
          aggregate_types << 'grade' if settings[:show_final_grade] == '1'
          aggregate_types << 'percentage' if settings[:show_final_percentage] == '1'
          aggregate_types.each do |type|
            next unless available_agg_types.include? type
            aggregates = []
            if final_score_for_final_exam_enabled?
              total_span = 0
              report.term_names.each do |term_name|
                if term_report? and planner_report?
                  total_span += report.term_section_col_count_without_addl_col(term_name)
                else
                  total_span += report.term_section_col_count(term_name)
                end
              end
              total_span -= final_report_exam.count if term_report? 
              aggregates << content_tag(:td, I18n.t("total_#{type}"), :colspan => total_span + 1, :class => "bold #{custom_padding}" )
              aggregates << total_mark_distribution_custom_e(type,report,custom_padding) if planner_report? or term_report? 
            elsif final_score_for_all_exams_enabled?
              aggregates << content_tag(:td, I18n.t("total_#{type}"), :class => "bold #{custom_padding}")
              aggregates << total_mark_distribution_custom_e(type,report,custom_padding) if planner_report? or term_report? 
              report.term_names.each do |term_name|
                report.exam_sets[term_name].each do |set|
                  aggregates << content_tag(:td,(set.aggregates.find_by(:type => type).try(:value) || ""),:class => "#{custom_padding}")
                  aggregates << content_tag(:td,"",:class => "#{custom_padding}") if set.additional_final_column.present?
                end
                if report.subject_wise_remark_enabled? and !term_report? and subject_remarks_present(report,term_name)
                  aggregates << content_tag(:td,"",:class => "#{custom_padding}")
                end
              end
            end
            unless planner_report?
            final_sets =  final_report_exam
              if final_score_for_final_exam_enabled? or (final_score_for_all_exams_enabled? and !term_report?)
                final_sets.each do |set|
                  aggregates << content_tag(:td,(set.aggregates.find_by(:type => type).try(:value) || ""),:class => "#{custom_padding}")
                  if set.additional_final_column.present?
                    aggregates << content_tag(:td,"",:class => "#{custom_padding}")
                  end
                end
              end
              if report.subject_wise_remark_enabled? and subject_remarks_present(report)
                aggregates << content_tag(:td,"",:class => "#{custom_padding}")
              end
            end
            final += content_tag(:tr, aggregates)
          end
        end
        
        return final
      end 
      
      
      
      def total_mark_distribution_custom_e(type,report,custom_padding)
        final_rows = []
        final_rows << content_tag(:td,"100",:class => "#{custom_padding}") if type=="percentage"
        max_and_pass = maximum_and_pass_marks_custom_e
        max_value = max_and_pass[0].to_f
        pass_value = max_and_pass[1].to_f
        percent = (pass_value/max_value)*100
        final_rows << content_tag(:td,"#{percent}",:class => "#{custom_padding}") if type=="percentage"
        final_rows << content_tag(:td," ",:class => "#{custom_padding}") if type=="grade"
        final_rows << content_tag(:td," ",:class => "#{custom_padding}") if type=="grade"
        final_rows << content_tag(:td,max_mark_for_report_custom_e(report),:class => "#{custom_padding}") if type=="score"
        final_rows << content_tag(:td,pass_mark_for_report_custom_e(report),:class => "#{custom_padding}") if type=="score"
        return final_rows
      end
      
      def max_mark_for_report_custom_e(report)
        max_and_pass_marks = maximum_and_pass_marks_custom_e
        max_mark = max_and_pass_marks[0].to_f
        subjects_count = report.subjects.select{|c| c.type == "Subject"}.count
        return (max_mark*subjects_count)
      end
      
      def pass_mark_for_report_custom_e(report)
        max_and_pass_marks = maximum_and_pass_marks_custom_e
        pass_mark = max_and_pass_marks[1].to_f
        subjects_count = report.subjects.select{|c| c.type == "Subject"}.count
        return (pass_mark*subjects_count)
      end
      
      def attedance_report(values)
        round = values[:round] if values[:round].present?
        html = ''
        attendance = (values[:type].present? and values[:type] == 'term_and_consolidated') ? report.attendance_reports.to_a : report.exam_attendance_reports
        return html unless attendance.present?
        
        headers = [content_tag(:th, I18n.t('attendance'))] + attendance.map{|a| content_tag(:th,a.parent_name) }
        html += content_tag :thead do
          headers
        end
        
        if settings[:percentage] == '1'
          headers = [content_tag(:td, I18n.t('percentage_of_days'))] + attendance.map{|a| content_tag(:td,a.days_present_percentage) }
          html += content_tag :tr do
            headers
          end
        end
        if settings[:days_present_by_working_days] == '1'
          headers = [content_tag(:td, "#{I18n.t('days_present')}/#{I18n.t('no_of_working_days')}")] + attendance.map{|a| content_tag(:td,a.days_present_by_working_days(round)) }
          html += content_tag :tr do
            headers
          end
        end
        if settings[:working_days] == '1'
          if round.present? and round == true
            att_count = attendance.map{|a| content_tag(:td,a.total.to_f.ceil)}
          else
            att_count = attendance.map{|a| content_tag(:td,a.total)}
          end
          headers = [content_tag(:td, I18n.t('num_of_working_days'))] + att_count
          html += content_tag :tr do
            headers
          end
        end
        if settings[:days_present] == '1'
          if round.present? and round == true
            att_count = attendance.map{|a| content_tag(:td,a.attended.to_f.ceil)}
          else
            att_count = attendance.map{|a| content_tag(:td,a.attended)}
          end
          headers = [content_tag(:td, I18n.t('num_of_days_present'))] + att_count
          html += content_tag :tr do
            headers
          end
        end
        if settings[:days_absent] == '1'
          headers = [content_tag(:td, I18n.t('num_of_days_absent'))] + attendance.map{|a| content_tag(:td,a.no_of_days_absent(round)) }
          html += content_tag :tr do
            headers
          end
        end
        html
      end
	
      def get_subject_row(subject,level, options = {})
        template = without_skills_check(options) ? 'd' : ''
        html = subject_row({:subject => subject,:level => level, :parent_subject_id => nil, :template => template})
        if subject.type == "BatchSubjectGroup"
          sub_subjects = subject.children(report, nil)
          sub_subjects.each do |subject|
            html += subject_row({:subject => subject,:level => level+1, :parent_subject_id => subject.parent_subject_id, :template => template})
          end
        end
        html
      end
      
      def activity_set_name(activity_set)
        term_report? ? "Grade" : activity_set.term_name
      end
      
      def aggregate_rows_custom_g(options={})
          final = ""
          header = [content_tag(:td, "Terms")]
          report.term_names.each do |name|
              header << content_tag(:td, name)
          end
          final += content_tag :tr do
              header
          end
          aggregate_types = []
          aggregate_types << 'percentage' if settings[:show_final_percentage] == '1'
          tot_value = 0
          aggregate_types.each do |type|
              aggregates = []
              aggregates << content_tag(:td, I18n.t(type),  :class => 'bold' )
              exam_sets = report.exam_sets.select{|c| c.is_a_final_exam? and !c.planner_exam}
              if exam_sets.present?
              exam_sets.each do |set|
                  aggregates << content_tag(:td,(set.aggregates.find_by(:type => type).try(:value) || ""))
                  f_per = set.aggregates.find_by(:type => type).try(:value) || 0
                  tot_value += f_per
              end
              else
               report.term_names.each do |term|   
                 aggregates << content_tag(:td,"-")  
               end
              end
              final += content_tag(:tr, aggregates)
          end 
          if planner_report?
              overall_td = []
              overall_td << content_tag(:td, "Overall Percentage",  :class => 'bold' )
                  overall_td << content_tag(:td,(tot_value.zero? ? "-" : tot_value/2),:colspan=>report.term_names.count)
              final += content_tag(:tr, overall_td)
          end
          return final
      end
      
      def display_name_for_activity_exam(exam)
        key = report.report_template.to_s + "_activity_exam_header"
        if settings[key.to_sym].present? and settings[key.to_sym] == "exam_code"
          return exam.code
        end
        exam.term_name
      end
      
      private 
      
     def subject_row(options ={})
        round=options[:round] if  options[:round].present?
        round_marks=options[:round_marks] if  options[:round_marks].present?
        custom_padding = ""
        if options[:custom_padding].present?
          custom_padding = find_padding_for_rows
        end
        class_name = (options[:grouped_exams].present? and options[:level].zero?) ? 'bold' : ''
        content = [content_tag(:td, options[:subject].name, :class => "level_#{options[:level]} #{class_name} #{custom_padding}")]
        report.term_names.each do |term_name|
          report_exam_sets = without_skills_check(options) ? exam_sets_without_skills(term_name) : report.exam_sets[term_name]
          exam_set_values = report_exam_sets.collect{|e| {:set => e, :score => e.scores.group_by{|s| s.subject.obj_id}} }
          content = get_content(options.merge({:exam_set_values => exam_set_values, :content => content,:round=>round,:round_marks=>round_marks}))
          if report.subject_wise_remark_enabled? and subject_remarks_present(report,term_name)
            content << content_tag(:td, report.subject_remarks_of(:subject => options[:subject], :parent_name => term_name, :parent_type => 'AssessmentTerm'),:class => "#{custom_padding} left_text")
          end
        end
        exam_set_values = report.final_exam_sets(options).collect{|e| {:set => e, :score => e.scores.group_by{|s| s.subject.obj_id}} }
        content = get_content(options.merge({:exam_set_values => exam_set_values, :content => content,:round=>round,:round_marks=>round_marks}))
        if report.subject_wise_remark_enabled? and !term_report? and subject_remarks_present(report)
          content << content_tag(:td, report.subject_remarks_of(:subject => options[:subject], :parent_name => report.name, :parent_type => report.type),:class => "#{custom_padding} left_text")
        end
        content_tag :tr,:class => ( options[:grouped_exams] == true ? options[:level] == 0 ? "top_border" : "no_border" : "" ) do
          content
        end
      end
      
     def subject_remarks_present(report,term_name=nil)
       if term_name.present?
         return report.subject_remarks.select{|remark| remark.parent_type=="AssessmentTerm" and remark.parent_name== term_name}.present?
       else
         return report.subject_remarks.select{|remark| remark.parent_type==report.type}.present?
       end
     end
     
      def subject_row_custom_e(options ={})
        custom_padding = find_padding_for_rows
        max_and_pass_marks = maximum_and_pass_marks_custom_e
        max_mark = max_and_pass_marks[0].to_f
        pass_mark = max_and_pass_marks[1].to_f
        class_name = (options[:grouped_exams].present? and options[:level].zero?) ? 'bold' : ''
        content = [content_tag(:td, options[:subject].name, :class => "level_#{options[:level]} #{class_name} #{custom_padding}")]
        content << [content_tag(:td,max_mark,:class=>"#{custom_padding}" )] if planner_report? or term_report? 
        content << [content_tag(:td,pass_mark,:class=>"#{custom_padding}")] if planner_report? or term_report? 
        report.term_names.each do |term_name|
          exam_set_values = report.exam_sets[term_name].collect{|e| {:set => e, :score => e.scores.group_by{|s| s.subject.obj_id}} }
          content = get_content(options.merge({:exam_set_values => exam_set_values, :content => content}))
          if report.subject_wise_remark_enabled? and subject_remarks_present(report,term_name)
            content << content_tag(:td, report.subject_remarks_of(:subject => options[:subject], :parent_name => term_name, :parent_type => 'AssessmentTerm'),:class => "#{custom_padding} left_text")
          end
        end
        unless planner_report?
          exam_set_values = report.final_exam_sets.collect{|e| {:set => e, :score => e.scores.group_by{|s| s.subject.obj_id}} }
          content = get_content(options.merge({:exam_set_values => exam_set_values, :content => content}))
          if report.subject_wise_remark_enabled? and !term_report? and subject_remarks_present(report)
            content << content_tag(:td, report.subject_remarks_of(:subject => options[:subject], :parent_name => report.name, :parent_type => report.type),:class => "#{custom_padding} left_text")
          end
        end
        content_tag :tr,:class => ( options[:grouped_exams] == true ? options[:level] == 0 ? "top_border" : "no_border" : "" ) do
          content
        end
      end
      
      def subject_row_custom_j(options ={})
        log = Logger.new('log/custom_template_helper1.log')
        round=options[:round] if  options[:round].present?
        round_marks=options[:round_marks] if  options[:round_marks].present?
        term_exam=options[:is_term] if  options[:is_term].present?
        last_exam = options[:last_exam] if  options[:last_exam].present?
        log.info("last_exam base")
        log.info(last_exam)
        custom_padding = ""
        if options[:custom_padding].present?
          custom_padding = find_padding_for_rows
        end
        max_and_pass_marks = maximum_and_pass_marks_custom_j
        max_mark = max_and_pass_marks[0].to_f
        pass_mark = max_and_pass_marks[1].to_f
        class_name = (options[:grouped_exams].present? and options[:level].zero?) ? 'bold' : ''
        content = [content_tag(:td, options[:subject].name, :class => "level_#{options[:level]} #{class_name} #{custom_padding}")]
        report.term_names.each_with_index do |term_name , i|
          report_exam_sets = without_skills_check(options) ? exam_sets_without_skills(term_name) : report.exam_sets[term_name]
          exam_set_values = report_exam_sets.collect{|e| {:set => e, :score => e.scores.group_by{|s| s.subject.obj_id}} }
          content_with_status = get_content_custom_j(options.merge({:exam_set_values => exam_set_values, :content => content,:round=>round, :pass_mark => pass_mark, :term_exam => term_exam,:round_marks=>round_marks}))
          content = content_with_status[0] 
          @fail_exam_array << content_with_status[1] 
          if @fail_exam_array.present?
            if @fail_exam_array.flatten.uniq.include? last_exam
              @status = "false"
            end
          end
          if report.subject_wise_remark_enabled? and subject_remarks_present(report,term_name)
            content << content_tag(:td, report.subject_remarks_of(:subject => options[:subject], :parent_name => term_name, :parent_type => 'AssessmentTerm'),:class => "#{custom_padding} left_text")
          end
        end
        exam_set_values = report.final_exam_sets(options).collect{|e| {:set => e, :score => e.scores.group_by{|s| s.subject.obj_id}} }
        content_with_status = get_content_custom_j(options.merge({:exam_set_values => exam_set_values, :content => content,:term_exam => term_exam, :pass_mark => pass_mark,:round=>round,:round_marks=>round_marks}))
        content = content_with_status[0] 
        @fail_exam_array << content_with_status[1] 
          if @fail_exam_array.present?
            if @fail_exam_array.flatten.uniq.include? last_exam
              @status = "false"
            end
          end
        if report.subject_wise_remark_enabled? and !term_report? and subject_remarks_present(report)
          content << content_tag(:td, report.subject_remarks_of(:subject => options[:subject], :parent_name => report.name, :parent_type => report.type),:class => "#{custom_padding} left_text")
        end
        content_tag :tr,:class => ( options[:grouped_exams] == true ? options[:level] == 0 ? "top_border" : "no_border" : "" ) do
          content
        end
      end
      
      def find_padding_for_rows
        row_count = report.subjects.count
        row_count += 1 if settings[:show_total_score] == '1'
        row_count += 1 if settings[:show_final_grade] == '1'
        row_count += 1 if settings[:show_final_percentage] == '1'
        
        case row_count
        when 1..7
         return "padding_subject_7"
        when 8..9
         return "padding_subject_9"
        when 10..11
         return "padding_subject_11"
        when 12..13
         return "padding_subject_13"
        when 14..15
         return "padding_subject_15"
        else
         return "padding_subject_18"
        end 
      end
      
      def fetch_exam_sets(term_name, options)
        without_skills_check(options) ?  exam_sets_without_skills(term_name) : report.exam_sets[term_name]
      end
      
      def without_skills_check(options)
        (options.present? && options[:template].present? && options[:template] == 'd')
      end
      
      def exam_sets_without_skills(term_name)
        report.exam_sets[term_name].reject{|es| es.consider_skills }
      end
      
      def get_content(options = {})
          subject = options[:subject]
          exam_set_values = options[:exam_set_values]
          content = options[:content]
          round = options[:round] if options[:round].present?
          round_marks = options[:round_marks] if options[:round_marks].present?
          exam_set_values.each do |set_hash|
              exam_set = set_hash[:set]
              score = set_hash[:score][subject.obj_id].present? ? set_hash[:score][subject.obj_id].find{|s| s.subject.parent_subject_id == options[:parent_subject_id]} : nil
              marks_and_grades_printed = false
              if !options[:sub_skill].present? and options[:combine_final_grade].present? and exam_set.scoring_type == 'marks_and_grades' and (!exam_set.planner_exam and exam_set.is_a_final_exam?)
                  marks_and_grades_printed = true
                  #scores = (score.present? ? (score.is_absent ? '-' : "#{score.fetch_score_for_exam_set(exam_set,round)} (#{score.grade})") : '')
                  scores = (score.present? ? (score.is_absent ? '-' : (score.fetch_score_for_exam_set(exam_set,round,round_marks).to_s == score.grade.to_s ? score.grade.to_s : "#{score.fetch_score_for_exam_set(exam_set,round,round_marks)} (#{score.grade})")) : '')
                  content << content_tag(:td , (score.present? ? scores : ''))
              else
                if exam_set.additional_final_column.present? and score.present? and score.subject.present? and score.subject.is_activity == true
                  content << content_tag(:td , (score.present? ? (score.is_absent ? '-' : (score.grade.present?  ? (score.score.present? ? "#{score.fetch_score_for_exam_set(exam_set,round,round_marks)}" : "-") : "#{score.fetch_score_for_exam_set(exam_set,round,round_marks)}")) : ''))
                else
                  if score.present? and (score.subject.present? and score.subject.type == "AssessmentAttribute")
                    max_score = exam_set.hide_marks ? ' ' : "(#{score.max_score})"
                    content << content_tag(:td , (score.present? ? (score.is_absent ? '-' : (score.grade.present?  ? (score.score.present? ? "#{score.fetch_score_for_exam_set(exam_set,round,round_marks) + max_score}" : score.grade.to_s) : "#{score.fetch_score_for_exam_set(exam_set,round,round_marks) + max_score}")) : ''))
                  elsif score.present? and ((score.subject.present? and score.subject.type == "BatchSubjectGroup") or (score.subject.present? and score.subject.parent_type == "Batch"))
                    content << content_tag(:td , (score.present? ? (score.is_absent ? '-' : (score.grade.present?  ? (score.score.present? ? "#{score.fetch_score_for_exam_set(exam_set,round,round_marks)}" : score.grade.to_s) : "#{score.fetch_score_for_exam_set(exam_set,round,round_marks)}")) : ''),:class => "bold" )                  
                  else
                    content << content_tag(:td , (score.present? ? (score.is_absent ? '-' : (score.grade.present?  ? (score.score.present? ? "#{score.fetch_score_for_exam_set(exam_set,round,round_marks)}" : score.grade.to_s) : "#{score.fetch_score_for_exam_set(exam_set,round,round_marks)}")) : ''))
                  end
                end
              end 
       
              
              if !options[:sub_skill].present? and !marks_and_grades_printed 
                  
                  if exam_set.additional_final_column.present?
                      
                      if exam_set.scoring_type == 'marks_and_grades'
                        if score.present? and ((score.subject.present? and score.subject.type == "BatchSubjectGroup") or (score.subject.present? and score.subject.parent_type == "Batch"))
                          content << content_tag(:td, score.present? ? (score.is_absent ? '-' : score.grade) : '',:class => "bold" )
                        else
                          content << content_tag(:td, score.present? ? (score.is_absent ? '-' : score.grade) : '')
                        end
                      elsif exam_set.show_percentage
                        if score.present? and ((score.subject.present? and score.subject.type == "BatchSubjectGroup") or (score.subject.present? and score.subject.parent_type == "Batch"))
                          content << content_tag(:td, score.present? ? (score.is_absent ? '-' : score.percentage) : '',:class => "bold")
                        else
                          content << content_tag(:td, score.present? ? (score.is_absent ? '-' : score.percentage) : '')
                        end
                      end
                  end
              end
          end
          
          content
      end
      
      def get_content_custom_j(options = {})
          log = Logger.new('log/custom_template_helper1.log')
          subject = options[:subject]
          exam_set_values = options[:exam_set_values]
          content = options[:content]
          round = options[:round] if options[:round].present?
          round_marks = options[:round_marks] if options[:round_marks].present?
          pass_mark = options[:pass_mark] if options[:pass_mark].present?
          log.info("pass_mark upper")
          log.info(pass_mark)
          term_exam = options[:term_exam] if options[:term_exam].present?
          flag = 'pass'
          activity_total = false
          
          exam_set_values.each_with_index do |set_hash , i|
              exam_set = set_hash[:set]
              score = set_hash[:score][subject.obj_id].present? ? set_hash[:score][subject.obj_id].find{|s| s.subject.parent_subject_id == options[:parent_subject_id]} : nil
              if score.present? and score.min_score.present? and score.min_score.to_f > 0.0 
                pass_mark = score.min_score.to_f if (!options[:pass_mark].present? or options[:pass_mark] <= 0)
              end
              marks_and_grades_printed = false
              if !options[:sub_skill].present? and options[:combine_final_grade].present? and exam_set.scoring_type == 'marks_and_grades' and (!exam_set.planner_exam and exam_set.is_a_final_exam?)
                  marks_and_grades_printed = true
                  #scores = (score.present? ? (score.is_absent ? '-' : "#{score.fetch_score_for_exam_set(exam_set,round)} (#{score.grade})") : '')
                  if score.present? and score.grade == nil and score.subject.is_activity == true and score.subject.exclude_from_total == true
                    activity_total = true
                  end
                  scores = (score.present? ? (score.is_absent ? '-' : (score.fetch_score_for_exam_set(exam_set,round,round_marks,activity_total).to_s == score.grade.to_s ? score.grade.to_s : "#{score.fetch_score_for_exam_set(exam_set,round,round_marks,activity_total)} (#{score.grade})")) : '')
                  if score.present? and score.is_absent == false and !(score.subject.type == "SubjectSkill")
                    mark_scored = score.fetch_score_for_exam_set(exam_set,round,round_marks,activity_total)
                    if (mark_scored.to_s != score.grade.to_s and activity_total == false)
                      mark_scored.to_f < pass_mark.to_f ? flag = 'fail': flag = 'pass'
                    end
                  end
                  content << content_tag(:td , (score.present? ? scores : '') ,:class => "status_#{flag}")
              else
                if score.present? and score.grade == nil and score.subject.is_activity == true and score.subject.exclude_from_total == true
                  activity_total = true
                end
                if score.present? and score.is_absent == false and !(score.subject.type == "SubjectSkill")
                  mark_scored = score.fetch_score_for_exam_set(exam_set,round,round_marks,activity_total)
                    if (mark_scored.to_s != score.grade.to_s and activity_total == false)
                      mark_scored.to_f < pass_mark.to_f ? flag = 'fail': flag = 'pass'
                    end
                end
                  content << content_tag(:td , (score.present? ? (score.is_absent ? '-' : (score.grade.present?  ? (score.score.present? ? "#{score.fetch_score_for_exam_set(exam_set,round,round_marks,activity_total)}" : score.grade.to_s) : "#{score.fetch_score_for_exam_set(exam_set,round,round_marks,activity_total)}")) : ''),:class => "status_#{flag}")
              end 
       
              
              if !options[:sub_skill].present? and !marks_and_grades_printed 
                  
                  if exam_set.additional_final_column.present?
                      if exam_set.scoring_type == 'marks_and_grades'
                          content << content_tag(:td, score.present? ? (score.is_absent ? '-' : score.grade) : '')
                      elsif exam_set.show_percentage
                          content << content_tag(:td, score.present? ? (score.is_absent ? '-' : score.percentage) : '')
                      end
                  end
              end
              flag == 'fail' ? @exam_array << exam_set.obj_id : ''
          end
#          flag == 'fail' ? final_flag = false : final_flag = true
          return content, @exam_array
      end
      
      def sub_skill_subject_row(options ={})
        
        content = [content_tag(:td, options[:subject].name, :class => "level_#{options[:level]}")]
        if  group_report?
          exam_set_values = report.exam_sets.select{|es| es.consider_skills == true }.collect{|e| {:set => e, :score => e.scores.group_by{|s| s.subject.obj_id}} }
          content = get_content(options.merge({:exam_set_values => exam_set_values, :content => content, :sub_skill => true}))
        else
          report.term_names.each do |term_name|
            exam_set_values = report.exam_sets[term_name].select{|es| es.consider_skills == true }.collect{|e| {:set => e, :score => e.scores.group_by{|s| s.subject.obj_id}} }
            content = get_content(options.merge({:exam_set_values => exam_set_values, :content => content, :sub_skill => true}))
          end
        end
        content_tag :tr do
          content
        end
        
      end
      
      def final_score_for_all_exams_enabled?
        settings[:all_exam_score] == '0'
      end

      def final_score_for_final_exam_enabled?(options = {})
        settings[:all_exam_score] == '1' and final_report_exam(options).present?
      end
      
      def aggregate_enabled?(options = {})
        settings[:enable_aggregate] == '1' and (final_score_for_all_exams_enabled? or final_score_for_final_exam_enabled?(options))
      end
      
      def final_report_exam(options = {})
        if planner_report? or group_report?
          report.final_exam_sets(options)
        else
          report.final_exams(options)
        end
      end
      
      def report_published_date_custom_e
        published_date = report_model_obj.generated_report_batch.created_at
        return format_date(published_date,:format => :short_date)
      end
      
      def get_result_remark_custom_e(remarks)
        result_remark = remarks.select{|c| c.name.strip.downcase == "result"}.first
        return result_remark.present? ? result_remark.remark : " "
      end
      
      def get_promotion_remark_custom_e(remarks)
        promotion_remark = remarks.select{|c| c.name.strip.downcase == "promotion"}.first
        return promotion_remark.present? ? promotion_remark.remark : " "
      end
      
      def report_remarks_custom_e(remarks)
        result_remark = remarks.select{|c| c.name.strip.downcase == "result"}
        promotion_remark = remarks.select{|c| c.name.strip.downcase == "promotion"}
        return report_remarks(remarks-result_remark-promotion_remark)
      end
      
      def report_column_padding(report)
        count = sub_headers(report,{:get_column_count=>true})
        case count 
        when 12..20
          return "font_size_9"
        else
          return ""
        end
      end
      def round(value)
        if value.present?
          value.class == String ? value : value.round
        else
          ""
        end
      end
      
    end
  end
end
