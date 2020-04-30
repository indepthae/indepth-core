module IndepthOverrides
  module IndepthCustomReportsController
  	def self.included (base)
      base.instance_eval do
        alias_method_chain :generate, :tmpl
      end
    end
    
    def generate_with_tmpl
      @report=Report.new
      @report.model = @model_name
      @model.extend JoinScope
      @model.extend AdditionalFieldScope
      @search_fields = @model.fields_to_search_ext.deep_copy
      make_report_columns_tmpl
      @search_fields.each do |type,columns|
        case type
        when :string
          columns.each do |col|
            ["like","begins_with","equals"].each do |criteria|
              @report.report_queries.build(:table_name => @model_name,:column_name=>col,:criteria=>criteria,:column_type=>type,:field_name=>col)
            end
          end
        when :date
          columns.each do |col|
            ["gte","lte","equals"].each do |criteria|
              @report.report_queries.build(:table_name => @model_name,:column_name=>col,:criteria=>criteria,:column_type=>type,:field_name=>col)
            end
          end
        when :association
          columns.each do |col|
            case col
            when Symbol
              @report.report_queries.build(:table_name => @model_name,:column_name=>col,:criteria=>"in",:column_type=>type,:field_name=>col)
            when Hash
              @report.report_queries.build(:table_name => @model_name,:column_name=>col.keys.first,:criteria=>"in",:column_type=>type,:field_name=>col.keys.first)
            end
          end
        when :boolean
          columns.each do |col|
            @report.report_queries.build(:table_name => @model_name,:column_name=>col,:criteria=>"is",:column_type=>type,:field_name=>col)
          end
        when :integer
          columns.each do |col|
            ["gte","lte","equals"].each do |criteria|
              @report.report_queries.build(:table_name => @model_name,:column_name=>col,:criteria=>criteria,:column_type=>type,:field_name=>col)
            end
          end
        end

      end
      @search_fields[:additional]= @model.additional_field_methods
      @model.get_additional_fields.each do |f|
        if f.name.to_i == 0
          ["equals"].each do |criteria|
            @report.report_queries.build(:table_name => @model.additional_detail_model.to_s,:column_name=>f.id,:criteria=>criteria,:column_type=>:additional,:field_name=>( f.name.downcase.gsub(" ","_") + "_additional_fields_" + f.id.to_s))
          end
        end
      end
      @assoc_value = @report.report_queries.select{|rq| rq.column_type == :association}.inject({}){|hash,r| hash.merge(r.column_name.to_s => r.values_for_associations.map{|a| {"label" => a.to_s,"id" => a.id}})}
      if request.post?
        @report = Report.new(params[:report])
        if @report.save
          flash[:notice]="#{t('report_created_successfully')}"
          redirect_to :action => "index"
        else
          render :action => "generate"
        end
      end

    end

    def make_report_columns_tmpl
      @report_column_hash = {}
      fields_to_display=@model.fields_to_display_ext
      unless Configuration.enabled_roll_number?
        fields_to_display-= [:roll_number]
      end
      fields_to_display.each do |col|
        col.each do |key,value|
          @report_column_hash[key]=[] unless @report_column_hash.key?(key)
          value.each do |v|
            case v
            when Hash
              v.each do |assoc, methods|
                methods.each do |m|
                  @report_column_hash[key] <<@report.report_columns.build(:method=>m,:title=>t((assoc.to_s + "_" + m.to_s)), :association_method => assoc)
                end
              end
            when Symbol
              @report_column_hash[key] << @report.report_columns.build(:method=>v,:title=>t(v),:association_method => nil)
            end
          end
        end
      end
      @model.additional_field_methods.each do |col|
        @report_column_hash[:main] << @report.report_columns.build(:method=>col,:title=>col.to_s.titleize)
      end
    end
    
  end
end