require "net/http"
require 'json'

# Caminhos para os arquivos
pronacs_file = './data/pronacs_with_id.json'
output_file = './data/pronacs_with_id_and_files_info.json'
index_file = 'index.txt'

output_file_content = File.read(output_file)
output_data = JSON.parse(output_file_content)

def get_pronac_file_info(pronac_id)
  uri = URI("https://salic.cultura.gov.br/prestacao-contas/relatorio-cumprimento-objeto-rest/index?idPronac=#{pronac_id}")
  req = Net::HTTP::Get.new(uri)
  req['Cookie'] = "TS018d63b1=01ad235981ebc6bd719acc9082bd800f7f05181c5060d13ee19753fe6fe9fe55832c6f977293eef07423a7248782ba9cd7ea4cdfb0a424f70b58fb0e91a6a53f5e7b311ea46d0f0052a5a08b3751e09c56d1ec5342; PHPSESSID=f9963be21d036e42aaa291e297b22ff6; BIGipServerSALIC_POOL=990619840.20480.0000"

  response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') { |http|
    http.request(req)
  }
  
  if response.code != "200"
    return nil
  end

  JSON.parse(response.body)
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
    
    pronac = get_pronac_file_info(data['Id Pronac'])
    puts pronac.dig('data', 'items').is_a?(Array)
    pronac_with_files_info = data
    pronac_with_files_info["Arquivos"] = {}
    if pronac.dig('data', 'items').is_a?(Array)
      pronac_with_files_info["Arquivos"]["Plano De Divulgacao"] = []
      pronac_with_files_info["Arquivos"]["Comprovantes"] = []
    else
      pronac_with_files_info["Arquivos"]["Plano De Divulgacao"] = pronac.dig('data', 'items', "planoDeDivulgacao") || []
      pronac_with_files_info["Arquivos"]["Comprovantes"] = pronac.dig('data', 'items', "dadosComprovantes") || []
    end
    output_data << pronac_with_files_info

    # Salvar o índice atual
    File.write(index_file, current_index + 1)
    File.write(output_file, JSON.pretty_generate(output_data))
  end

end