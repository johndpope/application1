require 'rails_helper'

shared_examples_for 'has paragraphs for' do |*topics|
  let(:model) { described_class }
  let(:item) { FactoryGirl.build(model.to_s.underscore.to_sym) }
  let(:paragraphs) { 2.times.map { FactoryGirl.build(:paragraph) } }

  it('#paragraphs') { expect(item).to respond_to(:paragraphs) }

  topics.each do |topic|
    it(topic) do
      accessor = "#{topic}_paragraphs"
      expect(item).to respond_to(accessor)
      item.send(accessor).clear
      paragraphs.each do |p|
        item.send(accessor).build(title: p.title, body: p.body)
      end
      expect(item.send(topic)).to eq(paragraphs.map(&:body).join("\n\n"))

      shuffled = item.send(topic, shuffle: true)
      paragraphs.each do |p|
        expect(shuffled).to include(p.body)
      end
      expect { item.save(validate: false) }.to change {
        Paragraph.where(resource_type: described_class, scope: topic).count
      }.by(2)
    end
  end
end
