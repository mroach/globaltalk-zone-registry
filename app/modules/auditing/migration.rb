module Auditing
  module Migration
    # @param table_or_model [String | ApplicationRecord] Table name or model class
    # @param except_column [Array | Set]
    #   List of columns to not audit log
    #   By default this will be:
    #     * the primary key
    #     * counter caches
    #     * timestamps
    def enable_auditing(table_or_model, except_columns: Set.new)
      table_name, model_class = case table_or_model
      in Class => c
        [c.table_name, c]
      in String => s
        [s, ApplicationRecord.descendants.select { it.table_name == s }.sole]
      end

      except_columns = except_columns.map(&:to_s).to_set
      except_columns += Set[
        model_class.primary_key,
        *model_class.timestamp_attributes_for_create_in_model,
        *model_class.timestamp_attributes_for_update_in_model
      ]

      # Tables that don't inherit from ApplicationRecord won't have this method,
      # but they probably also won't have counter-caches either.
      if model_class.respond_to?(:counter_cache_column_names)
        except_columns.merge(model_class.counter_cache_column_names)
      end

      table_name_attr =
        ActiveRecord::Relation::QueryAttribute.new(
          "table_name",
          table_name,
          ActiveRecord::Type::String.new
        )

      except_cols_attr =
        ActiveRecord::Relation::QueryAttribute.new(
          "except_cols",
          PG::TextEncoder::Array.new.encode(except_columns.to_a.uniq),
          ActiveRecord::Type::String.new
        )

      reversible do |dir|
        dir.up do
          exec_update(
            "SELECT audit.enable_auditing($1, except_cols => $2::name[])",
            "Enable Auditing",
            [table_name_attr, except_cols_attr]
          )
        end

        dir.down do
          disable_auditing(table_name)
        end
      end
    end

    def disable_auditing(table_name)
      table_name_attr =
        ActiveRecord::Relation::QueryAttribute.new(
          "table_name",
          table_name,
          ActiveRecord::Type::String.new
        )

      exec_update(
        "SELECT audit.disable_auditing($1)",
        "Disable Auditing",
        [table_name_attr]
      )
    end
  end
end
