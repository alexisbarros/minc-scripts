require 'net/http'
require 'json'
require 'uri'

API_URL = 'https://salic.cultura.gov.br/projeto/proponente-rest/idPronac/'
OUTPUT_FILE = 'proponentes_rs.json'
INDEX_FILE = 'index.txt'

def fetch_data(index)
  uri = URI("#{API_URL}#{index+1}")
  puts uri
  req = Net::HTTP::Get.new(uri)
  req['Cookie'] = "TS018d63b1=01ad2359817bbbf9ddf7a0f74e525d4af5151af1761eb8e2302401716a82cc3c1e7b434f7fd66608fd4b202cd51965666737f7114cd4478f6901c50af706631050d6d9705c33d7056a9d9dedefa8bd25fae3849bd4; BIGipServerSALIC_POOL=990619840.20480.0000; PHPSESSID=0b6f1fa52b640d7107933d76c4f525e3"

  res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') { |http|
    http.request(req)
  }
  
  JSON.parse(res.body)
rescue => e
  puts "Error fetching data: #{e.message}"
  nil
end

def save_data(data)
  if File.exist?(OUTPUT_FILE)
    existing_data = JSON.parse(File.read(OUTPUT_FILE))
  else
    existing_data = []
  end

  existing_data.append(data)
  File.open(OUTPUT_FILE, 'w') do |file|
    file.write(JSON.pretty_generate(existing_data))
  end
end

def get_current_index
  if File.exist?(INDEX_FILE)
    File.read(INDEX_FILE).to_i
  else
    0
  end
end

def save_current_index(index)
  File.open(INDEX_FILE, 'w') do |file|
    file.write(index.to_s)
  end
end

def run
  current_index = get_current_index
  last_index = 261473

  loop do
    response = fetch_data(current_index)
    break if current_index > last_index
    
    save_data(response['data']['dados']) if response.dig('data', 'dados', 'Uf') == 'RS'
    
    current_index += 1
    save_current_index(current_index)
  end

  puts "Script completed. Last index: #{current_index}"
end

run
