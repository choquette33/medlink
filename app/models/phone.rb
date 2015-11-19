class Phone < ActiveRecord::Base
  belongs_to :user

  before_save { |rec| rec.condensed = Phone.condense rec.number }

  # FIXME: number should be immutable entirely, but that doesn't play nice with nested_attributes
  validates :condensed, uniqueness: true, on: :create

  def has_country_code
    unless number.start_with? '+'
      @errors.add :number, "should include a country code (e.g. +1 for the US)"
    end
  end
  validate :has_country_code

  def self.condense number
    number.gsub(/[^+\d]/, '')
  end

  def self.for number:
    normalized = condense number
    normalized = "+#{normalized}" unless normalized.start_with? "+"
    if found = Phone.find_by_condensed(normalized)
      found
    else
      Phone.create! number: number, condensed: normalized
    end
  end
end
