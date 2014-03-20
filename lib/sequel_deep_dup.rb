require 'sequel'
require 'sequel/plugins/instance_hooks'

module Sequel
  module Plugins
    module DeepDup
      class DeepDupper
        attr_reader :instance

        def initialize instance
          @instance = instance
          @cloned   = []
        end

        def shallow_dup instance
          klass      = instance.class
          attributes = instance.to_hash.dup
          [*klass.primary_key].each { |attr| attributes.delete(attr) } 
          klass.new attributes
        end

        def dup_associations instance, copy, associations
          associations.each do |name|
            next unless refl = instance.class.association_reflection(name)
            [*instance.send(name)].each { |rec| instantiate_associated(copy, refl, rec) }
          end
        end

        def dup
          deep_dup(instance)
        end

        private
        def deep_dup instance
          copy = shallow_dup(instance).extend(InstanceHooks::InstanceMethods)
          @cloned << instance
          dup_associations(instance, copy, instance.class.associations)
          copy
        end

        def instantiate_associated copy, reflection, record
          return if @cloned.detect { |cloned| record.pk == cloned.pk && record.class == cloned.class }

          unless reflection[:type] == :many_to_many
            record = deep_dup(record)
          end

          if reflection.returns_array?
            copy.send(reflection[:name]) << record
            copy.after_save_hook{ copy.send(reflection.add_method, record) }
          end
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
