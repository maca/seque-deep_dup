module Sequel
  module Plugins
    module DeepDup
      class << self
        def apply model
          model.plugin(:instance_hooks)
        end
      end

      module ClassMethods
      end

      class DeepDupper
        attr_reader :instance

        def initialize instance
          @instance = instance
        end

        def shallow_dup instance
          klass      = instance.class
          attributes = instance.to_hash.dup
          [*klass.primary_key].each{ |attr| attributes.delete(attr) } 
          klass.new attributes
        end

        def dup_associations instance, copy, associations
          associations.each do |name|
            next unless refl = instance.class.association_reflection(name)
            [*instance.send(name)].each { |rec| instantiate_associated(copy, refl, rec) }
          end
        end

        def instantiate_associated copy, reflection, record
          record = shallow_dup(record)

          if reflection.returns_array?
            copy.send(reflection[:name]) << record
            copy.after_save_hook{ copy.send(reflection.add_method, record) }
          end
          

          # else
          #   # case refl[:type]
          #   # when :one_to_many
          #   #   associated.each do |rec|
          #   #     new_rec = deep_dup(rec)
          #   #     copy.send refl.add_method, new_rec
          #   #   end
          #   # end
          #   end
        end

        def dup
          copy = shallow_dup instance
          dup_associations instance, copy, instance.class.associations
          copy
        end
      end

      module InstanceMethods
        def deep_dup
          DeepDupper.new(self).dup
        end
      end
    end
  end
end
