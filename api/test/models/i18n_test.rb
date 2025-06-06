require "test_helper"

class I18nTest < ActiveSupport::TestCase
  test 'model names should be localized to Spanish' do
    ApplicationRecord.descendants.each do |klass|
      assert_not_equal klass.model_name.human(locale: :es),
        klass.model_name.human
    end
  end

  test 'attribute names should be localized to Spanish' do
    skip_set = ['created_at', 'id', 'updated_at'].to_set
    non_default_locales = I18n.available_locales - [I18n.default_locale]

    ApplicationRecord.descendants.each do |klass|
      klass.new.attributes.keys.each do |attribute|
        key = attribute.delete_suffix '_id'
        next if skip_set.include? key

        non_default_locales.each do |locale|
          assert_not_equal klass.human_attribute_name(key, locale:),
            klass.human_attribute_name(key)
        end
      end
    end
  end
end
