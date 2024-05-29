require 'nokogiri'
require 'httparty'
require 'json'

# Função para buscar o conteúdo da tag <p> abaixo da tag <h3> com o conteúdo "Logradouro"
def fetch_logradouro_content(url)
  response = HTTParty.get(url)
  if response.code == 200
    document = Nokogiri::HTML(response.body)

    address = ""
    city = nil
    ['Logradouro', 'Número', 'Bairro', 'Município'].map do |title|
      tag_h3 = document.at_xpath("//h3[text()='#{title}']")
      
      if tag_h3
        tag_p = tag_h3.at_xpath("following-sibling::p")
        address = address + " " + (tag_p ? tag_p.text : "")
        city = (tag_p ? tag_p.text : "") if title == 'Município'
      end
    end
    { address: address, city: city }
  else
    puts "Erro ao acessar a URL: #{response.code}"
    { address: nil, city: nil }
  end
end

# Lendo o arquivo JSON com os dados de entrada
input_file = './data/museum.json'

locals = JSON.parse(File.read(input_file))

index = 0
locals_to_save = locals.map do |local|
  puts local['name']

  full_address = fetch_logradouro_content(local['link'])
  puts full_address

  index = index + 1
  {
    "id": local['id'],
    "name": local['name'],
    # "location": local['location'],
    "shortDescription": "Museu | Telefone: #{local['phone']} | Email: #{local['email']}",
    "terms": {
      "tag": [],
      "area": []
    },
    "type": {"id": 2, "name": "Coletivo"},
    "endereco": full_address[:address],
    "city": full_address[:city]
  }
end

# Salvando o novo JSON com os bairros incluídos
File.open('./data/museum_with_address.json', 'w') do |f|
  f.write(JSON.pretty_generate(locals_to_save))
end

puts "Script finalizado"
