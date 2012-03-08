# encoding: UTF-8
# Exemplo de uso do ActiveRecord sem o rails
# vide ligtning talks Rubyconfbr2011 @ 1h:15m 'José Valim'

##########  CONFIG  ##############################################################

require "rubygems"
require "bundler"

Bundler.setup

require 'mechanize'
require 'googlecharts'
require "active_record"
require 'yaml'

require "./firechart"
include FireChart

ActiveRecord::Base.establish_connection(
:adapter => "mysql2",
:database => "fireboard"
)

params = YAML.load_file(File.open('config/sources.yml', 'r'))

########## MODELS #################################################################

class Project < ActiveRecord::Base
  has_many :reports, :dependent => :destroy

  def make_report occurrences
    report = get_last_report
    report.bug_occurrences += occurrences
    report.save
  end

  def get_last_report
    if last_report = self.reports.last
      if last_report.created_at.to_date == Time.now.to_date
        return last_report
      else
        return self.reports.build
      end
    else
      return self.reports.build
    end
  end
end

class Report < ActiveRecord::Base
  belongs_to :project
end

########### SCRIPT ################################################################

agent = Mechanize.new

p "Starting get data from AIRBRAKE...  -------------- #{Time.now.strftime("%d/%m/%Y (%H:%M:%S)")}"

# AIRBRAKE
page = agent.get('https://ditointernet.airbrakeapp.com/login')
auth = page.form
auth.field_with(:dom_id => "session_email").value = params["airbrake"]["user"]
auth.field_with(:dom_id => "session_password").value = params["airbrake"]["password"]
page = auth.submit

project_links = page.links_with(:href => /(https:\/\/ditointernet\.airbrakeapp\.com\/projects\/[0-9]*\/errors)/)

# ex. Projeto (numero)
project_name_regex = /([\w\s\-ãõáéíóúê]*\s)/ # Qualquer palavra até o primeiro '('
project_errors_regex = /\w*\((\d+)\)/ # O número contido dentro dos ( )

# projects less used 
projects_in_select = project_links.first.node.ancestors[1].children
projects_and_errors = projects_in_select[projects_in_select.size - 4].children.last.children.text.gsub("Choose a project...","")

projects = projects_and_errors.scan(project_name_regex).flatten
errors = projects_and_errors.scan(project_errors_regex).flatten

projects.each_index do |n|
  project = Project.find_or_initialize_by_name(projects[n])
  project.make_report(errors[n].to_i)
end

# recent projects 
project_links.each do |link|
  if link.attributes.children[3]
    # p link.attributes.children[3].child.text + " - " + link.attributes.children[1].child.text + " erros"
    project = Project.find_or_initialize_by_name(link.attributes.children[3].child.text)
    project.make_report(link.attributes.children[1].child.text.to_i)
  end
end
p "AIRBRAKE done.  ---------------------------------- #{Time.now.strftime("%d/%m/%Y (%H:%M:%S)")}"


p "Starting get data from PROJETOS... --------------- #{Time.now.strftime("%d/%m/%Y (%H:%M:%S)")}"
# Projetos Dito
page = agent.get('http://projetos.dito.com.br:8008/login')

auth = page.forms.last
auth.fields[1].value = params["projetos"]["user"]
auth.fields[2].value = params["projetos"]["password"]
page = auth.submit

page = agent.get('http://projetos.dito.com.br:8008/projects')

projects_links = page.links_with(:dom_class => "project my-project")

projects_links.each do |link|
  page = link.click
  bug_dom = page.link_with(:href => /\/projects\/[a-zA-Z]*\/issues\?set_filter=1&tracker_id=1/)
  bugs_dom = bug_dom.attributes.ancestors[0].children.last.text.gsub(/['\t'|'\n'|':']/, "").split.first

  project = Project.find_or_initialize_by_name(link.text)
  project.make_report(bugs_dom.to_i)
end
p "PROJETOS done.  ---------------------------------- #{Time.now.strftime("%d/%m/%Y (%H:%M:%S)")}"

p "Generating charts... ----------------------------- #{Time.now.strftime("%d/%m/%Y (%H:%M:%S)")}"

# Cria um novo diretorio com um timestamp como nome
dir = Time.now.strftime("%Y%m%d")
system("mkdir charts/#{dir}")

Project.order("created_at ASC").each do |project|
  report_data_bugs = []
  report_data_dates = []
  project.reports.map{ |report| report_data_bugs << report.bug_occurrences}

  create_chart project.name, report_data_bugs, {:path => "charts/#{dir}/#{project.name}.svg"}
end

p "All charts Done. --------------------------------- #{Time.now.strftime("%d/%m/%Y (%H:%M:%S)")}"

