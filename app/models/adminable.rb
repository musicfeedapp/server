module Adminable
  DEFAULT_ADMINS = [
    'alex.korsak@gmail.com',
    'hanna.korsak@gmail.com',
    'tyronetranmer@gmail.com',
    'awais545@gmail.com'
  ]

  def self.included(base)
    base.class_eval do
      before_save :setup_default_admins

      # We will provide access to background processing, admin, db pages
      def setup_default_admins
        if DEFAULT_ADMINS.include?(email)
          self.role = 'admin'
        else
          self.role = 'user'
        end
      end
    end
  end

end
