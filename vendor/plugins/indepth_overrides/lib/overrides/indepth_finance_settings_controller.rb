module IndepthOverrides
  module IndepthFinanceSettingsController
  	def self.included (base)
      base.instance_eval do
        alias_method_chain :index, :tmpl
      end
    end

    def index_with_tmpl
      config_keys = [
        'MultiReceiptNumberSetEnabled', # multiple receipt number set enabled = 1
        'MultiReceiptTemplateEnabled', # multiple receipt template enabled = 1
        'MultiFeeAccountEnabled', # multiple fee accounts enabled = 1
      ]
      fetch_config_hash config_keys
      render :template => "indepth_finance_settings/index_with_tmpl"
    end
    
    def single_statement_header_settings
      @single_statement_header = SingleStatementHeader.first || SingleStatementHeader.new
      if request.post?
        if @single_statement_header.nil?
          # @single_statement_header = SingleStatementHeader.new
        end
        @single_statement_header.logo = params[:single_statement_header]["logo"] if params[:single_statement_header].present? and params[:single_statement_header][:logo].present?
        @single_statement_header.title = params[:single_statement_header]["title"]
        @single_statement_header.is_empty = params[:single_statement_header]["is_empty"]
        @single_statement_header.space_height = params[:single_statement_header]["space_height"]
        @single_statement_header.save
      else
      end
      if !@single_statement_header.nil?
        if @single_statement_header.is_empty
          @checked_val = true
        else
          @checked_val = false
        end
      else
        @checked_val = false
      end
      puts @checked_val.inspect
      @space_height = @single_statement_header.nil? ? 0  : @single_statement_header.space_height
      @title = @single_statement_header.nil? ? ""  : @single_statement_header.title
      @logo = @single_statement_header.nil? ? ""  : @single_statement_header.logo
      render :template => 'indepth_finance_settings/single_statement_header_settings'
    end
  
  end
end