class TimeZoneValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.nil?

    TZInfo::Timezone.get(value)
  rescue TZInfo::InvalidTimezoneIdentifier
    record.errors.add(attribute, "is not a valid IANA time zone identifer")
  end
end
