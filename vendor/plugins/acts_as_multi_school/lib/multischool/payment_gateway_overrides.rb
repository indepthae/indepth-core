# To change this template, choose Tools | Templates
# and open the template in the editor.

module MultiSchool
  module PaymentGatewayOverrides

    def self.attach_overrides
      CustomGatewaysController.send :include, MultiSchool::PaymentGatewayOverrides::GatewayControllerOverrides
      CustomGateway.send :include, MultiSchool::PaymentGatewayOverrides::CustomGatewayOverrides
    end

    module CustomGatewayOverrides

      def self.included(base)
        base.extend AccessMethods
        base.class_eval do
          class << self
            alias_method_chain :available_gateways, :multischool
            alias_method_chain :own_gateways, :multischool
          end
        end
      end

      module AccessMethods
        def available_gateways_with_multischool
          school = MultiSchool.current_school
          assigned_gateways = GatewayAssignee.find_all_by_assignee_id_and_assignee_type(school.id,"School")
          CustomGateway.find_all_by_id(assigned_gateways.collect(&:custom_gateway_id))
        end

        def own_gateways_with_multischool
          school = MultiSchool.current_school
          assigned_gateways = GatewayAssignee.find_all_by_assignee_id_and_assignee_type_and_is_owner(school.id,"School",true)
          CustomGateway.find_all_by_id(assigned_gateways.collect(&:custom_gateway_id))
        end
      end

    end

    module GatewayControllerOverrides

      def self.included(base)
        base.alias_method_chain :create, :multischool
        base.alias_method_chain :destroy, :multischool
        base.alias_method_chain :edit, :multischool
        base.alias_method_chain :update, :multischool
      end

      def create_with_multischool
        @gateway = CustomGateway.new(params[:custom_gateway])
        if @gateway.save
          GatewayAssignee.create(:custom_gateway_id=>@gateway.id,:assignee=>MultiSchool.current_school,:is_owner=>true)
          flash[:notice] = "New Custom Gateway created successfully."
          redirect_to custom_gateways_path
        else
          render :new
        end
      end

      def destroy_with_multischool
        @gateway = CustomGateway.find(params[:id])
        assigned_row = GatewayAssignee.find(:first,:conditions=>{:assignee_id=>MultiSchool.current_school.id,:assignee_type=>"School",:is_owner=>true,:custom_gateway_id=>@gateway.id})
        @active_gateway = PaymentConfiguration.config_value("fedena_gateway")
        unless (@active_gateway.include? @gateway.id.to_s or assigned_row.nil?)
          @gateway.update_attributes(:is_deleted=>true)
          assigned_row.destroy
          flash[:notice]="Custom Gateway deleted successfully."
        else
          flash[:notice]="Custom Gateway could not be deleted."
        end
        redirect_to custom_gateways_path
      end

      def edit_with_multischool
        @gateway = CustomGateway.find(params[:id])
        assigned_row = GatewayAssignee.find(:first,:conditions=>{:assignee_id=>MultiSchool.current_school.id,:assignee_type=>"School",:is_owner=>true,:custom_gateway_id=>@gateway.id})
        if assigned_row.present?
          @gateway = @gateway.remodel_params_hash
        else
          flash[:notice]="#{t('flash_msg4')}"
          redirect_to :controller=>'user', :action=>'dashboard'
        end
      end

      def update_with_multischool
        @gateway = CustomGateway.find(params[:id])
        assigned_row = GatewayAssignee.find(:first,:conditions=>{:assignee_id=>MultiSchool.current_school.id,:assignee_type=>"School",:is_owner=>true,:custom_gateway_id=>@gateway.id})
        if assigned_row.present?
          if @gateway.update_attributes(params[:custom_gateway])
            flash[:notice] = "#{t('gateway_updation_msg')}"
            redirect_to custom_gateways_path
          else
            render :edit
          end
        else
          flash[:notice]="#{t('flash_msg4')}"
          redirect_to :controller=>'user', :action=>'dashboard'
        end
      end

    end
  end
end
