# coding: utf-8
module Usernameable
  def self.get(name)
    name.to_s
      .gsub(/[^а-яА-Яa-zA-Z0-9]/,"")
      .split(/ /)
      .join
  end

  def self.find(name)
    username = Usernameable.get(name)

    username_count = User.where(username: username).count

    unless username_count == 0
      username = "#{username}#{username_count + 1}"
    end

    username
  end
end
