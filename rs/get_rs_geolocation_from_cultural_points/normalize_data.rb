require 'json'

# Lendo o arquivo JSON com os dados de entrada
input_file = './data/locals_with_coordinates.json'
output_file = './data/locals_normalized.json'

locals = JSON.parse(File.read(input_file))

index = 0
locals_to_save = locals.map do |local|
  puts local['name']
  index = index + 1
  {
    "id": index,
    "name": local['name'],
    "location": local['location'],
    "shortDescription": "Ponto de cultura | Telefone: #{local['phone']} | Email: #{local['email']}",
    "terms": {
      "tag": [],
      "area": []
    },
    "type": {"id": 2, "name": "Coletivo"},
    "endereco": local["address"],
    "city": local['city']
  }
end

# Salvando o novo JSON com os bairros incluídos
File.open(output_file, 'w') do |f|
  f.write(JSON.pretty_generate(locals_to_save))
end

puts "Script finalizado"
