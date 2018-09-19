module RegexPatterns
  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    def valid_email_pattern
      /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i
    end
  end
end
