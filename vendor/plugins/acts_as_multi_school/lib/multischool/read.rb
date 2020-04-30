module MultiSchool

  module Read

    def self.extended (base)
      
      eigen_class = class << base;self;end
      
      ["find","count","sum","exists?"].each do |method|
        
        matches = method.match /([\w\d_]+)(\?|!|=)?$/
        
        eigen_class.send :define_method, "#{matches[1]}_with_school#{matches[2]}" do |*args|

          options = args.extract_options!
          skip_multischool = options.delete :skip_multischool
          args << options unless options.empty?
          
          result = if skip_multischool || Thread.current[:skip_multischool].present?
            send("#{matches[1]}_without_school#{matches[2]}",*args)
          else
            with_school do
              send("#{matches[1]}_without_school#{matches[2]}",*args)
            end
          end
          result
        end

        eigen_class.send :alias_method_chain, method, :school
      end

    end

    def skip_multischool
      Thread.current[:skip_multischool]=true
      yield
    ensure
      Thread.current[:skip_multischool]=nil
    end

    private

    def with_school      
      target_school = MultiSchool.current_school
      if target_school.nil?
        raise MultiSchool::Exceptions::SchoolNotSelected,"School Not Selected"
      else
        with_scope(:find => {:conditions  => {:school_id  => target_school.id}}) do
          yield
        end
      end
    end

  end

end
