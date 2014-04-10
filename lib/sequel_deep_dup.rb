require 'sequel'
require 'sequel/plugins/instance_hooks'

module Sequel
  module Plugins
    module DeepDup
      class DeepDupper
        attr_reader :instance, :omit_records, :associations

        def initialize instance, opts = {}
          @instance     = instance
          @associations = opts[:associations]
          @omit_records = opts[:omit_records] || []
        end

        def dup
          copy = shallow_dup.extend(InstanceHooks::InstanceMethods)
          omit_records << instance
          dup_associations(instance, copy, associations)
          copy
        end

        def shallow_dup
          klass      = instance.class
          attributes = instance.to_hash.dup
          [*klass.primary_key].each { |attr| attributes.delete(attr) }
          klass.new attributes
        end

        def dup_associations instance, copy, includes = nil
          includes &&= normalize_graph(includes)
          associations = instance.class.associations

          if includes
            (includes.keys - associations).each do |assoc|
              raise(Error, "no association named #{assoc} for #{instance}")
            end
          end

          associations.each do |name|
            next unless refl = instance.class.association_reflection(name)
            [*instance.send(name)].compact.each do |rec|
              if includes
                next unless includes.has_key?( refl_name = refl[:name] )
                instantiate_associated copy, refl, rec, includes[refl_name]
              else
                next copy.values.delete(refl[:key]) if refl[:type] == :many_to_one
                instantiate_associated(copy, refl, rec, nil)
              end
            end
          end
        end

        def normalize_graph(*enum)
          enum.inject({}) do |hash, assoc|
            case assoc
            when Symbol then hash[assoc] = {}
            when Hash   then assoc.each { |k, v| hash[k] = normalize_graph(v) }
            else hash.merge!(normalize_graph(*assoc) || next)
            end
            hash
          end
        end

        private
        def instantiate_associated copy, reflection, record, associations
          return if omit_records.detect { |to_omit| record.pk == to_omit.pk && record.class == to_omit.class }

          unless reflection[:type] == :many_to_many
            record = DeepDupper.new(
              record,
              :omit_records => omit_records,
              :associations => associations
            ).dup
          end

          if reflection.returns_array?
            copy.send(reflection[:name]) << record
            copy.after_save_hook{ copy.send(reflection.add_method, record) }
          else
            copy.associations[reflection[:name]] = record
            copy.instance_variable_set :@set_associated_object_if_same, true

            if reflection[:type] == :many_to_one
              copy.before_save_hook {
                copy.send reflection.setter_method, record.save
              }
            else
              copy.after_save_hook{
                copy.send(reflection.setter_method, record)
              }
            end
          end
        end
      end

      module InstanceMethods
        def deep_dup *associations
          associations = nil if associations.empty?
          DeepDupper.new(self, :associations => associations).dup
        end
      end
    end
  end
end
