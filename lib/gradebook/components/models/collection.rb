# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.

module Gradebook
  module Components
    module Models
      class Collection < Array
        
        def [](index)
          if index.is_a? Fixnum
            super(index)
          else
            find_all_by(:term_name => index)
          end
        end
        
        ##
        #Exam Set
        
        def planner_exam
          exam_set_type?
          find_by(:planner_exam => true)
        end
        
        def term_exam(term)
          exam_set_type?
          find_by(:term_name => term, :term_exam => true)
        end
        
        def term_exams
          exam_set_type?
          find_all_by(:term_exam => true)
        end
        
        ##
        #Finder Methods
        
        # Search for the collection elements with properties passed as parameter
        # find_by returns first occurrence and find_all_by and search() return all
        # occurrences
        # 
        # Format :. find_by(:property_name => property_name)
        
        def find_by(args)
          self.find{|el| !args.map{|a,b| el.send(a) == b }.include?(false)}
        end
        
        def find_all_by(args)
          self.select{|el| !args.map{|a,b| el.send(a) == b }.include?(false)}
        end
        
        def search(args)
          find_all_by(args)
        end
        
        private
        
        ##
        # Raise Errors upon calling inappropriate methods on collections
        
        def exam_set_type?
          raise NoMethodError if self.length > 0 and !self[0].is_a? Gradebook::Components::Models::ExamSet
        end
      end
    end
  end
end
