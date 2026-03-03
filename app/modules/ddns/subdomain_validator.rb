module DDNS
  class SubdomainValidator < ActiveModel::EachValidator
    def validate_each(record, attribute, value)
      return if value.nil?
      return if DDNS.valid_name_part?(value)

      record.errors.add(attribute, "not a valid subdomain for DDNS")
    end
  end
end
