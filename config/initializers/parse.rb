# Example:
#
# curl -X POST \\
# -H "X-Parse-Application-Id: myBFEJGswnzSaJRwLkAzhAf3FinZmNURf5BnOFd7" \\
# -H "X-Parse-REST-API-Key: 4GpyUtNshhbzKHbBJqw3A4tYh00AS1uGSG9IfvQA" \\
# -H "Content-Type: application/json" \\
# -d '{
#       "where": {
#         "userExtId": "alex.korsak@gmail.com"
#       },
#       "data": {
#         "alert": "Personal Push to user with userExtId=alex.korsak@gmail.com."
#       }
#     }' \\
# https://api.parse.com/1/push
#
require 'parse-ruby-client'

if Rails.env.production?
  Parse.init :application_id => "myBFEJGswnzSaJRwLkAzhAf3FinZmNURf5BnOFd7",
             :api_key        => "4GpyUtNshhbzKHbBJqw3A4tYh00AS1uGSG9IfvQA"
end
