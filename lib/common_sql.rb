module CommonSql
  def sql_increment!(attributes)
    values = []

    collection = Array(attributes).map do |attribute|
      values.push(attribute[:by])
      "#{attribute[:name]} = COALESCE(#{attribute[:name]}, 0) + ?"
    end

    self.class.where(id: id).update_all([collection.join(','), *values])

    reload
  end
end
