class CaseType < ActiveRecord::Base
  belongs_to :parent, class_name: 'CaseType', foreign_key: :parent_id
  has_many :children, class_name: 'CaseType', foreign_key: :parent_id

  def self.roots
    CaseType.where(parent_id: nil)
  end

  def self.replicate
    conn = Faraday.new(url: 'http://www.legalbistro.com')
    response = conn.get '/api/case-types/hierarchy'
    case_types_tree = JSON.parse(response.body)
    CaseType.create_from_json(case_types_tree)
    ActiveRecord::Base.connection.reset_pk_sequence!(CaseType.table_name)
  end

  def self.create_from_json(case_type_json)
    parent_id = case_type_json['parent'].present? ? case_type_json['parent']['id'] : nil
    begin
      case_type = CaseType.find(case_type_json['id'])
      case_type.update_attributes(name: case_type_json['name'], parent_id: parent_id)
    rescue ActiveRecord::RecordNotFound
      CaseType.create(id: case_type_json['id'], name: case_type_json['name'], parent_id: parent_id)
    end
    case_type_json['children'].each { |child| CaseType.create_from_json(child) }
  end

  def get_random_tags(char_limit)
    tags = []
    ActiveRecord::Base.connection.exec_query("SELECT * FROM UNNEST(get_case_tags(#{self.id},#{char_limit})) as tag").each do |row|
      tags.push(row['tag'])
    end
    return tags
  end

  def get_random_tags(char_limit, language_code)
    tags = []
    ActiveRecord::Base.connection.exec_query("SELECT * FROM UNNEST(get_case_tags(#{self.id},#{language_code},#{char_limit})) as tag").each do |row|
      tags.push(row['tag'])
    end
    return tags
  end

  def get_random_tags(char_limit, primary_language_code, primary_language_percentage, secondary_language_code, secondary_language_percentage)
    tags = []
    ActiveRecord::Base.connection.exec_query("SELECT * FROM UNNEST(get_case_tags(#{self.id},#{char_limit},'#{primary_language_code}',#{primary_language_percentage},'#{secondary_language_code}',#{secondary_language_percentage})) as tag").each do |row|
      tags.push(row['tag'])
    end
    return tags
  end

end
