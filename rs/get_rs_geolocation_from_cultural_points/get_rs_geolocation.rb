require 'net/http'
require 'json'
require 'uri'

API_KEY = 'AIzaSyDyFZN_eQ7p5xxgyRuxeW_lLZzdaZD2BPY'

def get_coordinates(address)
  uri = URI("https://maps.googleapis.com/maps/api/geocode/json?address=#{URI::Parser.new.escape(address)}&key=#{API_KEY}")
  res = Net::HTTP.get(uri)
  data = JSON.parse(res)
  
  if data['status'] == 'OK'
    location = data['results'][0]['geometry']['location']
    { location: {latitude: location['lat'], longitude: location['lng'] } }
  else
    { location: {latitude: nil, longitude: nil } }
  end
end

# Lendo o arquivo JSON com os dados de entrada
input_file = './data/locals.json'
output_file = './data/locals_with_coordinates.json'

locals = JSON.parse(File.read(input_file))

index = 0
locals_to_save = locals.map do |local|
  index = index + 1
  puts "#{index}: #{local['name']}"
  coordinates = get_coordinates(local["address"])
  local['type'] = 'Pontos de cultura'
  local.merge(coordinates)
end

# Salvando o novo JSON com os bairros incluídos
File.open(output_file, 'w') do |f|
  f.write(JSON.pretty_generate(locals_to_save))
end

puts "Script finalizado"
