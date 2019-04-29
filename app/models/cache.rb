require 'json'

module Cache
  extend self

  def set(key, value, options = {})
    key = namespaced(key)

    $redis.pipelined do
      $redis.set(key, value)

      timeout = options[:expires_in]

      if timeout.present?
        $redis.expire(key, timeout)
      end
    end
  end

  def get(key)
    key = namespaced(key)

    $redis.get(key)
  end

  def remove(key)
    key = namespaced(key)

    $redis.del(key)
  end

  def namespaced(key)
    "ch:#{key}"
  end

  def clear(pattern = nil)
    if pattern
      match = "ch:#{pattern}:*"
    else
      match = "ch:*"
    end


    $redis.scan_each(match: match) do |key|
      $redis.del(key)
    end
  end
end
