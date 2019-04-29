User.destroy_all

User.create do |user|
  user.name                  = "Super Admin"
  user.email                 = "admin@rubyforce.com"
  user.password              = "password"
  user.password_confirmation = "password"
  user.role                  = 'admin'
end

User.create do |user|
  user.name                  = "John Watson"
  user.email                 = "user@rubyforce.com"
  user.password              = "12345678"
  user.password_confirmation = "12345678"
end
