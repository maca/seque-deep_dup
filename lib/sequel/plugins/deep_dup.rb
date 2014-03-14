module Sequel
  module Plugins
    module DeepDup
      class << self
        def apply model, opts=OPTS
          # model.instance_variable_set :@touched_associations, {}
        end

        def configure model, opts=OPTS
          # model.touch_associations(opts[:associations]) if opts[:associations]
        end

        def deep_dup instance, opts = {}
          associations = opts[:associations] || []

          values = instance.to_hash.dup
          instance.pk_hash.keys.each{ |attr| values.delete(attr) }
          copy = instance.class.create values

          associations.map do |name|
            next unless refl = instance.class.association_reflection(name)
            associated = instance.send(name)
            
            case refl[:type]
            when :one_to_many
              associated.each do |rec|
                new_rec = deep_dup(rec)
                copy.send refl.add_method, new_rec
              end
            end
          end

          copy
        end
      end

      module ClassMethods
        # def touch_associations *associations
        # end
      end

      module InstanceMethods
        def deep_dup
          DeepDup.deep_dup self, associations: self.class.associations
        end
      end
    end
  end
end
