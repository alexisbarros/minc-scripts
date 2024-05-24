require "net/http"

def get_plan_code(link)
  link_splited = link.split('detalhe/')
  link_splited[1].gsub('/dados-basicos', '')
end

def get_plan_data(plan_code)
  url = URI("https://fundos.transferegov.sistema.gov.br/maisbrasil-transferencia-backend/api/public/relatorio-gestao/plano-acao/#{plan_code}")
  response = Net::HTTP.get_response(url)
  
  if response.code != "200"
    return nil
  end

  JSON.parse(response.body)
end

def get_report_data(plan_id)
  url = URI("https://fundos.transferegov.sistema.gov.br/maisbrasil-transferencia-backend/api/public/relatorio-gestao/#{plan_id}")
  response = Net::HTTP.get_response(url)
  
  if response.code != "200"
    return nil
  end

  JSON.parse(response.body)
end

def get_attachments(plan_id)
  url = URI("https://fundos.transferegov.sistema.gov.br/maisbrasil-transferencia-backend/api/public/anexos/relatorio-gestao/#{plan_id}")
  response = Net::HTTP.get_response(url)
  
  if response.code != "200"
    return nil
  end

  JSON.parse(response.body)
end