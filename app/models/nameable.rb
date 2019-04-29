module Nameable

  def self.included(base)
    base.class_eval do
      before_save do
        write_attribute(:name, name)
      end

      def name
        read_attribute(:name) ||
          [first_name.to_s, last_name.to_s, middle_name.to_s]
        .map(&:strip)
        .reject(&:blank?)
        .join(' ')
      end

      def name=(full_name)
        names = full_name.to_s.split(/ /)
        self.first_name  = names[0]
        self.last_name   = names[1]
        self.middle_name = names[2]

        write_attribute(:name, full_name)
      end
    end
  end

end
