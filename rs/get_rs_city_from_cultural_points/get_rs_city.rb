require 'net/http'
require 'json'
require 'uri'

API_KEY = 'AIzaSyDyFZN_eQ7p5xxgyRuxeW_lLZzdaZD2BPY'

def get_city(lat, lng)
  uri = URI("https://maps.googleapis.com/maps/api/geocode/json?latlng=#{lat},#{lng}&key=#{API_KEY}")
  res = Net::HTTP.get(uri)
  data = JSON.parse(res)
  
  if data['status'] == 'OK'
    data['results'].each do |result|
      result['address_components'].each do |component|
        if component['types'].include?('administrative_area_level_2')
          return component['long_name']
        end
      end
    end
  end

  nil
end

# Lendo o arquivo JSON com os dados de entrada
input_file = 'locals.json'
output_file = 'locals_with_city.json'

locais = JSON.parse(File.read(input_file))

locals_with_city = locais.map do |local|
  puts local['name']

  city = nil
  geo_location_exists = !!(local.dig('location', 'latitude').to_f.nonzero?)

  city = get_city(local['location']['latitude'], local['location']['longitude']) if geo_location_exists 
  local.merge('city' => city)
end

# Salvando o novo JSON com os bairros incluídos
File.open(output_file, 'w') do |f|
  f.write(JSON.pretty_generate(locals_with_city))
end

puts "Dados atualizados com bairros salvos em #{output_file}"
