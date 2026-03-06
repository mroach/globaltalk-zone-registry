class PublicEndpointValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank?

    return if DDNS.valid_fqdn?(value)
    return if DDNS.valid_ip?(value)

    record.errors.add(attribute, "is not a valid public endpoint")
  end
end
