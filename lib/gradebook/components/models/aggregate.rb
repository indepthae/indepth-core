# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.

module Gradebook
  module Components
    module Models
      class Aggregate < Base
        include Rounding

        properties :type, :parent_name, :parent_type, :name, :value

        ROUNDOFF_TYPES = %w{score percentage batch_highest batch_lowest batch_average}

        round_off_properties :value, :if => Proc.new { ROUNDOFF_TYPES.include? type }
      end
    end
  end
end
