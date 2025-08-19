require 'rails_helper'

RSpec.describe WeatherController, type: :controller do
  let(:valid_address) { "123 Main St, Seattle, WA" }
  let(:weather_data) do
    WeatherData.new(
      zip: "98101",
      location_name: "Seattle",
      location_region: "Washington",
      location_country: "United States",
      temperature_f: 75.0,
      temperature_c: 23.9,
      description: "Partly cloudy",
      humidity: 65.0,
      wind_speed: 5.2,
      icon_url: "http://cdn.weatherapi.com/weather/64x64/day/116.png"
    )
  end
  let(:command_double) { instance_double(GetWeatherByAddressCommand) }

  before do
    allow(GetWeatherByAddressCommand).to receive(:new).and_return(command_double)
  end

  describe "GET #index" do
    context "when address parameter is present" do
      before do
        allow(command_double).to receive(:execute).and_return(weather_data)
        get :index, params: { address: valid_address }
      end

      it "assigns weather data" do
        expect(assigns(:weather_data)).to eq(weather_data.to_h)
      end

      it "renders the index template" do
        expect(response).to render_template(:index)
      end
    end

    context "when address parameter is missing" do
      before do
        get :index
      end

      it "does not assign weather data" do
        expect(assigns(:weather_data)).to be_nil
      end

      it "renders the index template" do
        expect(response).to render_template(:index)
      end
    end

    context "when argument error occurs" do
      before do
        allow(command_double).to receive(:execute).and_raise(
          ArgumentError.new("Invalid address")
        )
        get :index, params: { address: valid_address }
      end

      it "sets error message" do
        expect(assigns(:error)).to eq("Invalid request: Invalid address")
      end
    end

    context "when general weather error occurs" do
      before do
        allow(command_double).to receive(:execute).and_raise(
          Weather::Errors::WeatherError.new("General error")
        )
        get :index, params: { address: valid_address }
      end

      it "sets error message" do
        expect(assigns(:error)).to eq("Weather error: General error")
      end
    end
  end

  describe "GET #show" do
    context "when address parameter is present" do
      before do
        allow(command_double).to receive(:execute).and_return(weather_data)
        get :show, params: { address: valid_address }
      end

      it "returns successful JSON response" do
        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq("application/json; charset=utf-8")
      end

      it "returns weather data with success status" do
        json_response = JSON.parse(response.body)
        expect(json_response["status"]).to eq("success")
        expect(json_response["weather"]["zip"]).to eq("98101")
        expect(json_response["weather"]["location_name"]).to eq("Seattle")
        expect(json_response["weather"]["temperature_f"]).to eq(75.0)
        expect(json_response).to have_key("timestamp")
      end
    end

    context "when address parameter is missing" do
      before do
        get :show
      end

      it "returns bad request status" do
        expect(response).to have_http_status(:bad_request)
      end

      it "returns error message" do
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("Please provide an 'address' parameter")
        expect(json_response["status"]).to eq("error")
        expect(json_response).to have_key("timestamp")
      end
    end

  end
end
