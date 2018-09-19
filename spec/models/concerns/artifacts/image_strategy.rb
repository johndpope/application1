require 'rails_helper'

shared_examples_for 'image artifact strategy' do

  before(:all) { @query = 'skyline' }

  it 'extends the Artifacts::Image model' do
    image = described_class.new
    expect(image).to be_a(Artifacts::Image)
  end

  describe '.list' do
    it "performs a search through the API", vcr: true do
      expect(described_class).to respond_to(:list)
      result = described_class.list(q: @query)
      expect(result[:total]).to_not be_nil
      items = result[:items]
      expect(items.count <= Artifacts::Image::DEFAULTS[:limit]).to eq(true)
      item = items.shuffle.first
      expect(item).to be_a(described_class)
      %w(source_id url page_url).each do |attribute|
        expect(item.send(attribute)).to_not be_blank
      end
    end

    it "retreives up to #{limit = Artifacts::Image::LIMITS.last} records", vcr: true do
      result = described_class.list(q: @query, limit: limit)
      expect(result[:items].size).to be <= limit
    end
  end

  describe '#import', vcr: true do

    context 'when source_id is present' do
      before(:all) do
        @image = nil
        VCR.use_cassette("#{described_class.to_s}.list(q: #{@query}, limit: 3)") do
          result = described_class.list(q: @query, limit: 3)
          @image = described_class.new(source_id: result[:items].first.source_id)
        end
        VCR.use_cassette("#{described_class.to_s}-#{@image.source_id}#import") do
          @image.import
        end
      end

      it("saves the file to disk") { expect(@image.file).to exist }

      it('retreives author\'s details') { expect(@image.author).to_not be_nil }

      it('becomes an existing image') { expect(@image).to exist }

      it('saves the URL') { expect(@image.reload.url).to_not be_blank }

      it('saves the page URL') { expect(@image.reload.page_url).to_not be_blank }

      it('saves the title of the image') { expect(@image.reload.title).to_not be_blank }

      it('saves the source tags') { expect(@image.source_tag_list).to be_any }

      it('sets the metadata comment') do
        comment = @image.metadata['Properties']['comment']
        expect(comment).to eq("Artifacts::Image##{@image.id}")
      end

      it 'saves license information' do
        expect(@image.license_code || @image.license_name).to be_present
      end
    end

    context 'when source_id is undefined' do
      it 'raises an ArgumentError' do
        image = described_class.new
        image.source_id = nil
        expect { image.import }.to raise_error(ArgumentError)
      end
    end
  end

  describe '.recent_downloads' do
    before do
      Artifacts::Image.delete_all
      FactoryGirl.create_list(:artifacts_image, 3, type: described_class.to_s)
    end

    it 'counts records where `file_updated_at` falls into given interval' do
      expect(described_class.recent_downloads(1.minute)).to eq(3)
      image = described_class.first
      image.update_attribute(:file_updated_at, 1.hour.ago)
      expect(described_class.recent_downloads(1.minute)).to eq(2)
      expect(described_class.recent_downloads(2.hours)).to eq(3)
      # It does not include records with missing files
      image.update_attribute(:file, nil)
      expect(described_class.recent_downloads(2.hours)).to eq(2)
    end
  end
end
