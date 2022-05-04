require 'minitest/autorun'
require 'open-uri'
require 'openapi3_parser'
require 'json-schema'
require 'json'


class ApiTest < Minitest::Test
  def setup
    # https://dev.appcarto.teritorio.xyz/content/wp-content/plugins/ApiTeritorio/swagger-doc.yaml
    @yaml_url = ENV['SWAGGER_URL']

    begin
      yaml = URI.open(@yaml_url).read
      document = Openapi3Parser.load(yaml)
      # https://dev.appcarto.teritorio.xyz/content/wp-content/plugins/ApiTeritorio/../../../api.teritorio/geodata/v0.1
      @api_url = @yaml_url.split('/')[0..-2].join('/') + '/' + document[:servers][0][:url] + '/a/b'

      # Simplfiy relative URL
      prev_api_url = nil
      while prev_api_url != @api_url
        prev_api_url = @api_url
        @api_url = @api_url.gsub(%r{/[^/]*/../}, '/')
      end
    rescue StandardError
    end
  end

  def test_valid_swagger_spec
    puts @yaml_url
    yaml = URI.open(@yaml_url).read
    document = Openapi3Parser.load(yaml)
    assert !document.valid?, document.errors
  end

  def test_valid_settings
    url = "#{@api_url}/"
    json = URI.open(url).read
    assert json
    JSON.parse(json)
  end

  def test_valid_menu
    url = "#{@api_url}/menu"
    json = URI.open(url).read
    assert json
    JSON.parse(json)
  end

  def test_valid_pois
    url = "#{@api_url}/pois"
    json = URI.open(url).read
    assert json
    JSON.parse(json)
  end

  def test_valid_pois_from_menu
    url_menu = "#{@api_url}/menu"
    json_menu = URI.open(url_menu).read
    menu = JSON.parse(json_menu)

    menu.select{ |entry|
      entry['category']
    }.each{ |entry|
      id = entry['category']['id']
      url = "#{@api_url}/pois?idmenu=#{id}&as_point=true&short_description=true"
      puts [entry['category']['name'], url].inspect
      json = URI.open(url).read
      assert json
    }
  end
end
