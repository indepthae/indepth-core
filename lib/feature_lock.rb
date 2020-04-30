require 'fileutils'

module FeatureLock

  def self.included (base)
    base.send :extend, ClassMethods
    base.send :include, InstanceMethods
  end

  module ClassMethods

    def lock_with_feature (feature, options={})
      feature = feature.to_s
      filter_chain.prepend_filter_to_chain([options], :before) do |controller|
        controller.redirect_if_feature_locked(feature)
      end
    end

  end


  module InstanceMethods

    def redirect_if_feature_locked (feature)
      if feature_locked?(feature)
        if controller_path =~ /^api\//
          render :status => 501, :text=>'under-maintenance' and return true
        else
          flash[:notice] = "The application is being updated with new features. Please try accessing the page again after sometime."
          redirect_to(:controller=>:user, :action=>:dashboard) and return true
        end
      end
    end

    def feature_locked? (feature)
      FeatureLock.feature_locked?(feature)
    end

  end

  def self.lock_feature (feature)
    feature = feature.to_s
    FileUtils.touch('tmp/'+feature+'.featurelock')
  end

  def self.unlock_feature (feature)
    feature = feature.to_s
    FileUtils.remove('tmp/'+feature+'.featurelock')
  end

  def self.run_with_feature_lock (feature, &block)
    lock_feature feature
    yield block
  ensure
    unlock_feature feature
  end

  def self.feature_locked? (feature)
    feature = feature.to_s
    File.file?('tmp/'+feature+'.featurelock')
  end

end

