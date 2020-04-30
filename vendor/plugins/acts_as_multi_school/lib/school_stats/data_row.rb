module SchoolStats

  class DataRow

    attr_reader :attributes_hash,:data_entity
    
    def initialize (row,data_entity)
      @attributes_hash =(row.present?? (row.class==Hash ? row : row.attributes) : {})
      #      @attributes_hash = row.attributes
      @data_entity = data_entity
    end

    def read (field_name)
      DataValue.new(field_name,@attributes_hash[field_name.to_s],get_field(field_name.to_sym),@attributes_hash['id'])
    end

    private

    def get_field (field_name)
      data_entity.fields[field_name].try(:first)
    end
        
  end

  DataValue = Struct.new(:field_name,:value,:field,:row_id) do
    def to_s
      if (field && field.is_child?) && (field.is_live? || field.is_attendance?)
        "<span id='#{field.child_entity.entity.name}' class='child-entity'>#{self.value}</span>"
      elsif field && field.is_child?
        "<a href='#' id='#{field.child_entity.url_path(row_id)}' class='child-entity'>#{self.value}</a>"
      else
        self.value
      end
    end
  end
  
  class DataField
    attr_reader :name,:value,:data_entity,:child_entity

    def initialize (field,data_entity)
      @name = field
      @data_entity = data_entity
      check_child
    end
    
    def is_child?
      child_entity.present?
    end

    def is_live?
      data_entity.type.to_s=="live"
    end
    def is_attendance?
      data_entity.type.to_s=="attendance"
    end

    private

    def check_child
      if child=data_entity.child_entities.detect{|ce| ce.name.to_s == @name.to_s}
        @child_entity = child
      end
    end
    
  end

  class DataCollection < WillPaginate::Collection
    attr_reader :entity

    def initialize (collection,entity)
      @entity , @collection = entity, collection
      replace @collection      
    end

    def replace collection
      {:current_page=>1, :per_page=>30, :total_entries=>30, :total_pages=>1}.each{|k,v| instance_variable_set("@#{k}",(collection.send(k) if collection.respond_to? k)||v)}
      result = super

      if total_entries.nil? and length < per_page and (current_page == 1 or length > 0)
        self.total_entries = offset + length
      end

      result
    end

  end
  
end
