require 'minitest/autorun'
require 'open-uri'
require 'openapi3_parser'
require 'json-schema'
require 'json'


class ApiTest < Minitest::Test
  def setup
    # https://dev.appcarto.teritorio.xyz/content/wp-content/plugins/ApiTeritorio/swagger-doc.yaml
    @yaml_url = ENV.fetch('SWAGGER_URL', nil)

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

      @ontology = JSON.parse(URI.open(ENV.fetch('ONTOLOGY_URL', nil)).read)
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
    url = "#{@api_url}/settings.json"
    json = URI.open(url).read
    assert json
    JSON.parse(json)
  end

  def ontology_icons_extract(ontology)
    h = Hash.new{ |hash, key| hash[key] = [] }
    ontology['superclass'].collect{ |id, superclass|
      h[[superclass['color_fill'], superclass['color_line']]] += (
        [id] +
        superclass['class'].keys +
        superclass['class'].collect{ |_id, classes|
          classes['subclass']&.keys
        }
      ).flatten.compact
    }

    # h.each{ |c, icons|
    #   color_fill, color_line = c
    #   icons.each{ |icon|
    #     puts "UPDATE wp_postmeta JOIN wp_postmeta AS wp_postmeta_icon SET wp_postmeta.meta_value = '#{color_fill}' WHERE wp_postmeta_icon.meta_key = 'icon' AND wp_postmeta_icon.meta_value = 'teritorio teritorio-#{icon}' AND wp_postmeta_icon.post_id = wp_postmeta.post_id AND wp_postmeta.meta_key = 'color';"
    #     puts "UPDATE wp_postmeta JOIN wp_postmeta AS wp_postmeta_icon SET wp_postmeta.meta_value = '#{color_line}' WHERE wp_postmeta_icon.meta_key = 'icon' AND wp_postmeta_icon.meta_value = 'teritorio teritorio-#{icon}' AND wp_postmeta_icon.post_id = wp_postmeta.post_id AND wp_postmeta.meta_key = 'color_text';"
    #   }
    # }

    # h.each{ |c, icons|
    #   color_fill, color_line = c
    #   icons.each{ |icon|
    #     puts "UPDATE sp_menuniveau3 SET color = '#{color_fill};#{color_line}' WHERE icon = 'teritorio teritorio-#{icon}';"
    #   }
    # }

    h
  end

  def valid_icon(icon, ontology_icons)
    return true if icon.start_with?('glyphicons')
    return true if icon.include?('teritorio-extra-')

    return false if icon.split(' ', 2)[0] != 'teritorio'
    return false if icon.split(' ', 2)[1].split('-', 2)[0] != 'teritorio'

    i = icon.split(' ', 2)[1].split('-', 2)[1]
    ontology_icons.values.flatten.include?(i)
  rescue StandardError
    false
  end

  def valid_color(color_fill, color_line, icon, ontology_icons)
    return true if icon.start_with?('glyphicons')
    return true if icon.include?('teritorio-extra-')

    ontology_icons.include?([color_fill, color_line])
  rescue StandardError
    false
  end

  def valid_color_icon(color_fill, color_line, icon, ontology_icons)
    return true if icon.start_with?('glyphicons')
    return true if icon.include?('teritorio-extra-')

    return false if icon.split(' ', 2)[0] != 'teritorio'
    return false if icon.split(' ', 2)[1].split('-', 2)[0] != 'teritorio'

    i = icon.split(' ', 2)[1].split('-', 2)[1]
    ontology_icons[[color_fill, color_line]].include?(i)
  rescue StandardError
    false
  end

  def valid_style_class(style_class, ontology)
    c = ontology['superclass'][style_class[0]]['class'][style_class[1]]
    c['subclass'][style_class[2]] if style_class.size == 3
    true
  rescue StandardError
    false
  end

  def test_valid_menu
    url = "#{@api_url}/menu.json"
    json = URI.open(url).read
    assert json
    menu = JSON.parse(json)

    errors = menu.collect{ |menu_item|
      menu_item['category'] || menu_item['menu_group']
    }.compact.collect{ |category|
      id = category['id']
      err = []

      err << (
        if !category['color_fill'] || !category['color_line']
          "#{id} missing color fill or line"
        elsif !category['icon']
          "#{id} missing icon"
        elsif !valid_icon(category['icon'], @ontology_icons)
          "#{id} invalid icon '#{category['icon']}'"
        elsif !valid_color(category['color_fill'].downcase, category['color_line'].downcase, category['icon'], @ontology_icons)
          "#{id} invalid colors '#{category['color_fill']}, #{category['color_line']}' ('#{category['icon']}')"
        elsif !valid_color_icon(category['color_fill'].downcase, category['color_line'].downcase, category['icon'], @ontology_icons)
          "#{id} invalid cople (color_fill, color_line, icon) ('#{category['color_fill']}, '#{category['color_line']}', '#{category['icon']}')"
        end
      )

      err << (
        if category['style_merge']
          if !category['style_class']
            "#{id} missing style_class"
          elsif !valid_style_class(category['style_class'], @ontology)
            "#{id} invalid style_class '#{category['style_class'].join(';')}'"
          end
        end
      )

      err
    }.flatten.compact

    assert errors.empty?, errors.join("\n")
  end

  def test_valid_pois
    url = "#{@api_url}/pois.geojson"
    json = URI.open(url).read
    assert json
    pois = JSON.parse(json)

    errors = []
    features = pois['features'].select{ |poi|
      icon = poi['properties']&.[]('display')&.[]('icon')
      if !icon || icon == ''
        errors << "POI missing icon (#{poi})"
        false
      else
        true
      end
    }.collect{ |poi|
      begin
        if poi['properties']['display'].key?('icon')
          [
            poi['properties']['display']['icon'],
            poi['properties']['display']['color_fill'],
            poi['properties']['display']['color_line'],
            poi['properties']['metadata']
          ]
        end
      rescue StandardError
      end
    }

    features.group_by{ |icon, _color_fill, _color_line, _id| icon }.collect{ |icon, ids|
      errors << "POI invalid icon '#{icon}' (#{ids.join(',')})" if !valid_icon(icon, @ontology_icons)
    }
    features.group_by{ |icon, color_fill, color_line, _id| [icon, color_fill, color_line] }.collect{ |colors, _ids|
      if !valid_color(colors[1].downcase, colors[2].downcase, colors[0], @ontology_icons)
        errors << "POI invalid colors for icon '#{colors}'"
      end
    }

    assert errors.empty?, errors.join("\n")
  end

  def test_valid_pois_from_menu
    url_menu = "#{@api_url}/menu.json"
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

  def deep_label_translation(items, translations)
    errors = []
    items.each{ |item|
      group = item['group']
      if group
        if !translations.dig(group, 'label', 'fr')
          errors << "POI missing translation group label #{group}.label.fr"
        end

        errors += deep_label_translation(item['fields'], translations)
      elsif item['label']
        field = item['field']
        if !translations.dig(field, 'label', 'fr')
          errors << "POI missing translation field label #{field}.label.fr"
        end
      end
    }
    errors
  end

  def key_value_translation(key, value, translations)
    if !translations.dig(key, 'values', value, 'label', 'fr')
      "POI missing translation field value #{key}.values.#{value}.label.fr"
    end
  end

  def test_valid_pois_translations
    url = "#{@api_url}/pois.geojson"
    json = URI.open(url).read
    assert json
    pois = JSON.parse(json)

    url = "#{@api_url}/attribute_translations/fr.json"
    json = URI.open(url).read
    assert json
    translations = JSON.parse(json)

    errors = []

    # Key
    errors += pois['features'].collect{ |poi|
      popup_fields = poi.dig('properties', 'editorial', 'popup_fields')
      details_fields = poi.dig('properties', 'editorial', 'details_fields')
      (popup_fields || []) + (details_fields || [])
    }.collect{ |items|
      deep_label_translation(items, translations)
    }.flatten(1).uniq

    # Value
    values_keys = [/route:[^:]+:difficulty/]
    errors += pois['features'].collect{ |poi|
      keys = poi['properties'].keys.select{ |key| values_keys.find{ |match| match.match?(key) } }
      keys.collect{ |key|
        key_value_translation(key, poi['properties'][key], translations)
      }.compact
    }.flatten(1).uniq

    assert errors.empty?, errors.join("\n")
  end
end
