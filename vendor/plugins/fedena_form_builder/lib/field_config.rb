# To change this template, choose Tools | Templates
# and open the template in the editor.

module FieldConfig

  # this allows us to lazily instantiate the configuration by reading it in when it needs to be accessed
  class << self
    # if a method is called on the class, attempt to look it up in the config array
    def method_missing(meth, *args, &block)
      if args.empty? && block.nil?
        field_config[meth.to_s]
      end
    end

    private

    def field_config

      @field_config ||= YAML.load(ERB.new(File.read(File.join(::Rails.root, 'vendor/plugins/fedena_form_builder','config', 'fields.yml'))).result)
    rescue
      warn('something wrong in fields yml file.')
      {}
    end
  end
end