require 'json'

# Lendo o arquivo JSON com os dados de entrada
input_file = 'proponentes_rs.json'
output_file = 'proponentes_rs_final.json'

locais = JSON.parse(File.read(input_file), symbolize_names: true)

# Remover duplicados com base no atributo :nome
locais_unicos = locais.uniq { |local| local[:CNPJCPF] }

# Salvando o novo JSON com os locais únicos
File.open(output_file, 'w') do |f|
  f.write(JSON.pretty_generate(locais_unicos))
end

puts "Dados únicos salvos em #{output_file}"
