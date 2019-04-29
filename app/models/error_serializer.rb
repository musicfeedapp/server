module ErrorSerializer

  def ErrorSerializer.serialize(errors, options={})
    return {} if errors.nil?

    {
      errors: errors.map do |key, message|
        {
          id: key,
          title: "#{key.to_s.humanize} " + [message].join(". ") + "."
        }
      end
    }
  end

end
