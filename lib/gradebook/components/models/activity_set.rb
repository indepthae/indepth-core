# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.

module Gradebook
  module Components
    module Models
      class ActivitySet < Base
        properties :activities, :scores, :name, :planner_name, :term_name,:profile_name,:code
      end
    end
  end
end
