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

      @ontology = JSON.parse(URI.open(ENV['ONTOLOGY_URL']).read)
      @ontology_icons = ontology_icons_extract(@ontology)
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

  def valid_icon(icon, icons)
    return true if icon.start_with?('glyphicons')
    return true if icon.include?('teritorio-extra-')

    return false if icon.split(' ', 2)[0] != 'teritorio'
    return false if icon.split(' ', 2)[1].split('-', 2)[0] != 'teritorio'

    i = icon.split(' ', 2)[1].split('-', 2)[1]
    icons.include?(i)
  rescue StandardError => e
    false
  end

  def valid_style_class(style_class, ontology)
    c = ontology['superclass'][style_class[0]]['class'][style_class[1]]
    c['subclass'][style_class[2]] if style_class.size == 3
    true
  rescue StandardError => e
    false
  end

  def ontology_icons_extract(ontology)
    ontology['superclass'].collect{ |_id, superclass|
      (
        [_id] +
        superclass['class'].keys +
        superclass['class'].collect{ |_id, classes|
          classes['subclass']&.keys
        }
      )
    }.flatten.compact
  end

  def test_valid_menu
    url = "#{@api_url}/menu"
    json = URI.open(url).read
    assert json
    menu = JSON.parse(json)

    errors = menu.collect{ |menu_item|
      menu_item['category'] || menu_item['menu_group']
    }.compact.collect{ |category|
      id = category['id']
      if !category['icon']
        "#{id} missing icon"
      elsif !valid_icon(category['icon'], @ontology_icons)
        "#{id} invalid icon '#{category['icon']}'"
      elsif category['style_merge']
        if !category['style_class']
          "#{id} missing style_class"
        elsif !valid_style_class(category['style_class'], @ontology)
          "#{id} invalid style_class '#{category['style_class'].join(';')}'"
        end
      end
    }.compact

    assert errors.empty?, errors
  end

  def test_valid_pois
    url = "#{@api_url}/pois"
    json = URI.open(url).read
    assert json
    pois = JSON.parse(json)

    errors = []
    pois['features'].select{ |poi|
      icon = poi['properties']&.[]('display')&.[]('icon')
      if !icon || icon == ''
        errors << "POI missing icon (#{poi})"
        false
      else
        true
      end
    }.collect{ |poi|
      begin
        [poi['properties']['display']['icon'], poi['properties']['metadata']] if poi['properties']['display'].key?('icon')
      rescue StandardError
      end
    }.group_by{ |icon, _id| icon }.collect{ |icon, ids|
      error << "POI invalid icon '#{icon}' (#{ids.join(',')})" if !valid_icon(icon, @ontology_icons)
    }

    assert errors.empty?, errors
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
