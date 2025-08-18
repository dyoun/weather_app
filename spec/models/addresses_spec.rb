require 'rails_helper'

RSpec.describe Addresses, type: :model do
  let(:valid_attributes) do
    {
      address: "123 Main Street",
      city: "Seattle",
      state: "WA",
      zip: "98101"
    }
  end

  describe 'validations' do
    context 'presence validations' do
      it 'is valid with all required fields' do
        address = described_class.new(valid_attributes)
        expect(address).to be_valid
      end

      it 'is invalid without address' do
        address = described_class.new(valid_attributes.except(:address))
        expect(address).not_to be_valid
        expect(address.errors[:address]).to include("can't be blank")
      end

      it 'is invalid without city' do
        address = described_class.new(valid_attributes.except(:city))
        expect(address).not_to be_valid
        expect(address.errors[:city]).to include("can't be blank")
      end

      it 'is invalid without state' do
        address = described_class.new(valid_attributes.except(:state))
        expect(address).not_to be_valid
        expect(address.errors[:state]).to include("can't be blank")
      end

      it 'is invalid without zip' do
        address = described_class.new(valid_attributes.except(:zip))
        expect(address).not_to be_valid
        expect(address.errors[:zip]).to include("can't be blank")
      end
    end

    context 'zip code validations' do
      it 'is valid with 5-digit zip code' do
        address = described_class.new(valid_attributes.merge(zip: "12345"))
        expect(address).to be_valid
      end

      it 'is valid with leading zero zip code' do
        address = described_class.new(valid_attributes.merge(zip: "01234"))
        expect(address).to be_valid
      end

      it 'is invalid with 4-digit zip code' do
        address = described_class.new(valid_attributes.merge(zip: "1234"))
        expect(address).not_to be_valid
        expect(address.errors[:zip]).to include("Zip code must be a 5-digit number.")
      end
    end
  end

  describe '#to_h' do
    let(:address) { described_class.new(valid_attributes) }

    it 'returns a hash with all address attributes' do
      result = address.to_h

      expect(result).to be_a(Hash)
      expect(result[:address]).to eq("123 Main Street")
      expect(result[:city]).to eq("Seattle")
      expect(result[:state]).to eq("WA")
      expect(result[:zip]).to eq("98101")
    end
  end
end