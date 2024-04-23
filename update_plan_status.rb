require "json"
require_relative "unit_functions"

json_file = File.read("files/data.json")
data = JSON.parse(json_file)

data_updated = []
data.each_with_index do |entity, index|
  result, rest = index.divmod(10)
  puts index if rest == 0

  plan_code = get_plan_code(entity["Link Plano de Ação"])
  
  plan = get_plan_data(plan_code)
  next if !plan

  report = get_report_data(plan[0]["id"])
  next if !report
  
  attachments = get_attachments(plan[0]["id"])

  data_updated << {
    "Código Plano de Ação": entity["Código Plano de Ação"],
    "Link Plano de Ação": entity["Link Plano de Ação"],
    "CNPJ Ente Recebedor": entity["CNPJ Ente Recebedor"],
    "UF Ente Recebedor": entity["UF Ente Recebedor"],
    "Ente Recebedor": entity["Ente Recebedor"],
    "Valor Total do Repasse": entity["Valor Total do Repasse"],
    "1. Enviou Relatório de Gestão para análise?": report["situacao"] ? "Sim" : "Não",
    "3. Preencheu o campo “Descritivo”?": report["parecer"] ? "Sim" : "Não",
    "9. Informou percentual de execução de cada meta/ação aprovada no plano de ação?": report["listaAcoes"].reduce do |acc, current|
      acc && current["percentualConculsao"] > 0 ? "Sim" : "Não"
    end,
    "11. Preencheu o campo “Resultados alcançados em cada meta”?": report["resultadosAlcancados"] ? "Sim" : "Não",
    "16. Informou link de transparência do Ente, que permita verificar a listagem dos beneficiários e os resultados das ações realizadas em formato online?": report["enderecoEletronico"] ? "Sim" : "Não",
    "17. Marcou checkbox de declaração de conhecimento?": report["inDeclaracaoConformidade"] ? "Sim" : "Não",
    "25. Informou contrapartidas realizadas?": report["contrapartida"] ? "Sim" : "Não",
    "Anexos": attachments.reduce("") do |acc, current|
      acc += "Descrição: #{current["descricao"]} | Arquivo: #{current["nome"]} \n"
    end, 
  }
  
  if rest == 0
    json_data_updated = JSON.pretty_generate(data_updated)
    
    File.open("files/data_updated.json", "w") do |file|
      file.write(json_data_updated)
    end
  end
end


puts "Updated list saved"