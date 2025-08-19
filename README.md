# Rails Weather App

rails application that retrieves weather information based on an address using SOLID principles and enterprise design patterns.

addresses/location are normalized using [OpenStreetMaps](https://nominatim.openstreetmap.org/ui/search.html?q=space+needle) and include a zip code.

weather information is retrieved from [OpenWeather API](https://www.weatherapi.com/api-explorer.aspx#forecast)

## Quickstart
```shell
# pre-requisites: ruby 3.4.5
bundle install
OPEN_WEATHER_API_KEY= ./bin/rails server
# http://127.0.0.1:3000/

# alternatively
docker build -t rails-weather-app .
docker run -e OPEN_WEATHER_API_KEY= -e RAILS_MASTER_KEY=$(cat config/master.key) -p 3000:3000 rails-weather-app
# http://127.0.0.1:3000/
```

## Architecture

weather data is cached for 30 minutes by zipcode

### [SOLID Principles](https://en.wikipedia.org/wiki/SOLID)

* single responsibility principle: each class a single responsibility
  * `WeatherService` - weather API
  * `GeocodingService` - address normalization
  * `WeatherRepository` - coordinates data retrieval
  * `WeatherController` - handles HTTP requests

* open/closed principle: open for extension, closed for modification
  * open for extension by implementing interfaces, private methods to prevent modifications
    * `WeatherServiceInterface` and `GeocodingServiceInterface` define interfaces
  * interface design allows for easy service swapping

* liskov substitution principle: implementations are substitutable by their interfaces
  * weather and address services can be substituted in `WeatherRepository`
  * any weather/address service implementing `WeatherServiceInterface` or `GeocodingServiceInterface` can be used

* interface segregation principle: focused, specific interfaces
  * separate interfaces for weather/address services
  * no dependencies on unused methods

* dependency inversion principle: high level modules don't depend on low level modules
  * repository class `WeatherRepository` abstracts data access
  * services are injected as dependencies


### [Design Patterns](https://en.wikipedia.org/wiki/Design_Patterns)
* repository pattern
  * `WeatherRepository` isolates data access and separate concerns by keeping application logic separate
* command pattern
  * `GetWeatherByAddressCommand` decouples sender of request from receiver providing more flexibility
* strategy pattern
  * `WeatherRepository` separate concerns as services and make them interchangeable allowing flexibility
* factory pattern
  * `GetWeatherByAddressCommand` client doesn't create objects directly


### UML Diagram
```mermaid
classDiagram
    class WeatherController {
        +index()
        +show()
        -render_weather_by_address()
        -get_weather_by_address()
        -render_missing_parameters()
        -render_success_response()
    }
    
    class GetWeatherByAddressCommand {
        -address: string
        +execute() WeatherData
        -repository() WeatherRepository
        -weather_service() WeatherService
        -address_service() AddressService
    }
    
    class WeatherRepository {
        -weather_service: WeatherServiceInterface
        -address_service: AddressServiceInterface
        +initialize(weather_service, address_service)
        +find_weather_by_address(address) WeatherData
    }
    
    class WeatherServiceInterface {
        <<interface>>
        +get_weather_by_zip(zip) WeatherData
    }
    
    class AddressServiceInterface {
        <<interface>>
        +address_lookup(address) Addresses
    }
    
    class OpenWeatherMapService {
        -api_key: string
        -http_client: Faraday
        +get_weather_by_zip(zip) WeatherData
        -validate(zip)
        -fetch_weather_data(zip)
        -parse_weather_response(response, zip)
    }
    
    class OpenStreetMapService {
        -http_client: Faraday
        +address_lookup(address) Addresses
        -validate_address(address)
        -fetch_address(address)
        -parse_response(response, address)
    }
    
    class WeatherData {
        +to_h() Hash
    }
    
    class Addresses {
        +to_h() Hash
    }
    
    %% Relationships
    WeatherController --> GetWeatherByAddressCommand : uses
    GetWeatherByAddressCommand --> WeatherRepository : creates/uses
    WeatherRepository --> WeatherServiceInterface : depends on
    WeatherRepository --> AddressServiceInterface : depends on
    OpenWeatherMapService --|> WeatherServiceInterface : implements
    OpenStreetMapService --|> AddressServiceInterface : implements
    WeatherRepository --> WeatherData : returns
    WeatherRepository --> Addresses : uses
    OpenWeatherMapService --> WeatherData : creates
    OpenStreetMapService --> Addresses : creates
    GetWeatherByAddressCommand --> OpenWeatherMapService : instantiates
    GetWeatherByAddressCommand --> OpenStreetMapService : instantiates
    
    %% Design Patterns
    note for GetWeatherByAddressCommand "Command Pattern"
    note for WeatherRepository "Repository Pattern"
    note for WeatherServiceInterface "Strategy Pattern"
    note for AddressServiceInterface "Strategy Pattern"
```
