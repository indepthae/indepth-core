module MultiSchool
  module UserOverrides
    def self.extended (base)
        base.metaclass.send :alias_method_chain, :find, :zero
    end

    # overrides default find to create pseudo User objects for supportuser and superadmin
    # using id -1 and 0 to be stored in user_id columns and differentiate from other user entries
    def find_with_zero (*args)
      case args.first
        when 0
          val_hash = {'id'=>0, 'first_name'=>'Master Support User',
                      'admin'=>true, 'username' => 'mastersupportuser', 'is_first_login' => false}
        when -1
          val_hash = {'id'=>-1, 'first_name'=>'Super Admin',
                      'admin'=>true, 'username' => 'superadminuser', 'is_first_login' => false}
      else
        return find_without_zero(*args)
      end

      user_hash = ::User.new.attributes.merge(val_hash)
      special_user = ::User.instance_eval{instantiate(user_hash)}
      return special_user
    end

  end
end
