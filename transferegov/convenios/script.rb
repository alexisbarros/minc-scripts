require 'selenium-webdriver'
require 'webdrivers'
require 'json'

# Caminhos para os arquivos
links_file = 'convenios.json'
output_file = 'convenios_resultado.json'
index_file = 'index.txt'

# Carregar links
links = JSON.parse(File.read(links_file))

# Carregar o índice de onde parou
start_index = if File.exist?(index_file)
                File.read(index_file).to_i
              else
                0
              end

# Inicializar o driver do Selenium
options = Selenium::WebDriver::Chrome::Options.new
options.add_argument('--headless')
driver = Selenium::WebDriver.for :chrome, options: options

output_data = []

begin
  links[start_index..-1].each_with_index do |data, idx|
    link = "http://convenios.gov.br/siconv/ConsultarProposta/ResultadoDaConsultaDeConvenioSelecionarConvenio.do?sequencialConvenio=#{data['NÚMERO CONVÊNIO']}&Usr=guest&Pwd=guest"
    current_index = start_index + idx

    puts("#{current_index}/#{links.length}")
    # Navegar até o link
    driver.navigate.to link

    # Esperar que a página carregue
    wait = Selenium::WebDriver::Wait.new(timeout: 3)
    
    begin
      # Clicar no primeiro span Prestação de contas
      first_span = wait.until { driver.find_element(:xpath, "//span[text()='Prestação de Contas']") }
      first_span.click

      # Clicar no segundo span Prestação de contas
      second_span = wait.until { driver.find_element(:xpath, "(//span[text()='Prestação de Contas'])[2]") }
      second_span.click
    rescue Selenium::WebDriver::Error::NoSuchElementError, Selenium::WebDriver::Error::TimeoutError
      puts "Não foi possível encontrar 'Prestação de contas' em #{link}"
      output_data << {
        id: data['NÚMERO CONVÊNIO'],
        link: link,
        nota_de_risco: '',
        ocorrencia_de_trilhas: '',
        parecer_situacao: '',
        parecer_descricao: '',
        parecer_tem_anexo: '',
      }
      File.write(index_file, current_index + 1)
      File.write(output_file, JSON.pretty_generate(output_data))
      next
    end

    begin
      # Extrair Nota de Risco
      nota_de_risco_span = wait.until { driver.find_element(:xpath, "//span[text()='Nota de Risco']/following-sibling::span[1]") }
      nota_de_risco_value = nota_de_risco_span.text
    rescue Selenium::WebDriver::Error::NoSuchElementError, Selenium::WebDriver::Error::TimeoutError
      nota_de_risco_value = ''
    end

    begin
      # Extrair Ocorrência de Trilhas de Auditoria
      ocorrencia_de_trilhas_span = wait.until { driver.find_element(:xpath, "//span[text()='Ocorrência de Trilhas de Auditoria']/following-sibling::div[1]") }
      ocorrencia_de_trilhas_value = ocorrencia_de_trilhas_span.text
    rescue Selenium::WebDriver::Error::NoSuchElementError, Selenium::WebDriver::Error::TimeoutError
      ocorrencia_de_trilhas_value = ''
    end

    begin
      # Clicar em Pareceres
      first_span = wait.until { driver.find_element(:xpath, "//a[text()='Pareceres']") }
      first_span.click

      # Clicar em detalhar
      second_span = wait.until { driver.find_element(:xpath, "//a[text()='Detalhar']") }
      second_span.click
    rescue Selenium::WebDriver::Error::NoSuchElementError, Selenium::WebDriver::Error::TimeoutError
      output_data << {
        id: data['NÚMERO CONVÊNIO'],
        link: link,
        nota_de_risco: nota_de_risco_value,
        ocorrencia_de_trilhas: ocorrencia_de_trilhas_value,
        parecer_situacao: '',
        parecer_descricao: '',
        parecer_tem_anexo: '',
      }
      File.write(index_file, current_index + 1)
      File.write(output_file, JSON.pretty_generate(output_data))
      next
    end

    # Extrair dados do parecer
    parecer_situacao = wait.until { driver.find_element(:xpath, "//label[text()='Situação do Parecer:']/following-sibling::span[1]") }
    parecer_situacao_value = parecer_situacao.text
    
    parecer_descricao = wait.until { driver.find_element(:xpath, "//label[text()='Parecer:']/following-sibling::textarea[1]") }
    parecer_descricao_value = parecer_descricao.text
    
    begin
      # Verificar se a tabela Anexos possui linhas
      parecer_anexos_value = []
      table = wait.until { driver.find_element(:id, "formDetalhaParecer:listaArquivosAnexosModoDetalharParecer") }
      rows = table.find_elements(:tag_name, 'tr')
      if !rows.empty?
        rows.each do |row|
          begin
            # Encontrar o link dentro do span
            link_element = row.find_element(:xpath, ".//td//a")
            parecer_anexos_value << link_element.attribute('href')
          rescue Selenium::WebDriver::Error::NoSuchElementError
            # Se não encontrar, continuar para a próxima linha
            next
          end
        end
      end
    rescue Selenium::WebDriver::Error::NoSuchElementError, Selenium::WebDriver::Error::TimeoutError
      parecer_anexos_value = []
    end

    # Adicionar os dados extraídos à saída
    output_data << {
      id: data['NÚMERO CONVÊNIO'],
      link: link,
      nota_de_risco: nota_de_risco_value,
      ocorrencia_de_trilhas: ocorrencia_de_trilhas_value,
      parecer_situacao: parecer_situacao_value,
      parecer_descricao: parecer_descricao_value,
      parecer_anexos: parecer_anexos_value,
    }

    # Salvar o índice atual
    File.write(index_file, current_index + 1)
    File.write(output_file, JSON.pretty_generate(output_data))
  end

ensure
  # Fechar o navegador
  driver.quit

  # Salvar o JSON de saída
  File.write(output_file, JSON.pretty_generate(output_data))
end
