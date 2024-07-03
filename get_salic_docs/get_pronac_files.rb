require "net/http"
require 'json'

# Caminhos para os arquivos
pronacs_file = './data/pronacs_with_id_and_files_info.json'
index_file = 'index.txt'

def get_file(file_id, file_path)
  uri = URI("https://salic.cultura.gov.br/upload/abrir?id=#{file_id}")
  req = Net::HTTP::Get.new(uri)
  req['Cookie'] = "TS018d63b1=01ad235981ebc6bd719acc9082bd800f7f05181c5060d13ee19753fe6fe9fe55832c6f977293eef07423a7248782ba9cd7ea4cdfb0a424f70b58fb0e91a6a53f5e7b311ea46d0f0052a5a08b3751e09c56d1ec5342; PHPSESSID=f9963be21d036e42aaa291e297b22ff6; BIGipServerSALIC_POOL=990619840.20480.0000"

  response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') { |http|
    http.request(req)
  }
  
  if response.code == "200"
    File.open("files/#{file_path}", 'wb') do |file|
      file.write(response.body)
    end
  end
end

# Carregar pronacs
all_pronacs = JSON.parse(File.read(pronacs_file))
pronacs = all_pronacs.select{ |item| item["Arquivos"]["Plano De Divulgacao"].any? ||  item["Arquivos"]["Comprovantes"].any? }

# Carregar o índice de onde parou
start_index = if File.exist?(index_file)
                File.read(index_file).to_i
              else
                0
              end

pronacs[start_index..-1].each_with_index do |data, idx|
  current_index = start_index + idx
  puts("#{current_index}/#{pronacs.length}")
  
  system 'rm', '-rf', "files/#{data['Pronac']}"
  system 'mkdir', '-p', "files/#{data['Pronac']}/Plano de Divulgação"
  system 'mkdir', '-p', "files/#{data['Pronac']}/Comprovantes"

  plans = data["Arquivos"]["Plano De Divulgacao"].select{ |item| !item['idDocumento'].nil? }
  plans.each do |plan|
    get_file(plan["idDocumento"], "#{data['Pronac']}/Plano de Divulgação/#{plan["nmArquivo"]}")
  end
  
  comps = data["Arquivos"]["Comprovantes"].select{ |item| !item['idArquivo'].nil? }
  comps.each do |comp|
    get_file(comp["idArquivo"], "#{data['Pronac']}/Comprovantes/#{comp["nmArquivo"]}")
  end

  # Salvar o índice atual
  File.write(index_file, current_index + 1)
end