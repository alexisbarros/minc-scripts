require "net/http"
require 'json'

# Caminhos para os arquivos
pronacs_file = './data/pronacs.json'
output_file = './data/pronacs_with_id.json'
index_file = 'index.txt'

output_file_content = File.read(output_file)
output_data = JSON.parse(output_file_content)

def get_pronac_id(pronac_id)
  url = URI("https://salic.cultura.gov.br/navegacao/projeto-rest/?pronac=#{pronac_id}")
  response = Net::HTTP.get_response(url)
  
  if response.code != "200"
    return nil
  end

  JSON.parse(response.body)
end

def starts_with_number?(str)
  !!(str[0] =~ /\d/)
end

# Carregar pronacs
pronacs = JSON.parse(File.read(pronacs_file))

# Carregar o índice de onde parou
start_index = if File.exist?(index_file)
                File.read(index_file).to_i
              else
                0
              end

begin
  pronacs[start_index..-1].each_with_index do |data, idx|
    current_index = start_index + idx
    puts("#{current_index}/#{pronacs.length}")
    
    if starts_with_number?(data['Pronac'].strip)
      pronac = get_pronac_id(data['Pronac'])
      
      pronac_with_id = data
      pronac_with_id["Id Pronac"] = "#{pronac['projetos'][0]['idPronac']}"
      output_data << pronac_with_id

      # Salvar o índice atual
      File.write(index_file, current_index + 1)
      File.write(output_file, JSON.pretty_generate(output_data))
    end
  end

end